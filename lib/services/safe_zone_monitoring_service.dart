// lib/services/safe_zone_monitoring_service.dart
// Real-time safe zone monitoring with alerts and SOS
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'real_location_sharing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class SafeZoneMonitoringService {
  static final SafeZoneMonitoringService _instance = SafeZoneMonitoringService._internal();
  factory SafeZoneMonitoringService() => _instance;
  SafeZoneMonitoringService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  Position? _currentPosition;
  bool _wasInSafeZone = true; // Track previous state
  UserSafeZone? _lastSafeZone; // Track which zone we were in

  final List<UserSafeZone> _safeZones = [];
  bool _alertShown = false;
  Timer? _vibrationTimer;
  Timer? _alarmTimer;
  bool _alarmActive = false;

  // Settings
  bool _autoSOSEnabled = false;
  int _alertDelaySeconds = 30; // Delay before triggering SOS after leaving zone

  // Callbacks
  Function(UserSafeZone zone, Position position)? onLeftSafeZone;
  Function(UserSafeZone zone, Position position)? onEnteredSafeZone;
  Function(String message)? onAlert;

  bool get isMonitoring => _isMonitoring;
  List<UserSafeZone> get safeZones => List.unmodifiable(_safeZones);
  bool get autoSOSEnabled => _autoSOSEnabled;
  int get alertDelaySeconds => _alertDelaySeconds;

  /// Start monitoring safe zones
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _wasInSafeZone = true;
    _alertShown = false;
    await loadSafeZones();
    await loadSettings();

    // Get initial position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _checkSafeZoneStatus(_currentPosition!);
    } catch (e) {
      print('Error getting initial position: $e');
    }

    // Start continuous monitoring
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _checkSafeZoneStatus(position);
    });

    // Periodic check every 5 seconds
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPosition != null) {
        _checkSafeZoneStatus(_currentPosition!);
      }
    });

    print('✅ Safe zone monitoring started');
  }

  void _checkSafeZoneStatus(Position position) {
    if (_safeZones.isEmpty) {
      _wasInSafeZone = false;
      return;
    }

    bool currentlyInSafeZone = false;
    UserSafeZone? currentZone;

    // Check if user is in any safe zone
    for (var zone in _safeZones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= zone.radius) {
        currentlyInSafeZone = true;
        currentZone = zone;
        break;
      }
    }

    // User entered a safe zone
    if (currentlyInSafeZone && !_wasInSafeZone) {
      _wasInSafeZone = true;
      _alertShown = false;
      _stopAlarm();
      onEnteredSafeZone?.call(currentZone!, position);
      onAlert?.call('✅ Entered safe zone: ${currentZone!.name}');
      print('✅ Entered safe zone: ${currentZone!.name}');
    }
    // User left safe zone
    else if (!currentlyInSafeZone && _wasInSafeZone) {
      _wasInSafeZone = false;
      _lastSafeZone = currentZone;
      _handleLeftSafeZone(position);
    }
  }

  void _handleLeftSafeZone(Position position) {
    if (_alertShown) return; // Already alerted

    _alertShown = true;
    _triggerAlarm();
    onLeftSafeZone?.call(_lastSafeZone ?? _safeZones.first, position);
    
    final zoneName = _lastSafeZone?.name ?? 'Safe Zone';
    onAlert?.call('⚠️ Left safe zone: $zoneName');

    // If auto SOS is enabled, trigger after delay
    if (_autoSOSEnabled) {
      Future.delayed(Duration(seconds: _alertDelaySeconds), () {
        if (!_wasInSafeZone && _isMonitoring) {
          // User still outside safe zone after delay - trigger SOS
          _triggerSOS(position, zoneName);
        }
      });
    }
  }

  void _triggerAlarm() {
    if (kIsWeb || _alarmActive) return;

    _alarmActive = true;

    // Immediate vibration
    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();

    // Continuous vibration
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isMonitoring || kIsWeb) {
        timer.cancel();
        _alarmActive = false;
        return;
      }
      HapticFeedback.heavyImpact();
    });

    // Alarm sound
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.alert);

    _alarmTimer?.cancel();
    _alarmTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isMonitoring || kIsWeb) {
        timer.cancel();
        _alarmActive = false;
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
        _alarmActive = false;
      }
    });
  }

  void _stopAlarm() {
    _vibrationTimer?.cancel();
    _alarmTimer?.cancel();
    _alarmActive = false;
  }

  Future<void> _triggerSOS(Position position, String zoneName) async {
    print('🚨 SOS triggered - Left safe zone: $zoneName');

    // Get address
    String address = 'Unknown location';
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }

    final mapUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    final message = '🚨 SOS ALERT - LEFT SAFE ZONE 🚨\n\n'
        'I have left my safe zone "$zoneName" and need help!\n\n'
        '📍 Location: $address\n'
        'Coordinates: ${position.latitude}, ${position.longitude}\n'
        '📍 View on Map: $mapUrl\n\n'
        'Time: ${DateTime.now()}\n\n'
        'Please check on me immediately!';

    // Get family contact
    final prefs = await SharedPreferences.getInstance();
    final familyContact = prefs.getString('family_contact_number') ?? '';
    final emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
    final allContacts = [familyContact, ...emergencyContacts].where((c) => c.isNotEmpty).toList();

    if (allContacts.isEmpty) {
      print('No emergency contacts set');
      return;
    }

    // Share location via SMS and WhatsApp
    final locationService = RealLocationSharingService();
    await locationService.shareLocationOnce(
      phoneNumbers: allContacts,
      customMessage: message,
    );

    // Make phone call to family
    if (familyContact.isNotEmpty) {
      final cleanNumber = familyContact.replaceAll(RegExp(r'[^0-9]'), '');
      final callUri = Uri.parse('tel:$cleanNumber');
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        print('✅ Phone call initiated to family');
      }
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _positionSubscription?.cancel();
    _monitoringTimer?.cancel();
    _stopAlarm();
    _alertShown = false;
    print('🛑 Safe zone monitoring stopped');
  }

  /// Add a safe zone
  Future<void> addSafeZone(UserSafeZone zone) async {
    _safeZones.add(zone);
    await _saveSafeZones();
    print('✅ Safe zone added: ${zone.name}');
  }

  /// Remove a safe zone
  Future<void> removeSafeZone(UserSafeZone zone) async {
    _safeZones.removeWhere((z) =>
        z.name == zone.name &&
        z.latitude == zone.latitude &&
        z.longitude == zone.longitude);
    await _saveSafeZones();
    print('✅ Safe zone removed: ${zone.name}');
  }

  /// Save safe zones to storage
  Future<void> _saveSafeZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesList = _safeZones.map((zone) =>
          '${zone.name}|${zone.latitude}|${zone.longitude}|${zone.radius}|${zone.type}').toList();
      await prefs.setStringList('user_safe_zones', zonesList);
    } catch (e) {
      print('Error saving safe zones: $e');
    }
  }

  /// Load safe zones from storage
  Future<void> loadSafeZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesList = prefs.getStringList('user_safe_zones') ?? [];
      _safeZones.clear();

      for (var zoneStr in zonesList) {
        final parts = zoneStr.split('|');
        if (parts.length >= 4) {
          _safeZones.add(UserSafeZone(
            name: parts[0],
            latitude: double.parse(parts[1]),
            longitude: double.parse(parts[2]),
            radius: double.parse(parts[3]),
            type: parts.length > 4 ? parts[4] : 'place', // Support old format
          ));
        }
      }
      print('✅ Loaded ${_safeZones.length} safe zones');
    } catch (e) {
      print('Error loading safe zones: $e');
    }
  }

  /// Load settings
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSOSEnabled = prefs.getBool('safe_zone_auto_sos') ?? false;
      _alertDelaySeconds = prefs.getInt('safe_zone_alert_delay') ?? 30;
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  /// Update settings
  Future<void> updateSettings({bool? autoSOS, int? alertDelay}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (autoSOS != null) {
        _autoSOSEnabled = autoSOS;
        await prefs.setBool('safe_zone_auto_sos', autoSOS);
      }
      if (alertDelay != null) {
        _alertDelaySeconds = alertDelay;
        await prefs.setInt('safe_zone_alert_delay', alertDelay);
      }
    } catch (e) {
      print('Error updating settings: $e');
    }
  }

  /// Manually stop alarm (user acknowledged)
  void acknowledgeAlert() {
    _stopAlarm();
    _alertShown = false;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

class UserSafeZone {
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String type; // 'place' or 'road'

  UserSafeZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.type = 'place', // Default to place
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'type': type,
  };
  
  factory UserSafeZone.fromJson(Map<String, dynamic> json) => UserSafeZone(
    name: json['name'] as String,
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    radius: json['radius'] as double,
    type: json['type'] as String? ?? 'place',
  );
}

