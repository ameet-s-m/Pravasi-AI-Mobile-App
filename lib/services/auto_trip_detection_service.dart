// lib/services/auto_trip_detection_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'trip_data_service.dart';
import '../models/models.dart';
import 'package:flutter/material.dart';

class AutoTripDetectionService {
  static final AutoTripDetectionService _instance = AutoTripDetectionService._internal();
  factory AutoTripDetectionService() => _instance;
  AutoTripDetectionService._internal();

  bool _isActive = false;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _tripCheckTimer;
  
  Position? _lastPosition;
  DateTime? _tripStartTime;
  final List<Position> _currentTripPoints = [];
  double _currentTripDistance = 0.0;
  
  // Thresholds for automatic trip detection
  static const double _movementThreshold = 50.0; // meters - minimum movement to start trip
  static const double _speedThreshold = 5.0; // km/h - minimum speed to consider as trip
  static const int _tripStartDelay = 30; // seconds - wait before confirming trip started
  static const int _tripEndDelay = 120; // seconds - wait before ending trip (2 minutes stationary)
  
  DateTime? _potentialTripStart;
  DateTime? _lastMovementTime;
  
  Function()? onTripStarted;
  Function(Trip)? onTripCompleted;

  bool get isActive => _isActive;
  bool get isTracking => _isTracking;

  Future<void> startAutoDetection() async {
    if (_isActive) return;
    
    _isActive = true;
    
    // Start monitoring location
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });
    
    // Periodic check for trip status
    _tripCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkTripStatus();
    });
  }

  void _handleLocationUpdate(Position position) {
    if (!_isActive) return;
    
    if (_lastPosition == null) {
      _lastPosition = position;
      return;
    }
    
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    
    final speed = position.speed * 3.6; // Convert to km/h
    
    // Check if user is moving
    if (distance > _movementThreshold && speed > _speedThreshold) {
      _lastMovementTime = DateTime.now();
      
      if (!_isTracking) {
        // Potential trip start
        if (_potentialTripStart == null) {
          _potentialTripStart = DateTime.now();
        } else {
          // Check if enough time has passed to confirm trip start
          final timeSincePotentialStart = DateTime.now().difference(_potentialTripStart!);
          if (timeSincePotentialStart.inSeconds >= _tripStartDelay) {
            _startTrip(position);
          }
        }
      } else {
        // Trip is active - record point
        _currentTripPoints.add(position);
        _currentTripDistance += distance / 1000; // Convert to km
      }
    }
    
    _lastPosition = position;
  }

  void _startTrip(Position startPosition) {
    if (_isTracking) return;
    
    _isTracking = true;
    _tripStartTime = DateTime.now();
    _currentTripPoints.clear();
    _currentTripPoints.add(startPosition);
    _currentTripDistance = 0.0;
    _potentialTripStart = null;
    
    print('🚗 Auto trip detection: Trip started at $_tripStartTime');
    onTripStarted?.call();
  }

  void _checkTripStatus() {
    if (!_isTracking) return;
    
    // Check if user has been stationary for too long
    if (_lastMovementTime != null) {
      final timeSinceLastMovement = DateTime.now().difference(_lastMovementTime!);
      
      if (timeSinceLastMovement.inSeconds >= _tripEndDelay) {
        // Trip ended - user has been stationary for 2 minutes
        _endTrip();
      }
    }
  }

  Future<void> _endTrip() async {
    if (!_isTracking || _tripStartTime == null || _currentTripPoints.length < 2) {
      return;
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(_tripStartTime!);
    
    // Only save trips that are meaningful (at least 100m and 1 minute)
    if (_currentTripDistance < 0.1 || duration.inSeconds < 60) {
      _resetTrip();
      return;
    }
    
    // Format duration
    String durationStr = '';
    if (duration.inHours > 0) {
      durationStr = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      durationStr = '${duration.inMinutes}m';
    }
    
    // Determine mode from average speed
    final avgSpeed = _currentTripDistance / (duration.inHours + duration.inMinutes / 60.0);
    String mode = 'car';
    IconData icon = Icons.directions_car;
    Color color = Colors.blue;
    
    if (avgSpeed < 5) {
      mode = 'walking';
      icon = Icons.directions_walk;
      color = Colors.blue;
    } else if (avgSpeed < 20) {
      mode = 'bike';
      icon = Icons.directions_bike;
      color = Colors.orange;
    } else if (avgSpeed < 50) {
      mode = 'car';
      icon = Icons.directions_car;
      color = Colors.blue;
    } else {
      mode = 'highway';
      icon = Icons.directions_car;
      color = Colors.purple;
    }
    
    // Create trip title
    final title = 'Auto Tracked Trip';
    
    // Convert Position list to RoutePoint list
    final routePoints = _currentTripPoints.map((p) => RoutePoint(
      latitude: p.latitude,
      longitude: p.longitude,
    )).toList();

    // Save trip with real GPS coordinates
    final trip = Trip(
      tripId: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      mode: mode,
      distance: _currentTripDistance,
      duration: durationStr,
      time: _tripStartTime!.toString().substring(11, 16),
      destination: 'Auto-detected destination',
      icon: icon,
      isCompleted: true,
      companions: 'Solo',
      purpose: 'Daily Travel',
      notes: 'Automatically detected and tracked trip. ${_currentTripPoints.length} GPS points recorded.',
      color: color,
      routePoints: routePoints,
      startLocation: routePoints.isNotEmpty 
          ? RoutePoint(
              latitude: routePoints.first.latitude,
              longitude: routePoints.first.longitude,
            )
          : null,
      endLocation: routePoints.isNotEmpty
          ? RoutePoint(
              latitude: routePoints.last.latitude,
              longitude: routePoints.last.longitude,
            )
          : null,
      startTime: _tripStartTime,
      endTime: endTime,
    );
    
    try {
      final tripDataService = TripDataService();
      await tripDataService.initialize();
      await tripDataService.addTrip(trip);
      
      print('✅ Auto trip saved: ${_currentTripDistance.toStringAsFixed(2)} km, $durationStr');
      onTripCompleted?.call(trip);
    } catch (e) {
      print('Error saving auto trip: $e');
    }
    
    _resetTrip();
  }

  void _resetTrip() {
    _isTracking = false;
    _tripStartTime = null;
    _potentialTripStart = null;
    _lastMovementTime = null;
    _currentTripPoints.clear();
    _currentTripDistance = 0.0;
  }

  void stopAutoDetection() {
    _isActive = false;
    _positionSubscription?.cancel();
    _tripCheckTimer?.cancel();
    
    // End current trip if tracking
    if (_isTracking) {
      _endTrip();
    }
    
    _resetTrip();
  }

  // Manual trip control (for testing or override)
  void startManualTrip() {
    if (_lastPosition != null) {
      _startTrip(_lastPosition!);
    }
  }

  void endManualTrip() {
    if (_isTracking) {
      _endTrip();
    }
  }
}

