// lib/services/driving_mode_service.dart
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sensors_plus/sensors_plus.dart';

class DrivingModeService {
  static final DrivingModeService _instance = DrivingModeService._internal();
  factory DrivingModeService() => _instance;
  DrivingModeService._internal();

  bool _isActive = false;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _speedCheckTimer;
  
  double _currentSpeed = 0.0; // km/h
  final List<double> _speedHistory = [];
  DateTime? _lastSpeedUpdate;
  Position? _currentPosition;
  
  // Sensor data for speed calculation
  final List<double> _accelerationMagnitudes = [];
  final List<Position> _positionHistory = [];
  DateTime? _lastPositionTime;
  Position? _lastPosition;
  static const int _sensorBufferSize = 10;
  
  // Thresholds
  static const double _suddenStopThreshold = 5.0; // km/h - below this is considered stopped
  static const double _highSpeedThreshold = 30.0; // km/h - above this is considered moving
  static const int _suddenStopTimeWindow = 5; // seconds - time window for sudden stop detection
  static const double _unexpectedSpeedChangeThreshold = 0.5; // 50% speed change is unexpected
  static const double _drasticSpeedChangeThreshold = 0.7; // 70% speed change is drastic (for accidents)
  
  Function(String message)? onSafetyAlert;
  Function()? onAreYouAlrightCheck;
  Function()? onAutoSOSTrigger; // Callback when auto-SOS should be triggered

  bool get isActive => _isActive;
  double get currentSpeed => _currentSpeed;
  Position? get currentPosition => _currentPosition;

  Future<void> startDrivingMode() async {
    if (_isActive) return;
    
    // Check location permissions first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Please grant location permissions.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
    }
    
    _isActive = true;
    _speedHistory.clear();
    _currentSpeed = 0.0;
    
    try {
      // Start monitoring accelerometer for motion detection
      if (!kIsWeb) {
        _accelerometerSubscription = accelerometerEventStream().listen(
          (AccelerometerEvent event) {
            _processAccelerometerData(event);
          },
          onError: (error) {
            print('Accelerometer error: $error');
          },
        );
      }

      // Start monitoring position and speed using GPS
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // Update every 3 meters for better accuracy
        ),
      ).listen(
        (Position position) {
          _updateSpeed(position);
        },
        onError: (error) {
          print('Error in position stream: $error');
          // Don't stop driving mode on error, just log it
        },
      );

      // Periodic safety checks
      _speedCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_isActive) {
          _checkSafetyConditions();
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      _isActive = false;
      throw Exception('Failed to start location monitoring: $e');
    }
  }

  void _processAccelerometerData(AccelerometerEvent event) {
    if (!_isActive) return;
    
    // Calculate magnitude of acceleration vector
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // Remove gravity (approximately 9.8 m/s²) to get net acceleration
    final netAcceleration = (magnitude - 9.8).abs();
    
    _accelerationMagnitudes.add(netAcceleration);
    if (_accelerationMagnitudes.length > _sensorBufferSize) {
      _accelerationMagnitudes.removeAt(0);
    }
  }

  void _updateSpeed(Position position) {
    _currentPosition = position;
    
    // Method 1: Use GPS speed directly (from device sensors)
    double gpsSpeedKmh = position.speed * 3.6; // Convert m/s to km/h
    
    // Method 2: Calculate speed from position changes (more accurate)
    double calculatedSpeedKmh = gpsSpeedKmh;
    
    if (_lastPosition != null && _lastPositionTime != null) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastPositionTime!).inMilliseconds / 1000.0; // seconds
      
      if (timeDiff > 0) {
        // Calculate distance between positions
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        ); // meters
        
        // Calculate speed: distance / time
        final calculatedSpeedMs = distance / timeDiff; // m/s
        calculatedSpeedKmh = calculatedSpeedMs * 3.6; // km/h
        
        // Use the more reliable value (GPS speed if available and reasonable, otherwise calculated)
        if (gpsSpeedKmh > 0 && gpsSpeedKmh < 200) {
          // GPS speed is reasonable, use it
          _currentSpeed = gpsSpeedKmh;
        } else if (calculatedSpeedKmh > 0 && calculatedSpeedKmh < 200) {
          // Use calculated speed
          _currentSpeed = calculatedSpeedKmh;
        } else {
          // Both seem unreliable, use GPS as fallback
          _currentSpeed = gpsSpeedKmh > 0 ? gpsSpeedKmh : 0.0;
        }
      }
    } else {
      // First reading, use GPS speed
      _currentSpeed = gpsSpeedKmh;
    }
    
    // Store position history for speed calculation
    _positionHistory.add(position);
    if (_positionHistory.length > 10) {
      _positionHistory.removeAt(0);
    }
    
    _lastPosition = position;
    _lastPositionTime = DateTime.now();
    
    // Update speed history (keep last 10 readings)
    _speedHistory.add(_currentSpeed);
    if (_speedHistory.length > 10) {
      _speedHistory.removeAt(0);
    }
    
    _lastSpeedUpdate = DateTime.now();
  }

  void _checkSafetyConditions() {
    if (!_isActive || _speedHistory.length < 2) return;

    // Check for sudden stop
    if (_detectSuddenStop()) {
      _triggerSafetyCheck('Sudden stop detected');
      return;
    }

    // Check for unexpected speed changes
    if (_detectUnexpectedSpeedChange()) {
      _triggerSafetyCheck('Unexpected speed change detected');
      return;
    }

    // Check for drastic speed changes (potential accident)
    if (_detectDrasticSpeedChange()) {
      _triggerSafetyCheck('Drastic speed change detected - possible accident');
      return;
    }

    // Check if vehicle was moving and suddenly stopped
    if (_wasMovingAndStopped()) {
      _triggerSafetyCheck('Vehicle stopped unexpectedly');
      return;
    }
  }

  bool _detectSuddenStop() {
    if (_speedHistory.length < 3) return false;
    
    // Check if speed dropped from high (>30 km/h) to very low (<5 km/h) quickly
    final recentSpeeds = _speedHistory.sublist(_speedHistory.length - 3);
    final maxSpeed = recentSpeeds.reduce((a, b) => a > b ? a : b);
    final minSpeed = recentSpeeds.reduce((a, b) => a < b ? a : b);
    
    // If was going fast and suddenly stopped
    if (maxSpeed > _highSpeedThreshold && minSpeed < _suddenStopThreshold) {
      // Check time window
      if (_lastSpeedUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(_lastSpeedUpdate!).inSeconds;
        if (timeSinceUpdate < _suddenStopTimeWindow) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _detectUnexpectedSpeedChange() {
    if (_speedHistory.length < 2) return false;
    
    // Check for sudden speed drop (>50% in short time)
    final current = _speedHistory.last;
    final previous = _speedHistory[_speedHistory.length - 2];
    
    if (previous > _highSpeedThreshold) {
      final speedDrop = (previous - current) / previous;
      if (speedDrop > _unexpectedSpeedChangeThreshold && current < _suddenStopThreshold) {
        return true;
      }
    }
    
    return false;
  }

  bool _wasMovingAndStopped() {
    if (_speedHistory.length < 2) return false;
    
    // Check if we had significant speed and now we're stopped
    final avgRecentSpeed = _speedHistory.length >= 5
        ? _speedHistory.sublist(_speedHistory.length - 5).reduce((a, b) => a + b) / 5
        : _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
    
    final currentSpeed = _speedHistory.last;
    
    // Was moving (>20 km/h) and now stopped (<5 km/h)
    if (avgRecentSpeed > 20.0 && currentSpeed < _suddenStopThreshold) {
      return true;
    }
    
    return false;
  }

  bool _detectDrasticSpeedChange() {
    if (_speedHistory.length < 3) return false;
    
    // Check for very drastic speed drop (>70% in short time) - indicates possible accident
    final recentSpeeds = _speedHistory.sublist(_speedHistory.length - 3);
    final maxSpeed = recentSpeeds.reduce((a, b) => a > b ? a : b);
    final minSpeed = recentSpeeds.reduce((a, b) => a < b ? a : b);
    
    // If was going fast (>40 km/h) and speed dropped drastically (>70%)
    if (maxSpeed > 40.0) {
      final speedDrop = (maxSpeed - minSpeed) / maxSpeed;
      if (speedDrop > _drasticSpeedChangeThreshold && minSpeed < _suddenStopThreshold) {
        return true;
      }
    }
    
    return false;
  }

  void _triggerSafetyCheck(String reason) {
    if (!_isActive) return;
    
    // Vibrate device
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      // Continuous vibration pattern
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_isActive && !kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_isActive && !kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      });
    }
    
    // Trigger safety check callback
    onAreYouAlrightCheck?.call();
    onSafetyAlert?.call(reason);
  }

  void stopDrivingMode() {
    _isActive = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _speedCheckTimer?.cancel();
    _speedCheckTimer = null;
    _speedHistory.clear();
    _accelerationMagnitudes.clear();
    _positionHistory.clear();
    _currentSpeed = 0.0;
    _lastPosition = null;
    _lastPositionTime = null;
  }

  String getSafetyStatus() {
    if (!_isActive) return 'Not Active';
    
    if (_currentSpeed < _suddenStopThreshold) {
      return 'Stopped';
    } else if (_currentSpeed < 20) {
      return 'Slow Speed';
    } else if (_currentSpeed < 60) {
      return 'Normal Speed';
    } else {
      return 'High Speed';
    }
  }

  double getAverageSpeed() {
    if (_speedHistory.isEmpty) return 0.0;
    return _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
  }
}

