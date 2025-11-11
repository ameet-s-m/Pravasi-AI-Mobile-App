// lib/services/emotion_detection_service.dart
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class EmotionDetectionService {
  static final EmotionDetectionService _instance = EmotionDetectionService._internal();
  factory EmotionDetectionService() => _instance;
  EmotionDetectionService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  bool _isMonitoring = false;
  double _baselineHeartRate = 70.0;
  double _currentHeartRate = 70.0;
  
  Function()? onDistressDetected;
  Function()? onPanicDetected;
  Function()? onEmotionalStateChange;

  // Simulated wearable data (in real app, connect to actual wearable)
  Timer? _heartRateSimulator;
  Timer? _emotionAnalyzer;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Monitor accelerometer for sudden movements (panic indicators)
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _analyzeMovement(event.x, event.y, event.z);
    });

    // Monitor gyroscope for orientation changes
    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      _analyzeOrientation(event.x, event.y, event.z);
    });

    // Simulate heart rate monitoring (in real app, get from wearable)
    _heartRateSimulator = Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulateHeartRate();
    });

    // Analyze emotional state periodically
    _emotionAnalyzer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _analyzeEmotionalState();
    });
  }

  void _analyzeMovement(double x, double y, double z) {
    final magnitude = (x * x + y * y + z * z) / 1000;
    
    // Sudden high acceleration might indicate struggle or panic
    if (magnitude > 50) {
      _detectPanic();
    }
  }

  void _analyzeOrientation(double x, double y, double z) {
    // Sudden orientation changes might indicate struggle
    final change = (x.abs() + y.abs() + z.abs());
    if (change > 5) {
      _detectDistress();
    }
  }

  void _simulateHeartRate() {
    // Simulate heart rate changes
    // In real app, get from wearable device
    final variation = (DateTime.now().millisecond % 20) - 10;
    _currentHeartRate = _baselineHeartRate + variation;
    
    // High heart rate might indicate stress/panic
    if (_currentHeartRate > _baselineHeartRate + 30) {
      _detectDistress();
    }
  }

  void _analyzeEmotionalState() {
    // Combine multiple factors to detect emotional state
    final heartRateElevated = _currentHeartRate > _baselineHeartRate + 20;
    
    if (heartRateElevated) {
      onDistressDetected?.call();
    }
  }

  void _detectPanic() {
    onPanicDetected?.call();
    // Trigger emergency response
  }

  void _detectDistress() {
    onDistressDetected?.call();
    // Trigger safety check
  }

  void updateBaselineHeartRate(double rate) {
    _baselineHeartRate = rate;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _heartRateSimulator?.cancel();
    _emotionAnalyzer?.cancel();
  }

  double get currentHeartRate => _currentHeartRate;
  bool get isMonitoring => _isMonitoring;
}

