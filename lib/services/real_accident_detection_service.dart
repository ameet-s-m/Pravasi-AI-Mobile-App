// lib/services/real_accident_detection_service.dart
// Real accident detection using device sensors (accelerometer, gyroscope)
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_voice_call_service.dart';

class RealAccidentDetectionService {
  static final RealAccidentDetectionService _instance = RealAccidentDetectionService._internal();
  factory RealAccidentDetectionService() => _instance;
  RealAccidentDetectionService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _monitoringTimer;
  
  bool _isMonitoring = false;
  bool _accidentDetected = false;
  
  // Sensor data buffers
  final List<double> _accelerationMagnitudes = [];
  final List<double> _gyroscopeMagnitudes = [];
  final int _bufferSize = 10; // Keep last 10 readings
  
  // Detection thresholds (calibrated for real accidents)
  static const double _impactThreshold = 15.0; // m/s² - sudden deceleration
  static const double _rotationThreshold = 8.0; // rad/s - sudden rotation
  static const double _speedDropThreshold = 0.7; // 70% speed drop in 2 seconds
  static const double _minSpeedForAccident = 20.0; // km/h - minimum speed to consider
  
  double _lastSpeed = 0.0;
  DateTime? _lastSpeedUpdate;
  Position? _currentPosition;
  
  // Callbacks
  Function(Position location, Map<String, dynamic> details)? onAccidentDetected;
  Function()? onFalseAlarm;

  bool get isMonitoring => _isMonitoring;
  bool get accidentDetected => _accidentDetected;

  /// Start real-time accident monitoring using device sensors
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _accidentDetected = false;
    _accelerationMagnitudes.clear();
    _gyroscopeMagnitudes.clear();
    _lastSpeed = 0.0;
    _lastSpeedUpdate = null;

    // Start accelerometer monitoring
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _processAccelerometerData(event);
      },
      onError: (error) {
        print('Accelerometer error: $error');
      },
    );

    // Start gyroscope monitoring
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        _processGyroscopeData(event);
      },
      onError: (error) {
        print('Gyroscope error: $error');
      },
    );

    // Start GPS monitoring for speed
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _checkSpeedChange(position);
    });

    // Periodic check for accident patterns
    _monitoringTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _analyzeAccidentPattern();
    });
  }

  void _processAccelerometerData(AccelerometerEvent event) {
    // Calculate magnitude of acceleration vector
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // Remove gravity (approximately 9.8 m/s²)
    final netAcceleration = (magnitude - 9.8).abs();
    
    _accelerationMagnitudes.add(netAcceleration);
    if (_accelerationMagnitudes.length > _bufferSize) {
      _accelerationMagnitudes.removeAt(0);
    }
  }

  void _processGyroscopeData(GyroscopeEvent event) {
    // Calculate magnitude of rotation
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    _gyroscopeMagnitudes.add(magnitude);
    if (_gyroscopeMagnitudes.length > _bufferSize) {
      _gyroscopeMagnitudes.removeAt(0);
    }
  }

  void _checkSpeedChange(Position position) {
    final speed = position.speed * 3.6; // Convert to km/h
    
    if (_lastSpeed > _minSpeedForAccident) {
      final speedDrop = (_lastSpeed - speed) / _lastSpeed;
      final timeDiff = _lastSpeedUpdate != null
          ? DateTime.now().difference(_lastSpeedUpdate!).inSeconds
          : 0;
      
      // Check for sudden speed drop (accident indicator)
      if (speedDrop > _speedDropThreshold && timeDiff <= 3) {
        // Significant speed drop detected
        _analyzeAccidentPattern();
      }
    }
    
    _lastSpeed = speed;
    _lastSpeedUpdate = DateTime.now();
  }

  void _analyzeAccidentPattern() {
    if (_accelerationMagnitudes.length < 3 || _accelerationMagnitudes.isEmpty) {
      return;
    }

    // Calculate peak acceleration
    final peakAcceleration = _accelerationMagnitudes.reduce(max);
    
    // Calculate average rotation
    double avgRotation = 0.0;
    if (_gyroscopeMagnitudes.isNotEmpty) {
      avgRotation = _gyroscopeMagnitudes.reduce((a, b) => a + b) / _gyroscopeMagnitudes.length;
    }

    // Multi-factor accident detection
    bool impactDetected = peakAcceleration > _impactThreshold;
    bool rotationDetected = avgRotation > _rotationThreshold;
    bool speedDropDetected = _lastSpeed > _minSpeedForAccident && 
        _lastSpeedUpdate != null &&
        DateTime.now().difference(_lastSpeedUpdate!).inSeconds <= 3;

    // Accident detected if multiple indicators are present
    if ((impactDetected && rotationDetected) || 
        (impactDetected && speedDropDetected) ||
        (rotationDetected && speedDropDetected && impactDetected)) {
      
      if (!_accidentDetected && _currentPosition != null) {
        _triggerAccidentDetection();
      }
    }
  }

  Future<void> _triggerAccidentDetection() async {
    if (_accidentDetected || _currentPosition == null) return;
    
    _accidentDetected = true;
    
    // Get accident details
    final details = {
      'impact': _accelerationMagnitudes.isNotEmpty 
          ? _accelerationMagnitudes.reduce(max).toStringAsFixed(2)
          : '0.0',
      'rotation': _gyroscopeMagnitudes.isNotEmpty
          ? _gyroscopeMagnitudes.reduce(max).toStringAsFixed(2)
          : '0.0',
      'speed': _lastSpeed.toStringAsFixed(1),
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('🚨 ACCIDENT DETECTED: Impact=${details['impact']} m/s², Rotation=${details['rotation']} rad/s, Speed=${details['speed']} km/h');
    
    // Notify callback
    onAccidentDetected?.call(_currentPosition!, details);
    
    // Trigger emergency response
    await _triggerEmergencyResponse(_currentPosition!, details);
  }

  Future<void> _triggerEmergencyResponse(Position location, Map<String, dynamic> details) async {
    // Get emergency contacts
    final prefs = await SharedPreferences.getInstance();
    final familyContactNumber = prefs.getString('family_contact_number') ?? '';
    final ambulanceWhatsAppNumber = prefs.getString('ambulance_whatsapp_number') ?? '108';
    final ambulanceAutoCallEnabled = prefs.getBool('ambulance_auto_call_enabled') ?? false;
    
    // Create emergency message with location
    final mapUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    final emergencyMessage = '🚨 ACCIDENT DETECTED 🚨\n\n'
        'An accident has been automatically detected by PRAVASI AI safety system.\n\n'
        '📍 Location:\n'
        'Latitude: ${location.latitude}\n'
        'Longitude: ${location.longitude}\n'
        'Google Maps: $mapUrl\n\n'
        '📊 Detection Details:\n'
        'Impact: ${details['impact']} m/s²\n'
        'Rotation: ${details['rotation']} rad/s\n'
        'Speed: ${details['speed']} km/h\n'
        'Time: ${DateTime.now()}\n\n'
        'Please send help immediately!';
    
    // Call family member immediately
    if (familyContactNumber.isNotEmpty) {
      try {
        // Make real phone call
        final callUri = Uri.parse('tel:$familyContactNumber');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        }
        
        // Send SMS with location
        final smsUri = Uri.parse('sms:$familyContactNumber?body=${Uri.encodeComponent(emergencyMessage)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
        
        // Send WhatsApp with location
        final cleanNumber = familyContactNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(emergencyMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
        
        // AI voice call - ALWAYS ENABLED (AI assistant automatically talks in calls)
        try {
          final aiCallService = AIVoiceCallService();
          await aiCallService.loadApiKeyFromStorage();
          await aiCallService.callFamilyMemberWithAI(
            phoneNumber: familyContactNumber,
            emergencyType: 'Accident Detected',
            location: location,
            additionalDetails: 'Accident automatically detected by sensors. Impact: ${details['impact']} m/s², Speed: ${details['speed']} km/h',
          );
        } catch (e) {
          print('Error making AI call: $e');
        }
      } catch (e) {
        print('Error calling family: $e');
      }
    }
    
    // Call ambulance
    if (ambulanceAutoCallEnabled && ambulanceWhatsAppNumber.isNotEmpty) {
      try {
        final cleanAmbulanceNumber = ambulanceWhatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');
        
        // Call ambulance
        final callUri = Uri.parse('tel:$cleanAmbulanceNumber');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        }
        
        // Send WhatsApp to ambulance
        final whatsappUri = Uri.parse('https://wa.me/$cleanAmbulanceNumber?text=${Uri.encodeComponent(emergencyMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
        
        // AI call to ambulance if enabled
        try {
          final aiCallService = AIVoiceCallService();
          await aiCallService.loadApiKeyFromStorage();
          await aiCallService.callAmbulanceWithAI(
            phoneNumber: cleanAmbulanceNumber,
            location: location,
            accidentDetails: 'Accident automatically detected. Impact: ${details['impact']} m/s², Speed: ${details['speed']} km/h',
          );
        } catch (e) {
          print('Error making AI ambulance call: $e');
        }
      } catch (e) {
        print('Error calling ambulance: $e');
      }
    }
    
    // Also call emergency number 108
    try {
      final emergencyCallUri = Uri.parse('tel:108');
      if (await canLaunchUrl(emergencyCallUri)) {
        await launchUrl(emergencyCallUri);
      }
    } catch (e) {
      print('Error calling 108: $e');
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accidentDetected = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    _monitoringTimer?.cancel();
    _accelerationMagnitudes.clear();
    _gyroscopeMagnitudes.clear();
  }

  void resetDetection() {
    _accidentDetected = false;
  }
}

