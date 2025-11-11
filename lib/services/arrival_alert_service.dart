// lib/services/arrival_alert_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ArrivalAlertService {
  static final ArrivalAlertService _instance = ArrivalAlertService._internal();
  factory ArrivalAlertService() => _instance;
  ArrivalAlertService._internal();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  Position? _destination;
  double _alertDistance = 5.0; // km
  int _alertTime = 10; // minutes
  Function(String)? _onAlertCallback;

  // Get current alert settings
  Future<Map<String, dynamic>> getAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isActive': prefs.getBool('arrival_alert_active') ?? false,
      'destinationLat': prefs.getDouble('arrival_alert_lat'),
      'destinationLng': prefs.getDouble('arrival_alert_lng'),
      'destinationName': prefs.getString('arrival_alert_name') ?? 'Destination',
      'alertDistance': prefs.getDouble('arrival_alert_distance') ?? 5.0,
      'alertTime': prefs.getInt('arrival_alert_time') ?? 10,
    };
  }

  // Set alert destination and settings
  Future<void> setAlert({
    required double latitude,
    required double longitude,
    required String name,
    required double alertDistanceKm,
    required int alertTimeMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arrival_alert_active', true);
    await prefs.setDouble('arrival_alert_lat', latitude);
    await prefs.setDouble('arrival_alert_lng', longitude);
    await prefs.setString('arrival_alert_name', name);
    await prefs.setDouble('arrival_alert_distance', alertDistanceKm);
    await prefs.setInt('arrival_alert_time', alertTimeMinutes);

    _destination = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _alertDistance = alertDistanceKm;
    _alertTime = alertTimeMinutes;

    await startMonitoring();
  }

  // Start monitoring location
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer?.cancel();

    // Check every 30 seconds
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (_destination == null) {
          final settings = await getAlertSettings();
          if (settings['isActive'] == true && 
              settings['destinationLat'] != null && 
              settings['destinationLng'] != null) {
            _destination = Position(
              latitude: settings['destinationLat'] as double,
              longitude: settings['destinationLng'] as double,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
            _alertDistance = settings['alertDistance'] as double? ?? 5.0;
            _alertTime = settings['alertTime'] as int? ?? 10;
          } else {
            stopMonitoring();
            return;
          }
        }

        // Calculate distance
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          _destination!.latitude,
          _destination!.longitude,
        ) / 1000; // Convert to km

        // Calculate estimated time based on current speed
        double estimatedMinutes = 0;
        if (currentPosition.speed > 0) {
          estimatedMinutes = (distance / (currentPosition.speed * 3.6)) * 60; // speed in m/s to km/h
        } else {
          // Default speed estimate (50 km/h)
          estimatedMinutes = (distance / 50) * 60;
        }

        // Check if alert conditions are met
        if (distance <= _alertDistance || estimatedMinutes <= _alertTime) {
          await _triggerAlert(distance, estimatedMinutes);
        }
      } catch (e) {
        print('Error monitoring arrival: $e');
      }
    });
  }

  // Trigger alert (vibration and callback)
  Future<void> _triggerAlert(double distanceKm, double estimatedMinutes) async {
    // Vibrate device
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();

    // Call callback if set
    if (_onAlertCallback != null) {
      final settings = await getAlertSettings();
      final destinationName = settings['destinationName'] as String? ?? 'Destination';
      _onAlertCallback!(
        'You are ${distanceKm.toStringAsFixed(1)} km away from $destinationName. '
        'Estimated arrival: ${estimatedMinutes.toStringAsFixed(0)} minutes.'
      );
    }

    // Stop monitoring after alert
    await stopMonitoring();
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _destination = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arrival_alert_active', false);
  }

  // Set callback for alerts
  void setOnAlertCallback(Function(String message)? callback) {
    _onAlertCallback = callback;
  }

  // Check if monitoring is active
  bool get isMonitoring => _isMonitoring;
}

