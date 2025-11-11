// lib/services/real_driver_mode_service.dart
// Real driver mode detection using motion sensors and GPS
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class RealDriverModeService {
  static final RealDriverModeService _instance = RealDriverModeService._internal();
  factory RealDriverModeService() => _instance;
  RealDriverModeService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _analysisTimer;
  
  bool _isMonitoring = false;
  bool _isDriving = false;
  
  // Sensor data
  final List<double> _accelerationX = [];
  final List<double> _accelerationY = [];
  final List<double> _accelerationZ = [];
  final int _bufferSize = 20;
  
  double _currentSpeed = 0.0;
  DateTime? _drivingStartTime;
  
  // Detection thresholds
  static const double _minDrivingSpeed = 10.0; // km/h
  static const double _maxWalkingSpeed = 8.0; // km/h
  static const double _minAccelerationVariation = 2.0; // m/s² - vehicle motion
  static const int _minDrivingDuration = 30; // seconds - must drive for 30s to confirm
  
  // Callbacks
  Function(bool isDriving)? onDrivingStatusChanged;
  Function(double speed, double distance)? onDrivingUpdate;

  bool get isMonitoring => _isMonitoring;
  bool get isDriving => _isDriving;
  double get currentSpeed => _currentSpeed;

  /// Start monitoring for driver mode
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _isDriving = false;
    _accelerationX.clear();
    _accelerationY.clear();
    _accelerationZ.clear();
    _currentSpeed = 0.0;

    // Monitor accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _processAccelerometerData(event);
      },
      onError: (error) {
        print('Accelerometer error: $error');
      },
    );

    // Monitor gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        // Can use for additional detection
      },
      onError: (error) {
        print('Gyroscope error: $error');
      },
    );

    // Monitor GPS for speed
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentSpeed = position.speed * 3.6; // Convert to km/h
      _checkDrivingStatus();
    });

    // Periodic analysis
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _analyzeDrivingPattern();
    });
  }

  void _processAccelerometerData(AccelerometerEvent event) {
    _accelerationX.add(event.x);
    _accelerationY.add(event.y);
    _accelerationZ.add(event.z);
    
    // Keep buffer size
    if (_accelerationX.length > _bufferSize) {
      _accelerationX.removeAt(0);
      _accelerationY.removeAt(0);
      _accelerationZ.removeAt(0);
    }
  }

  void _checkDrivingStatus() {
    // Check if speed indicates driving
    if (_currentSpeed > _minDrivingSpeed) {
      if (!_isDriving) {
        _drivingStartTime = DateTime.now();
      }
    } else if (_currentSpeed < _maxWalkingSpeed) {
      // Likely not driving
      if (_isDriving && _drivingStartTime != null) {
        final duration = DateTime.now().difference(_drivingStartTime!);
        if (duration.inSeconds > 60) {
          // Was driving for more than 1 minute, now stopped
          _setDrivingStatus(false);
        }
      }
    }
  }

  void _analyzeDrivingPattern() {
    if (_accelerationX.length < 5) return;

    // Calculate acceleration variation (vehicles have more variation than walking)
    final xVariation = _calculateVariation(_accelerationX);
    final yVariation = _calculateVariation(_accelerationY);
    final zVariation = _calculateVariation(_accelerationZ);
    final maxVariation = [xVariation, yVariation, zVariation].reduce(max);

    // Multi-factor detection
    bool speedIndicatesDriving = _currentSpeed > _minDrivingSpeed;
    bool accelerationIndicatesDriving = maxVariation > _minAccelerationVariation;
    
    // Determine driving status
    if (speedIndicatesDriving && accelerationIndicatesDriving) {
      if (!_isDriving) {
        // Start driving detection
        _drivingStartTime = DateTime.now();
      } else {
        // Confirm driving if duration is sufficient
        if (_drivingStartTime != null) {
          final duration = DateTime.now().difference(_drivingStartTime!);
          if (duration.inSeconds >= _minDrivingDuration) {
            _setDrivingStatus(true);
          }
        }
      }
    } else if (!speedIndicatesDriving && _currentSpeed < _maxWalkingSpeed) {
      // Likely not driving
      if (_isDriving) {
        final duration = _drivingStartTime != null
            ? DateTime.now().difference(_drivingStartTime!).inSeconds
            : 0;
        if (duration > 120) { // Stopped for 2 minutes
          _setDrivingStatus(false);
        }
      }
    }
  }

  double _calculateVariation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  void _setDrivingStatus(bool driving) {
    if (_isDriving != driving) {
      _isDriving = driving;
      onDrivingStatusChanged?.call(driving);
      
      if (driving) {
        print('🚗 Driver mode activated - Speed: ${_currentSpeed.toStringAsFixed(1)} km/h');
      } else {
        print('🚶 Driver mode deactivated');
      }
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _isDriving = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    _analysisTimer?.cancel();
    _accelerationX.clear();
    _accelerationY.clear();
    _accelerationZ.clear();
  }
}

