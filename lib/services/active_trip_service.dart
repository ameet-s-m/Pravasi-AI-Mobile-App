// lib/services/active_trip_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'trip_data_service.dart';

class ActiveTripService {
  static final ActiveTripService _instance = ActiveTripService._internal();
  factory ActiveTripService() => _instance;
  ActiveTripService._internal();

  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _updateTimer;
  
  Position? _currentPosition;
  DateTime? _tripStartTime;
  final List<Position> _routePoints = [];
  double _totalDistance = 0.0;
  Position? _lastPosition;
  String? _currentTripId;
  
  // Callbacks
  Function(Position)? onLocationUpdate;
  Function(double distance, Duration duration, String speed)? onTripUpdate;
  Function(Trip)? onTripCompleted;
  
  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  List<Position> get routePoints => List.unmodifiable(_routePoints);
  double get totalDistance => _totalDistance;
  Duration get duration => _tripStartTime != null 
      ? DateTime.now().difference(_tripStartTime!) 
      : Duration.zero;

  Future<void> startTrip({
    String? tripId,
    String? title,
    String? destination,
  }) async {
    if (_isTracking) return;
    
    // Request location permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    _isTracking = true;
    _tripStartTime = DateTime.now();
    _routePoints.clear();
    _totalDistance = 0.0;
    _lastPosition = null;
    _currentTripId = tripId ?? 'trip_${DateTime.now().millisecondsSinceEpoch}';

    // Get initial position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _routePoints.add(_currentPosition!);
      _lastPosition = _currentPosition;
      onLocationUpdate?.call(_currentPosition!);
    } catch (e) {
      print('Error getting initial position: $e');
    }

    // Start location stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters for real-time tracking
      ),
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });

    // Start update timer for UI updates
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTracking && _tripStartTime != null) {
        final speed = _currentPosition?.speed != null 
            ? '${(_currentPosition!.speed * 3.6).toStringAsFixed(0)} km/h'
            : '0 km/h';
        onTripUpdate?.call(
          _totalDistance,
          duration,
          speed,
        );
      }
    });
  }

  void _handleLocationUpdate(Position position) {
    if (!_isTracking) return;

    _currentPosition = position;
    _routePoints.add(position);
    onLocationUpdate?.call(position);

    // Calculate distance
    if (_lastPosition != null) {
      final segmentDistance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      ) / 1000; // Convert to km
      _totalDistance += segmentDistance;
    }

    _lastPosition = position;
  }

  Future<Trip> stopTrip({
    String? title,
    String? destination,
    String? mode,
    String? companions,
    String? purpose,
    String? notes,
  }) async {
    if (!_isTracking || _tripStartTime == null || _routePoints.isEmpty) {
      throw Exception('No active trip to stop');
    }

    _isTracking = false;
    _positionSubscription?.cancel();
    _updateTimer?.cancel();

    final endTime = DateTime.now();
    final tripDuration = endTime.difference(_tripStartTime!);

    // Format duration
    String durationStr = '';
    if (tripDuration.inHours > 0) {
      durationStr = '${tripDuration.inHours}h ${tripDuration.inMinutes.remainder(60)}m';
    } else {
      durationStr = '${tripDuration.inMinutes}m';
    }

    // Determine mode from average speed if not provided
    String tripMode = mode ?? 'car';
    IconData icon = Icons.directions_car;
    Color color = Colors.blue;

    if (_totalDistance > 0 && tripDuration.inHours > 0) {
      final avgSpeed = _totalDistance / (tripDuration.inHours + tripDuration.inMinutes / 60.0);
      if (avgSpeed < 5) {
        tripMode = 'walking';
        icon = Icons.directions_walk;
        color = Colors.green;
      } else if (avgSpeed < 20) {
        tripMode = 'bike';
        icon = Icons.directions_bike;
        color = Colors.orange;
      } else if (avgSpeed < 50) {
        tripMode = 'car';
        icon = Icons.directions_car;
        color = Colors.blue;
      } else {
        tripMode = 'highway';
        icon = Icons.directions_car;
        color = Colors.purple;
      }
    }

    // Convert Position list to RoutePoint list
    final routePoints = _routePoints.map((p) => RoutePoint(
      latitude: p.latitude,
      longitude: p.longitude,
    )).toList();

    // Create trip
    final trip = Trip(
      tripId: _currentTripId,
      title: title ?? 'Tracked Trip',
      mode: tripMode,
      distance: _totalDistance,
      duration: durationStr,
      time: _tripStartTime!.toString().substring(11, 16),
      destination: destination ?? 'Tracked destination',
      icon: icon,
      isCompleted: true,
      companions: companions ?? 'Solo',
      purpose: purpose ?? 'Travel',
      notes: notes ?? 'Real-time GPS tracked trip. ${_routePoints.length} location points recorded.',
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

    // Save trip
    try {
      final tripDataService = TripDataService();
      await tripDataService.initialize();
      await tripDataService.addTrip(trip);
      onTripCompleted?.call(trip);
    } catch (e) {
      print('Error saving trip: $e');
    }

    // Reset
    _reset();

    return trip;
  }

  void _reset() {
    _isTracking = false;
    _tripStartTime = null;
    _routePoints.clear();
    _totalDistance = 0.0;
    _lastPosition = null;
    _currentPosition = null;
    _currentTripId = null;
  }

  void pauseTrip() {
    _positionSubscription?.cancel();
  }

  void resumeTrip() {
    if (!_isTracking) return;
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });
  }

  void dispose() {
    _positionSubscription?.cancel();
    _updateTimer?.cancel();
    _reset();
  }
}

