// lib/services/child_safety_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';

class ChildSafetyService {
  static final ChildSafetyService _instance = ChildSafetyService._internal();
  factory ChildSafetyService() => _instance;
  ChildSafetyService._internal();

  final List<ChildProfile> _children = [];
  final Map<String, StreamSubscription<Position>> _trackingSubscriptions = {};
  final Map<String, Timer> _checkTimers = {};
  final Map<String, bool> _safetyZoneAlertShown = {};
  final Map<String, List<LocationHistoryEntry>> _locationHistory = {};

  Function(String childId, Position position)? onChildLocationUpdate;
  Function(String childId)? onChildMissing;
  Function(String childId, Position position)? onChildOutOfZone;
  Function(String childId, Position position)? onSafetyZoneAlert;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadChildren();
    _initialized = true;
  }

  Future<void> addChild(ChildProfile child) async {
    _children.add(child);
    await _saveChildren();
  }

  Future<void> updateChild(ChildProfile updatedChild) async {
    final index = _children.indexWhere((c) => c.id == updatedChild.id);
    if (index != -1) {
      _children[index] = updatedChild;
      await _saveChildren();
    }
  }

  Future<void> removeChild(String childId) async {
    stopTrackingChild(childId);
    _children.removeWhere((c) => c.id == childId);
    _locationHistory.remove(childId);
    await _saveChildren();
  }

  // Manual location check-in (for when parent updates child's location)
  Future<void> checkInChildLocation(String childId, Position position) async {
    final child = _children.firstWhere((c) => c.id == childId);
    child.lastKnownPosition = position;
    child.lastUpdateTime = DateTime.now();
    
    // Add to location history
    if (!_locationHistory.containsKey(childId)) {
      _locationHistory[childId] = [];
    }
    _locationHistory[childId]!.add(LocationHistoryEntry(
      position: position,
      timestamp: DateTime.now(),
    ));
    
    // Keep only last 100 entries
    if (_locationHistory[childId]!.length > 100) {
      _locationHistory[childId]!.removeAt(0);
    }
    
    // Check safety
    _checkChildSafety(child, position);
    
    // Notify listeners
    onChildLocationUpdate?.call(childId, position);
    
    await _saveChildren();
    await _saveLocationHistory();
  }

  // Start tracking child (if child has their own device, this would track their device)
  // For now, this simulates tracking by periodically checking if child should be at school/home
  Future<void> startTrackingChild(String childId) async {
    if (_trackingSubscriptions.containsKey(childId)) {
      return; // Already tracking
    }

    final child = _children.firstWhere((c) => c.id == childId);
    
    // If child has last known position, start monitoring from there
    if (child.lastKnownPosition != null) {
      // Periodic safety checks
      _checkTimers[childId] = Timer.periodic(const Duration(minutes: 5), (timer) {
        _performSafetyCheck(child);
      });
    } else {
      // If no location, prompt parent to check in location
      print('No location set for ${child.name}. Please check in location first.');
    }
  }

  void stopTrackingChild(String childId) {
    _trackingSubscriptions[childId]?.cancel();
    _trackingSubscriptions.remove(childId);
    _checkTimers[childId]?.cancel();
    _checkTimers.remove(childId);
  }

  void _checkChildSafety(ChildProfile child, Position position) {
    // Check if child is in safe zone
    if (child.safeZones.isNotEmpty) {
      bool inSafeZone = false;
      SafeZone? nearestZone;
      double nearestDistance = double.infinity;
      
      for (var zone in child.safeZones) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          zone.latitude,
          zone.longitude,
        );
        
        if (distance <= zone.radius) {
          inSafeZone = true;
          // Reset alert flag when back in zone
          _safetyZoneAlertShown[child.id] = false;
          break;
        } else {
          // Track nearest zone for boundary warning
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestZone = zone;
          }
        }
      }
      
      // Check if approaching boundary or outside
      if (!inSafeZone && nearestZone != null) {
        final distanceToBoundary = nearestDistance - nearestZone.radius;
        final warningThreshold = nearestZone.radius * 0.2; // 20% of radius before boundary
        
        if (distanceToBoundary <= warningThreshold && distanceToBoundary > 0) {
          // Approaching boundary - warn BEFORE leaving
          final alertShown = _safetyZoneAlertShown[child.id] ?? false;
          if (!alertShown) {
            _safetyZoneAlertShown[child.id] = true;
            onSafetyZoneAlert?.call(child.id, position);
          }
        } else if (distanceToBoundary > warningThreshold) {
          // Already outside - trigger alert
          final alertShown = _safetyZoneAlertShown[child.id] ?? false;
          if (!alertShown) {
            _safetyZoneAlertShown[child.id] = true;
            onSafetyZoneAlert?.call(child.id, position);
          }
          onChildOutOfZone?.call(child.id, position);
        }
      }
    }

    // Check if child hasn't moved (possible issue)
    if (child.lastKnownPosition != null) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        child.lastKnownPosition!.latitude,
        child.lastKnownPosition!.longitude,
      );
      
      if (distance < 10) {
        // Child hasn't moved much - might be in trouble
        final timeSinceLastMove = DateTime.now().difference(child.lastUpdateTime);
        if (timeSinceLastMove.inMinutes > 30) {
          onChildMissing?.call(child.id);
        }
      }
    }

    child.lastKnownPosition = position;
    child.lastUpdateTime = DateTime.now();
  }

  void _performSafetyCheck(ChildProfile child) {
    if (child.lastKnownPosition == null) return;
    
    // Check if child should be at school/home
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
    
    // School hours check (8 AM - 3 PM, Monday to Friday)
    if (currentDay >= 1 && currentDay <= 5 && currentHour >= 8 && currentHour < 15) {
      if (child.schoolLocation != null) {
        final distance = Geolocator.distanceBetween(
          child.lastKnownPosition!.latitude,
          child.lastKnownPosition!.longitude,
          child.schoolLocation!.latitude,
          child.schoolLocation!.longitude,
        );
        
        if (distance > 500) {
          // Child not at school during school hours
          onChildMissing?.call(child.id);
        }
      }
    }
    
    // Home check (after 6 PM on weekdays, or anytime on weekends)
    if ((currentDay >= 6 || (currentDay <= 5 && currentHour >= 18)) && child.homeLocation != null) {
      final distance = Geolocator.distanceBetween(
        child.lastKnownPosition!.latitude,
        child.lastKnownPosition!.longitude,
        child.homeLocation!.latitude,
        child.homeLocation!.longitude,
      );
      
      if (distance > 200) {
        // Child not at home when expected
        onChildMissing?.call(child.id);
      }
    }
  }

  Future<void> setSchoolLocation(String childId, Position position) async {
    final child = _children.firstWhere((c) => c.id == childId);
    final updatedChild = ChildProfile(
      id: child.id,
      name: child.name,
      age: child.age,
      photoUrl: child.photoUrl,
      safeZones: child.safeZones,
      schoolLocation: position,
      homeLocation: child.homeLocation,
      lastKnownPosition: child.lastKnownPosition,
      lastUpdateTime: child.lastUpdateTime,
      isMissing: child.isMissing,
      missingSince: child.missingSince,
    );
    await updateChild(updatedChild);
  }

  Future<void> setHomeLocation(String childId, Position position) async {
    final child = _children.firstWhere((c) => c.id == childId);
    final updatedChild = ChildProfile(
      id: child.id,
      name: child.name,
      age: child.age,
      photoUrl: child.photoUrl,
      safeZones: child.safeZones,
      schoolLocation: child.schoolLocation,
      homeLocation: position,
      lastKnownPosition: child.lastKnownPosition,
      lastUpdateTime: child.lastUpdateTime,
      isMissing: child.isMissing,
      missingSince: child.missingSince,
    );
    await updateChild(updatedChild);
  }

  Future<void> addEmergencyContact(String childId, String contactName, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'child_emergency_contacts_$childId';
    final contacts = prefs.getStringList(key) ?? [];
    
    // Format: "Name|PhoneNumber"
    contacts.add('$contactName|$phoneNumber');
    await prefs.setStringList(key, contacts);
  }

  Future<void> removeEmergencyContact(String childId, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'child_emergency_contacts_$childId';
    final contacts = prefs.getStringList(key) ?? [];
    contacts.removeWhere((c) => c.split('|').last == phoneNumber);
    await prefs.setStringList(key, contacts);
  }

  Future<List<Map<String, String>>> getEmergencyContacts(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'child_emergency_contacts_$childId';
    final contacts = prefs.getStringList(key) ?? [];
    
    return contacts.map((c) {
      final parts = c.split('|');
      return {'name': parts[0], 'phone': parts.length > 1 ? parts[1] : ''};
    }).toList();
  }

  Future<void> reportChildMissing(String childId) async {
    final child = _children.firstWhere((c) => c.id == childId);
    child.isMissing = true;
    child.missingSince = DateTime.now();
    
    await _saveChildren();
    await _sendMissingChildAlert(child);
  }

  Future<void> markChildFound(String childId) async {
    final child = _children.firstWhere((c) => c.id == childId);
    child.isMissing = false;
    child.missingSince = null;
    await _saveChildren();
  }

  Future<void> _sendMissingChildAlert(ChildProfile child) async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyContacts = await getEmergencyContacts(child.id);
    final familyContacts = prefs.getStringList('emergency_contacts') ?? [];
    final familyContactNumber = prefs.getString('family_contact_number');
    
    final mapUrl = child.lastKnownPosition != null
        ? 'https://www.google.com/maps?q=${child.lastKnownPosition!.latitude},${child.lastKnownPosition!.longitude}'
        : 'Location not available';
    
    final message = '🚨 MISSING CHILD ALERT 🚨\n\n'
        'Child: ${child.name}\n'
        'Age: ${child.age}\n'
        'Last Known Location: ${child.lastKnownPosition != null ? "${child.lastKnownPosition!.latitude}, ${child.lastKnownPosition!.longitude}" : "Not available"}\n'
        'Map: $mapUrl\n'
        'Missing Since: ${child.missingSince?.toString() ?? "Unknown"}\n\n'
        'Please help locate this child immediately!';
    
    // Send to child's emergency contacts
    for (var contact in emergencyContacts) {
      try {
        final phone = contact['phone'] ?? '';
        if (phone.isNotEmpty) {
          final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          }
        }
      } catch (e) {
        print('Error sending alert to ${contact['name']}: $e');
      }
    }
    
    // Send to family contacts
    for (var contact in familyContacts) {
      try {
        final smsUri = Uri.parse('sms:$contact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending alert to $contact: $e');
      }
    }
    
    // Send to primary family contact
    if (familyContactNumber != null && familyContactNumber.isNotEmpty) {
      try {
        final smsUri = Uri.parse('sms:$familyContactNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
        
        // Also send WhatsApp
        final whatsappMessage = '🚨 MISSING CHILD ALERT 🚨\n\n'
            '${child.name} (Age ${child.age}) is missing!\n\n'
            'Last Location: $mapUrl\n'
            'Missing Since: ${child.missingSince?.toString() ?? "Unknown"}';
        final cleanNumber = familyContactNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(whatsappMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
      } catch (e) {
        print('Error sending to family contact: $e');
      }
    }
    
    print('Missing child alert sent for: ${child.name}');
  }

  Future<void> sendSOSAlert(String childId, Position position) async {
    final child = _children.firstWhere((c) => c.id == childId);
    final prefs = await SharedPreferences.getInstance();
    final emergencyContacts = await getEmergencyContacts(child.id);
    final familyContacts = prefs.getStringList('emergency_contacts') ?? [];
    final familyContactNumber = prefs.getString('family_contact_number');
    
    final mapUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    final message = '🚨 SOS ALERT - CHILD SAFETY 🚨\n\n'
        '${child.name} has left their safety zone and did not confirm safety!\n\n'
        'Current Location: ${position.latitude}, ${position.longitude}\n'
        'Google Maps: $mapUrl\n'
        'Time: ${DateTime.now()}\n\n'
        'Please check on ${child.name} immediately!';
    
    // Send to child's emergency contacts
    for (var contact in emergencyContacts) {
      try {
        final phone = contact['phone'] ?? '';
        if (phone.isNotEmpty) {
          final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          }
        }
      } catch (e) {
        print('Error sending SOS to ${contact['name']}: $e');
      }
    }
    
    // Send to family contacts
    for (var contact in familyContacts) {
      try {
        final smsUri = Uri.parse('sms:$contact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending SOS to $contact: $e');
      }
    }
    
    // Send to primary family contact
    if (familyContactNumber != null && familyContactNumber.isNotEmpty) {
      try {
        final smsUri = Uri.parse('sms:$familyContactNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
        
        // Send WhatsApp
        final whatsappMessage = '🚨 SOS ALERT - CHILD SAFETY 🚨\n\n'
            '${child.name} has left their safety zone!\n\n'
            'Location: $mapUrl\n'
            'Time: ${DateTime.now()}';
        final cleanNumber = familyContactNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(whatsappMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
      } catch (e) {
        print('Error sending to family contact: $e');
      }
    }
    
    print('SOS alert sent for child: ${child.name}');
  }

  List<LocationHistoryEntry> getLocationHistory(String childId) {
    return _locationHistory[childId] ?? [];
  }

  Future<void> _saveChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = _children.map((child) {
        return {
          'id': child.id,
          'name': child.name,
          'age': child.age,
          'photoUrl': child.photoUrl,
          'safeZones': child.safeZones.map((zone) => {
            'name': zone.name,
            'latitude': zone.latitude,
            'longitude': zone.longitude,
            'radius': zone.radius,
          }).toList(),
          'schoolLocation': child.schoolLocation != null ? {
            'latitude': child.schoolLocation!.latitude,
            'longitude': child.schoolLocation!.longitude,
          } : null,
          'homeLocation': child.homeLocation != null ? {
            'latitude': child.homeLocation!.latitude,
            'longitude': child.homeLocation!.longitude,
          } : null,
          'lastKnownPosition': child.lastKnownPosition != null ? {
            'latitude': child.lastKnownPosition!.latitude,
            'longitude': child.lastKnownPosition!.longitude,
          } : null,
          'lastUpdateTime': child.lastUpdateTime.toIso8601String(),
          'isMissing': child.isMissing,
          'missingSince': child.missingSince?.toIso8601String(),
        };
      }).toList();
      
      await prefs.setString('child_profiles', jsonEncode(childrenJson));
      print('✅ Saved ${_children.length} children');
    } catch (e) {
      print('Error saving children: $e');
    }
  }

  Future<void> _loadChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childrenJsonStr = prefs.getString('child_profiles');
      if (childrenJsonStr == null || childrenJsonStr.isEmpty) {
        return;
      }
      
      final childrenJson = jsonDecode(childrenJsonStr) as List;
      _children.clear();
      
      for (var childData in childrenJson) {
        final safeZones = (childData['safeZones'] as List? ?? []).map((zone) {
          return SafeZone(
            name: zone['name'],
            latitude: zone['latitude'].toDouble(),
            longitude: zone['longitude'].toDouble(),
            radius: zone['radius'].toDouble(),
          );
        }).toList();
        
        Position? schoolLocation;
        if (childData['schoolLocation'] != null) {
          schoolLocation = Position(
            latitude: childData['schoolLocation']['latitude'],
            longitude: childData['schoolLocation']['longitude'],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
        
        Position? homeLocation;
        if (childData['homeLocation'] != null) {
          homeLocation = Position(
            latitude: childData['homeLocation']['latitude'],
            longitude: childData['homeLocation']['longitude'],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
        
        Position? lastKnownPosition;
        if (childData['lastKnownPosition'] != null) {
          lastKnownPosition = Position(
            latitude: childData['lastKnownPosition']['latitude'],
            longitude: childData['lastKnownPosition']['longitude'],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
        
        final child = ChildProfile(
          id: childData['id'],
          name: childData['name'],
          age: childData['age'],
          photoUrl: childData['photoUrl'],
          safeZones: safeZones,
          schoolLocation: schoolLocation,
          homeLocation: homeLocation,
          lastKnownPosition: lastKnownPosition,
          lastUpdateTime: childData['lastUpdateTime'] != null
              ? DateTime.parse(childData['lastUpdateTime'])
              : DateTime.now(),
          isMissing: childData['isMissing'] ?? false,
          missingSince: childData['missingSince'] != null
              ? DateTime.parse(childData['missingSince'])
              : null,
        );
        
        _children.add(child);
      }
      
      print('✅ Loaded ${_children.length} children');
    } catch (e) {
      print('Error loading children: $e');
    }
  }

  Future<void> _saveLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyMap = <String, List<Map<String, dynamic>>>{};
      
      _locationHistory.forEach((childId, entries) {
        historyMap[childId] = entries.map((entry) => {
          'latitude': entry.position.latitude,
          'longitude': entry.position.longitude,
          'timestamp': entry.timestamp.toIso8601String(),
        }).toList();
      });
      
      await prefs.setString('child_location_history', jsonEncode(historyMap));
    } catch (e) {
      print('Error saving location history: $e');
    }
  }

  void stopTracking() {
    for (var subscription in _trackingSubscriptions.values) {
      subscription.cancel();
    }
    _trackingSubscriptions.clear();
    
    for (var timer in _checkTimers.values) {
      timer.cancel();
    }
    _checkTimers.clear();
  }

  List<ChildProfile> get children => List.unmodifiable(_children);
}

class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String? photoUrl;
  final List<SafeZone> safeZones;
  final Position? schoolLocation;
  final Position? homeLocation;
  Position? lastKnownPosition;
  DateTime lastUpdateTime;
  bool isMissing;
  DateTime? missingSince;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.photoUrl,
    this.safeZones = const [],
    this.schoolLocation,
    this.homeLocation,
    this.lastKnownPosition,
    DateTime? lastUpdateTime,
    this.isMissing = false,
    this.missingSince,
  }) : lastUpdateTime = lastUpdateTime ?? DateTime.now();
}

class SafeZone {
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String name;

  SafeZone({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.name,
  });
}

class LocationHistoryEntry {
  final Position position;
  final DateTime timestamp;

  LocationHistoryEntry({
    required this.position,
    required this.timestamp,
  });
}
