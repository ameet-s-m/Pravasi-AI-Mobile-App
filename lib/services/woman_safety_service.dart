// lib/services/woman_safety_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WomanSafetyService {
  static final WomanSafetyService _instance = WomanSafetyService._internal();
  factory WomanSafetyService() => _instance;
  WomanSafetyService._internal();

  bool _isActive = false;
  bool _isNightMode = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _safetyCheckTimer;
  Timer? _locationShareTimer;
  Timer? _safetyZoneVibrationTimer;
  Timer? _safetyZoneAlarmTimer;
  bool _safetyZoneAlarmActive = false;
  
  Position? _currentPosition;
  final List<Position> _routeHistory = [];
  final List<UserSafeZone> _userSafeZones = []; // User-defined safety zones
  bool _safetyZoneAlertShown = false; // Track if alert already shown
  
  // Safety thresholds
  static const double _unsafeZoneRadius = 200.0; // meters
  static const int _locationShareInterval = 30; // seconds
  static const int _nightModeStartHour = 20; // 8 PM
  static const int _nightModeEndHour = 6; // 6 AM
  
  Function(String message)? onSafetyAlert;
  Function()? onEmergencyTriggered;
  Function(Position position)? onLocationUpdate;
  Function()? onUnsafeZoneDetected;
  Function(Position position)? onLeftSafetyZone; // New callback for leaving safety zone

  bool get isActive => _isActive;
  bool get isNightMode => _isNightMode;
  Position? get currentPosition => _currentPosition;

  Future<void> startWomanSafetyMode() async {
    if (_isActive) return;
    
    _isActive = true;
    _routeHistory.clear();
    _checkNightMode();
    
    // Load saved safety zones
    await loadSafetyZones();
    
    // Start location tracking
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters - REAL TIME monitoring
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _routeHistory.add(position);
      if (_routeHistory.length > 100) {
        _routeHistory.removeAt(0);
      }
      
      onLocationUpdate?.call(position);
      _checkSafetyConditions(position);
      _checkUserSafetyZones(position); // REAL TIME check if user left their safety zone
    });

    // Periodic safety checks
    _safetyCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _performSafetyChecks();
    });

    // Share location periodically
    _locationShareTimer = Timer.periodic(
      const Duration(seconds: _locationShareInterval),
      (timer) => _shareLocationWithContacts(),
    );

    // Initial location share
    _shareLocationWithContacts();
  }

  void _checkNightMode() {
    final hour = DateTime.now().hour;
    _isNightMode = hour >= _nightModeStartHour || hour < _nightModeEndHour;
  }

  void _checkSafetyConditions(Position position) {
    // Check for unsafe zones (areas with high incident reports)
    _checkUnsafeZones(position);
    
    // Check if in isolated area (low population density)
    _checkIsolatedArea(position);
    
    // Night mode enhanced checks
    if (_isNightMode) {
      _performNightModeChecks(position);
    }
  }

  void _checkUnsafeZones(Position position) {
    // In real implementation, check against database of unsafe zones
    // For now, use demo unsafe zones
    final unsafeZones = _getUnsafeZones();
    
    for (var zone in unsafeZones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone['lat'] as double,
        zone['lng'] as double,
      );
      
      if (distance <= _unsafeZoneRadius) {
        onUnsafeZoneDetected?.call();
        onSafetyAlert?.call('⚠️ You are near an area with reported incidents. Stay alert!');
        
        // Vibrate to alert
        if (!kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      }
    }
  }

  void _checkIsolatedArea(Position position) {
    // Check if user is in an isolated area (far from safe zones)
    // This is a simplified check - in real app, use population density data
    if (_routeHistory.length >= 5) {
      final recentPositions = _routeHistory.sublist(_routeHistory.length - 5);
      final avgDistance = _calculateAverageDistanceFromSafeZones(recentPositions);
      
      if (avgDistance > 500) {
        // More than 500m from nearest safe zone
        onSafetyAlert?.call('📍 You are in a less populated area. Share your location with trusted contacts.');
      }
    }
  }

  void _performNightModeChecks(Position position) {
    // Enhanced safety checks during night hours
    if (_routeHistory.length >= 3) {
      final recentPositions = _routeHistory.sublist(_routeHistory.length - 3);
      final avgSpeed = _calculateAverageSpeed(recentPositions);
      
      // If moving slowly at night (walking), increase alert frequency
      if (avgSpeed < 5.0) {
        // Walking at night - share location more frequently
        _shareLocationWithContacts();
      }
    }
  }

  void _performSafetyChecks() {
    if (!_isActive || _currentPosition == null) return;
    
    // Check if user has been stationary for too long
    if (_routeHistory.length >= 10) {
      final recentPositions = _routeHistory.sublist(_routeHistory.length - 10);
      final isStationary = _isStationary(recentPositions);
      
      if (isStationary) {
        onSafetyAlert?.call('⚠️ You have been stationary for a while. Are you safe?');
      }
    }
  }

  bool _isStationary(List<Position> positions) {
    if (positions.length < 2) return false;
    
    final first = positions.first;
    final last = positions.last;
    final distance = Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      last.latitude,
      last.longitude,
    );
    
    // If moved less than 50 meters in last positions, consider stationary
    return distance < 50;
  }

  double _calculateAverageDistanceFromSafeZones(List<Position> positions) {
    // Simplified - in real app, calculate distance to nearest safe zone
    return 200.0; // Placeholder
  }

  double _calculateAverageSpeed(List<Position> positions) {
    if (positions.length < 2) return 0.0;
    
    double totalSpeed = 0.0;
    for (var pos in positions) {
      totalSpeed += pos.speed * 3.6; // Convert to km/h
    }
    return totalSpeed / positions.length;
  }

  List<Map<String, double>> _getUnsafeZones() {
    // Real unsafe zones - empty by default, populated from real incident reports
    // In production, fetch from database of reported incidents
    // For now, return empty - no fake unsafe zones
    return [];
  }

  Future<void> _shareLocationWithContacts() async {
    if (_currentPosition == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
    
    if (emergencyContacts.isEmpty) return;
    
    final message = _isNightMode
        ? '🌙 Night Mode Active\n📍 Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}\n🕐 Time: ${DateTime.now().toString()}\n\nStay safe!'
        : '📍 Live Location\nCoordinates: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}\nTime: ${DateTime.now().toString()}\n\nView on map: https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    
    // In real implementation, send to all emergency contacts
    print('Location shared: $message');
  }

  Future<void> triggerEmergency() async {
    if (_currentPosition == null) return;
    
    // Vibrate heavily
    if (!kIsWeb) {
      for (int i = 0; i < 5; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    // Send emergency alert
    final prefs = await SharedPreferences.getInstance();
    final emergencyContact = prefs.getString('emergency_contact_number');
    
    if (emergencyContact != null) {
      final message = '🚨 EMERGENCY ALERT 🚨\n\n'
          'I need immediate help!\n\n'
          'Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}\n'
          'Time: ${DateTime.now().toString()}\n\n'
          'View on map: https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      
      try {
        final smsUri = Uri.parse('sms:$emergencyContact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending emergency SMS: $e');
      }
    }
    
    onEmergencyTriggered?.call();
  }

  Future<void> shareLiveLocation() async {
    await _shareLocationWithContacts();
  }

  Future<void> callEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyContact = prefs.getString('emergency_contact_number');
    
    if (emergencyContact != null) {
      try {
        final callUri = Uri.parse('tel:$emergencyContact');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        }
      } catch (e) {
        print('Error calling emergency contact: $e');
      }
    }
  }

  void _checkUserSafetyZones(Position position) {
    if (_userSafeZones.isEmpty) return;
    
    bool inAnySafeZone = false;
    UserSafeZone? nearestZone;
    double nearestDistance = double.infinity;
    
    for (var zone in _userSafeZones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );
      
      if (distance <= zone.radius) {
        inAnySafeZone = true;
        // Reset alert flag when back in zone
        _safetyZoneAlertShown = false;
        break;
      } else {
        // Track nearest zone for boundary warning
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestZone = zone;
        }
      }
    }
    
    // If user is OUTSIDE any safety zone - trigger IMMEDIATE alarm and vibration
    if (!inAnySafeZone && nearestZone != null) {
      final distanceToBoundary = nearestDistance - nearestZone.radius;
      
      // If outside the zone (even slightly), trigger IMMEDIATE alert
      if (distanceToBoundary > 0) {
        if (!_safetyZoneAlertShown) {
          _safetyZoneAlertShown = true;
          // Trigger immediate alarm and vibration
          _triggerSafetyZoneAlarm();
          // Call the callback to show dialog
          onLeftSafetyZone?.call(position);
        }
      }
    }
  }

  void _triggerSafetyZoneAlarm() {
    if (kIsWeb || _safetyZoneAlarmActive) return;
    
    _safetyZoneAlarmActive = true;
    
    // IMMEDIATE strong vibration - continuous pattern
    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();
    
    // Start continuous vibration pattern - REAL vibration
    _safetyZoneVibrationTimer?.cancel();
    _safetyZoneVibrationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isActive || kIsWeb) {
        timer.cancel();
        _safetyZoneAlarmActive = false;
        return;
      }
      HapticFeedback.heavyImpact();
    });
    
    // Play alarm sound immediately - REAL alarm
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.alert);
    
    // Continuous alarm sound pattern - REAL alarm at full volume
    _safetyZoneAlarmTimer?.cancel();
    _safetyZoneAlarmTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isActive || kIsWeb) {
        timer.cancel();
        _safetyZoneAlarmActive = false;
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
        _safetyZoneAlarmActive = false;
      }
    });
  }

  void stopSafetyZoneAlarm() {
    _safetyZoneVibrationTimer?.cancel();
    _safetyZoneAlarmTimer?.cancel();
    _safetyZoneAlarmActive = false;
    _safetyZoneAlertShown = false;
  }

  Future<void> addSafetyZone(UserSafeZone zone) async {
    _userSafeZones.add(zone);
    // Save safety zones to SharedPreferences for persistence
    await _saveSafetyZones();
  }

  Future<void> _saveSafetyZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save zones as JSON string
      final zonesList = _userSafeZones.map((zone) => 
        '${zone.name}|${zone.latitude}|${zone.longitude}|${zone.radius}'
      ).toList();
      await prefs.setStringList('woman_safety_zones', zonesList);
      print('✅ Safety zones saved: ${_userSafeZones.length} zones');
    } catch (e) {
      print('Error saving safety zones: $e');
    }
  }

  Future<void> loadSafetyZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesList = prefs.getStringList('woman_safety_zones') ?? [];
      _userSafeZones.clear();
      
      for (var zoneStr in zonesList) {
        final parts = zoneStr.split('|');
        if (parts.length == 4) {
          _userSafeZones.add(UserSafeZone(
            name: parts[0],
            latitude: double.parse(parts[1]),
            longitude: double.parse(parts[2]),
            radius: double.parse(parts[3]),
          ));
        }
      }
      print('✅ Safety zones loaded: ${_userSafeZones.length} zones');
    } catch (e) {
      print('Error loading safety zones: $e');
    }
  }

  Future<void> removeSafetyZone(UserSafeZone zone) async {
    _userSafeZones.removeWhere((z) => 
      z.name == zone.name && 
      z.latitude == zone.latitude && 
      z.longitude == zone.longitude
    );
    await _saveSafetyZones();
  }

  List<UserSafeZone> get safetyZones => _userSafeZones;

  Future<void> sendSOSAlert(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
    final familyContactNumber = prefs.getString('family_contact_number'); // Get family contact from settings
    
    final mapUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    final message = '🚨 SOS ALERT - SAFETY ZONE 🚨\n\n'
        'I have left my safety zone and did not confirm safety!\n\n'
        'Current Location: ${position.latitude}, ${position.longitude}\n'
        'Google Maps: $mapUrl\n'
        'Time: ${DateTime.now()}\n\n'
        'Please check on me immediately!';
    
    // Send to all emergency contacts via SMS
    for (var contact in emergencyContacts) {
      try {
        final smsUri = Uri.parse('sms:$contact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending SOS SMS to $contact: $e');
      }
    }
    
    // Send to family contact via SMS and WhatsApp (if specified)
    if (familyContactNumber != null && familyContactNumber.isNotEmpty) {
      try {
        // Send SMS
        final smsUri = Uri.parse('sms:$familyContactNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
        
        // Send WhatsApp message
        final whatsappMessage = '🚨 SOS ALERT - SAFETY ZONE 🚨\n\n'
            'I have left my safety zone and need help!\n\n'
            'Location: $mapUrl\n'
            'Time: ${DateTime.now()}';
        final whatsappUri = Uri.parse('https://wa.me/$familyContactNumber?text=${Uri.encodeComponent(whatsappMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
      } catch (e) {
        print('Error sending to family contact: $e');
      }
    }
    
    // Also trigger emergency
    await triggerEmergency();
  }

  void stopWomanSafetyMode() {
    _isActive = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _safetyCheckTimer?.cancel();
    _safetyCheckTimer = null;
    _locationShareTimer?.cancel();
    _locationShareTimer = null;
    stopSafetyZoneAlarm();
    _routeHistory.clear();
  }

  String getSafetyStatus() {
    if (!_isActive) return 'Inactive';
    if (_isNightMode) return 'Night Mode Active';
    return 'Active';
  }

  List<Position> getRouteHistory() => List.unmodifiable(_routeHistory);
}

class UserSafeZone {
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters

  UserSafeZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
}

