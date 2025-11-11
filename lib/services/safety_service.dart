// lib/services/safety_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_sms/flutter_sms.dart'; // Using url_launcher instead
import 'package:url_launcher/url_launcher.dart';
import 'ai_voice_call_service.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  Timer? _safetyCheckTimer;
  bool _isSafetyCheckActive = false;
  Position? _currentPosition;
  List<Position> _routePositions = [];
  Position? _lastRoutePosition;
  StreamSubscription<Position>? _positionSubscription;
  Function(String)? onRouteDeviation;
  Function()? onSafetyCheckRequired;
  Function()? onEmergencyTriggered;

  // Start monitoring route
  Future<void> startRouteMonitoring({
    required List<Position> plannedRoute,
    required Function(String) onDeviation,
    required Function() onSafetyCheck,
  }) async {
    _routePositions = plannedRoute;
    _lastRoutePosition = plannedRoute.isNotEmpty ? plannedRoute[0] : null;
    onRouteDeviation = onDeviation;
    onSafetyCheckRequired = onSafetyCheck;

    // Start location tracking
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _checkRouteDeviation(position);
    });
  }

  void _checkRouteDeviation(Position currentPosition) {
    if (_routePositions.isEmpty || _lastRoutePosition == null) return;

    // Calculate distance from planned route
    double minDistance = double.infinity;
    for (var routePos in _routePositions) {
      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        routePos.latitude,
        routePos.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If deviated more than 200 meters from planned route
    if (minDistance > 200) {
      onRouteDeviation?.call('Route deviation detected: ${minDistance.toStringAsFixed(0)}m from planned route');
      _triggerSafetyCheck();
    }
  }

  void _triggerSafetyCheck() {
    if (_isSafetyCheckActive) return;
    
    _isSafetyCheckActive = true;
    onSafetyCheckRequired?.call();

    // Start 30-second timer
    _safetyCheckTimer = Timer(const Duration(seconds: 30), () {
      if (_isSafetyCheckActive) {
        // No response received, trigger emergency
        sendEmergencyAlert();
      }
    });
  }

  void confirmSafety() {
    _isSafetyCheckActive = false;
    _safetyCheckTimer?.cancel();
    _safetyCheckTimer = null;
  }

  Future<void> sendEmergencyAlert({
    Function(bool)? onPermissionRequested,
    Position? overridePosition,
  }) async {
    _isSafetyCheckActive = false;
    onEmergencyTriggered?.call();

    // Get emergency contact and family contact
    final prefs = await SharedPreferences.getInstance();
    final emergencyContact = prefs.getString('emergency_contact_number');
    final familyContactNumber = prefs.getString('family_contact_number');
    // AI assistant call is always enabled by default
    final sosAutoCallEnabled = prefs.getBool('sos_auto_call_enabled') ?? true;

    // Use override position if provided, otherwise get current position
    Position? position = overridePosition ?? _currentPosition;
    
    // If no position available, try to get it now
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = position;
      } catch (e) {
        print('Error getting location for SOS: $e');
        // Continue without location if we can't get it
      }
    }
    
    // If still no position, use a default or skip location-dependent features
    if (position == null) {
      print('Warning: No location available for SOS alert');
      // Still send SMS without location
    }

    // Send SMS with live location (always)
    String message;
    if (position != null) {
      message = '🚨 EMERGENCY ALERT from PRAVASI AI 🚨\n\n'
          'I may be in danger. Please check my location immediately.\n\n'
          'Live Location:\n'
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}\n\n'
          'Time: ${DateTime.now().toString()}\n\n'
          'If you don\'t hear from me, please take necessary action.';
    } else {
      message = '🚨 EMERGENCY ALERT from PRAVASI AI 🚨\n\n'
          'I may be in danger. Please contact me immediately.\n\n'
          'Time: ${DateTime.now().toString()}\n\n'
          'If you don\'t hear from me, please take necessary action.';
    }

    if (emergencyContact != null && emergencyContact.isNotEmpty) {
      try {
        final smsUri = Uri.parse('sms:$emergencyContact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending SMS: $e');
      }
    }

    // If SOS auto-call is enabled and family contact exists, call with AI
    if (sosAutoCallEnabled && familyContactNumber != null && familyContactNumber.isNotEmpty) {
      try {
        // Request permission before calling
        if (onPermissionRequested != null) {
          final permissionGranted = await onPermissionRequested(true);
          if (permissionGranted && position != null) {
            final aiCallService = AIVoiceCallService();
            await aiCallService.loadApiKeyFromStorage();
            
            await aiCallService.callFamilyMemberWithAI(
              phoneNumber: familyContactNumber,
              emergencyType: 'SOS Emergency Alert',
              location: position,
              additionalDetails: 'User triggered SOS button. Immediate assistance may be required.',
            );
          }
        } else if (position != null) {
          // Auto-call without permission dialog (if callback not provided)
          final aiCallService = AIVoiceCallService();
          await aiCallService.loadApiKeyFromStorage();
          
          await aiCallService.callFamilyMemberWithAI(
            phoneNumber: familyContactNumber,
            emergencyType: 'SOS Emergency Alert',
            location: position,
            additionalDetails: 'User triggered SOS button. Immediate assistance may be required.',
          );
        }
      } catch (e) {
        print('Error calling family member: $e');
        // Continue even if call fails
      }
    }

    // Don't open maps automatically - user wants to see the call happen
    // Maps can be opened manually if needed
    // Removed automatic map opening to allow AI call to proceed without interruption
  }

  void stopMonitoring() {
    _safetyCheckTimer?.cancel();
    _safetyCheckTimer = null;
    _isSafetyCheckActive = false;
    _routePositions.clear();
    _lastRoutePosition = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Position? getCurrentPosition() => _currentPosition;
  bool get isSafetyCheckActive => _isSafetyCheckActive;
}

