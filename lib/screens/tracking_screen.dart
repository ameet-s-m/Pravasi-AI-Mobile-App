// lib/screens/tracking_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/safety_service.dart';
import '../services/voice_service.dart';
import '../services/route_learning_service.dart';
import '../services/emotion_detection_service.dart';
import '../services/accident_detection_service.dart';
import '../services/emergency_response_service.dart';
import '../services/hotel_service.dart';
import '../services/weather_service.dart';
import '../services/trip_data_service.dart';
import '../services/database_service.dart';
import 'route_verification_screen.dart';
import 'hotels_screen.dart';

class TrackingScreen extends StatefulWidget {
  final PlannedTrip? trip;
  const TrackingScreen({super.key, this.trip});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final SafetyService _safetyService = SafetyService();
  final VoiceService _voiceService = VoiceService();
  final RouteLearningService _routeLearning = RouteLearningService();
  final EmotionDetectionService _emotionService = EmotionDetectionService();
  final AccidentDetectionService _accidentService = AccidentDetectionService();
  final HotelService _hotelService = HotelService();
  final WeatherService _weatherService = WeatherService();
  bool _isTracking = false;
  bool _isMotorcycleMode = false;
  bool _isPaused = false;
  Position? _currentPosition;
  String _speed = '0 km/h';
  double _distance = 0.0;
  Duration _duration = Duration.zero;
  Timer? _trackingTimer;
  DateTime? _startTime;
  Position? _lastPosition;
  bool _showSafetyDialog = false;
  StreamSubscription<Position>? _positionSubscription;
  final List<Position> _routePoints = []; // REAL GPS route tracking

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _initializeVoiceCommands();
  }

  void _initializeVoiceCommands() {
    _voiceService.onVoiceCommand = (command) {
      if (command == 'safe') {
        _safetyService.confirmSafety();
      }
    };
    _voiceService.onSOSVoice = () {
      _triggerEmergency();
    };
    
    // Setup emotion detection
    _emotionService.onDistressDetected = () {
      if (_currentPosition != null) {
        _handleEmotionBasedEmergency();
      }
    };
    
    _emotionService.onPanicDetected = () {
      if (_currentPosition != null) {
        _triggerEmergency();
      }
    };
  }
  
  Future<void> _handleEmotionBasedEmergency() async {
    if (_currentPosition != null) {
      final emergencyService = EmergencyResponseService();
      await emergencyService.handleEmotionBasedEmergency(_currentPosition!);
    }
  }
  
  Future<void> _enableMotorcycleMode() async {
    setState(() {
      _isMotorcycleMode = true;
    });
    await _accidentService.startMotorcycleMonitoring();
    _accidentService.onAccidentDetected = (location) {
      _handleAccident(location);
    };
  }
  
  void _handleAccident(Position location) {
    final emergencyService = EmergencyResponseService();
    emergencyService.handleAccidentEmergency(location);
  }

  Future<void> _initializeTracking() async {
    // Request location permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied');
      return;
    }

    // Get initial position
    _currentPosition = await Geolocator.getCurrentPosition();
    _lastPosition = _currentPosition;
    _startTime = DateTime.now();

    // Start route monitoring if trip has planned route
    if (widget.trip?.plannedRoute != null && widget.trip!.plannedRoute!.isNotEmpty) {
      List<Position> routePositions = widget.trip!.plannedRoute!.map((point) => 
        Position(
          latitude: point.latitude,
          longitude: point.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        )
      ).toList();

      _safetyService.startRouteMonitoring(
        plannedRoute: routePositions,
        onDeviation: (message) {
          if (!_showSafetyDialog) {
            _checkRouteWithLearning(message);
          }
        },
        onSafetyCheck: () {
          if (!_showSafetyDialog) {
            _showSafetyCheckDialog();
          }
        },
      );

      _safetyService.onEmergencyTriggered = () {
        _showEmergencyAlert();
      };
    }
    
    // Start emotion detection
    await _emotionService.startMonitoring();
    
    // Setup hotel monitoring
    _hotelService.onNearbyHotel = (hotel) {
      _showHotelAlert(hotel);
    };
    
    // Setup weather alerts
    _weatherService.onWeatherAlert = (alert) {
      _showWeatherAlert(alert);
    };
    
    // Start monitoring for hotels and weather
    if (_currentPosition != null) {
      _hotelService.startNearbyHotelMonitoring(_currentPosition!);
      _weatherService.checkWeatherAlerts(_currentPosition!);
    }
    
    // Ask if motorcycle mode
    _askMotorcycleMode();
  }
  
  void _showHotelAlert(Hotel hotel) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🏨 Hotel Nearby'),
        content: Text(
          '${hotel.name} is nearby (${hotel.distance.toStringAsFixed(1)} km)\n'
          'Price: ${hotel.formattedPrice}\n'
          'Rating: ${hotel.rating} ⭐',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('View Hotels'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => HotelsScreen(location: _currentPosition),
                ),
              );
            },
          ),
          CupertinoDialogAction(
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  void _showWeatherAlert(WeatherAlert alert) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('⚠️ ${alert.type} Alert'),
        content: Text(alert.message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  void _checkRouteWithLearning(String message) async {
    if (_currentPosition != null) {
      final isExpected = await _routeLearning.isExpectedRoute('current_trip', _currentPosition!);
      
      if (!isExpected) {
        // Unexpected route - require verification
        final verified = await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => RouteVerificationScreen(
              routeType: 'current_trip',
              currentPosition: _currentPosition!,
            ),
          ),
        );
        
        if (verified != true) {
          // Not verified - emergency already triggered
          return;
        }
      } else {
        // Expected route but still deviated - show normal safety check
        _showRouteDeviationDialog(message);
      }
    }
  }
  
  void _askMotorcycleMode() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Motorcycle Mode'),
        content: const Text('Are you traveling by motorcycle? This will enable accident detection.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.pop(context);
              _enableMotorcycleMode();
            },
          ),
          CupertinoDialogAction(
            child: const Text('No'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _startTrip() {
    setState(() {
      _isTracking = true;
    });

    _startTracking();
  }

  void _startTracking() {
    _startTime = DateTime.now();
    _routePoints.clear();
    _distance = 0.0;
    _duration = Duration.zero;
    
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _updateTracking();
      }
    });

    // REAL GPS tracking - track location continuously
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters - REAL tracking
      ),
    ).listen((Position position) {
      if (!_isPaused && _isTracking) {
        // Save route point for REAL route tracking
        _routePoints.add(position);
        
        setState(() {
          _currentPosition = position;
          if (_lastPosition != null) {
            final segmentDistance = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            ) / 1000; // Convert to km
            _distance += segmentDistance;
          }
          _lastPosition = position;
          _speed = '${(position.speed * 3.6).toStringAsFixed(0)} km/h';
        });
      }
    });
  }

  void _updateTracking() {
    if (_startTime != null) {
      setState(() {
        _duration = DateTime.now().difference(_startTime!);
      });
    }
  }

  void _showRouteDeviationDialog(String message) {
    setState(() {
      _showSafetyDialog = true;
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('⚠️ Route Deviation Detected'),
        content: Text('$message\n\nAre you safe?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('I Need Help'),
            onPressed: () {
              Navigator.pop(context);
              _triggerEmergency();
            },
          ),
          CupertinoDialogAction(
            child: const Text('I Am Safe'),
            onPressed: () {
              Navigator.pop(context);
              _safetyService.confirmSafety();
              setState(() {
                _showSafetyDialog = false;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showSafetyCheckDialog() {
    setState(() {
      _showSafetyDialog = true;
    });

    int countdown = 30;
    Timer? countdownTimer;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (countdown > 0) {
                countdown--;
                setDialogState(() {});
              } else {
                timer.cancel();
                if (mounted && _showSafetyDialog) {
                  Navigator.pop(context);
                  _triggerEmergency();
                }
              }
            });

            return CupertinoAlertDialog(
              title: const Text('🚨 Safety Check'),
              content: Text('Are you safe? Please confirm within $countdown seconds.'),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('I Need Help'),
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.pop(context);
                    _triggerEmergency();
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('I Am Safe'),
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.pop(context);
                    _safetyService.confirmSafety();
                    setState(() {
                      _showSafetyDialog = false;
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerEmergency() {
    _safetyService.sendEmergencyAlert();
    _showEmergencyAlert();
  }

  void _showEmergencyAlert() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🚨 Emergency Alert Sent'),
        content: const Text('Your live location has been sent to your emergency contact. Help is on the way.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _endTrip() async {
    _trackingTimer?.cancel();
    _positionSubscription?.cancel();
    _safetyService.stopMonitoring();
    
    // Save REAL trip data with actual GPS tracking
    if (_startTime != null && _routePoints.isNotEmpty) {
      await _saveCompletedTrip();
    }
    
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _saveCompletedTrip() async {
    try {
      final tripDataService = TripDataService();
      await tripDataService.initialize();
      
      // Calculate real duration
      final endTime = DateTime.now();
      final actualDuration = endTime.difference(_startTime!);
      
      // Format duration
      String durationStr = '';
      if (actualDuration.inHours > 0) {
        durationStr = '${actualDuration.inHours}h ${actualDuration.inMinutes.remainder(60)}m';
      } else {
        durationStr = '${actualDuration.inMinutes}m';
      }
      
      // Determine mode from vehicle type or speed
      String mode = 'car';
      IconData icon = Icons.directions_car;
      Color color = Colors.blue;
      
      if (widget.trip?.vehicleType != null) {
        final vehicleType = widget.trip!.vehicleType!.toLowerCase();
        if (vehicleType.contains('motorcycle') || vehicleType.contains('bike')) {
          mode = 'motorcycle';
          icon = Icons.two_wheeler;
          color = Colors.orange;
        } else if (vehicleType.contains('bus')) {
          mode = 'bus';
          icon = Icons.directions_bus;
          color = Colors.green;
        } else if (vehicleType.contains('metro') || vehicleType.contains('train')) {
          mode = 'metro';
          icon = Icons.directions_transit;
          color = Colors.purple;
        } else if (vehicleType.contains('walk')) {
          mode = 'walking';
          icon = Icons.directions_walk;
          color = Colors.blue;
        }
      } else {
        // Infer from average speed
        final avgSpeed = _distance / (actualDuration.inHours + actualDuration.inMinutes / 60.0);
        if (avgSpeed < 5) {
          mode = 'walking';
          icon = Icons.directions_walk;
          color = Colors.blue;
        } else if (avgSpeed < 20) {
          mode = 'bike';
          icon = Icons.directions_bike;
          color = Colors.orange;
        }
      }
      
      // Create trip title from origin/destination
      String title = 'Trip';
      if (widget.trip != null) {
        final origin = widget.trip!.origin.split(',').first;
        final destination = widget.trip!.destination.split(',').first;
        title = '$origin → $destination';
      } else if (_routePoints.isNotEmpty) {
        title = 'Tracked Trip';
      }
      
      // Create REAL trip with actual GPS data
      final completedTrip = Trip(
        title: title,
        mode: mode,
        distance: _distance,
        duration: durationStr,
        time: _startTime!.toString().substring(11, 16),
        destination: widget.trip?.destination ?? 'Unknown',
        icon: icon,
        isCompleted: true,
        companions: widget.trip?.passengers.toString() ?? 'Solo',
        purpose: 'Travel',
        notes: 'Real-time GPS tracked trip. ${_routePoints.length} location points recorded.',
        color: color,
      );
      
      await tripDataService.addTrip(completedTrip);
      
      // Also save to database with route points
      final dbService = DatabaseService();
      if (dbService.database != null) {
        final tripId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Save trip to database
        await dbService.saveTrip({
          'id': tripId,
          'origin': widget.trip?.origin ?? 'Unknown',
          'destination': widget.trip?.destination ?? 'Unknown',
          'distance': _distance,
          'duration': actualDuration.inMinutes,
          'start_time': _startTime!.millisecondsSinceEpoch,
          'end_time': endTime.millisecondsSinceEpoch,
          'mode': mode,
          'safety_status': 'completed',
          'route_data': jsonEncode(_routePoints.map((p) => {
            'latitude': p.latitude,
            'longitude': p.longitude,
            'timestamp': p.timestamp.millisecondsSinceEpoch,
          }).toList()),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
        
        // Save all route points to database
        for (final point in _routePoints) {
          await dbService.saveLocation({
            'id': '${tripId}_${point.timestamp.millisecondsSinceEpoch}',
            'latitude': point.latitude,
            'longitude': point.longitude,
            'timestamp': point.timestamp.millisecondsSinceEpoch,
            'trip_id': tripId,
            'speed': point.speed,
            'accuracy': point.accuracy,
          });
        }
      }
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Trip Saved'),
            content: Text(
              'Your trip has been saved!\n\n'
              'Distance: ${_distance.toStringAsFixed(2)} km\n'
              'Duration: $durationStr\n'
              'Route points: ${_routePoints.length}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error saving trip: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save trip: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _positionSubscription?.cancel();
    _safetyService.stopMonitoring();
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _emotionService.stopMonitoring();
    _accidentService.stopMonitoring();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Live Trip Tracking'),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: CupertinoColors.lightBackgroundGray,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.location_solid, size: 60, color: CupertinoColors.systemBlue),
                    const SizedBox(height: 16),
                    Text(
                      _currentPosition != null
                          ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                          : 'Getting location...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CupertinoColors.secondaryLabel),
                    ),
                    if (widget.trip != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'From: ${widget.trip!.origin}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('To: ${widget.trip!.destination}'),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrackingStat(value: _speed, label: 'Speed'),
                      _buildTrackingStat(value: '${_distance.toStringAsFixed(1)} km', label: 'Distance'),
                      _buildTrackingStat(value: _formatDuration(_duration), label: 'Duration'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: _isTracking ? _togglePause : null,
                        child: Column(
                          children: [
                            Icon(
                              _isPaused ? CupertinoIcons.play : CupertinoIcons.pause,
                              size: 40,
                            ),
                            Text(_isPaused ? 'Resume' : 'Pause'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      CupertinoButton(
                        onPressed: _endTrip,
                        child: const Column(
                          children: [
                            Icon(
                              CupertinoIcons.stop_circle_fill,
                              size: 40,
                              color: CupertinoColors.systemRed,
                            ),
                            Text(
                              'End',
                              style: TextStyle(color: CupertinoColors.systemRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () {
                      if (_voiceService.isListening) {
                        _voiceService.stopListening();
                      } else {
                        _voiceService.startListening();
                      }
                    },
                    color: CupertinoColors.systemBlue,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _voiceService.isListening
                              ? CupertinoIcons.mic_fill
                              : CupertinoIcons.mic,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _voiceService.isListening ? 'Listening...' : 'Voice Commands',
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                      ],
                    ),
                  ),
                  if (_safetyService.isSafetyCheckActive)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed),
                          SizedBox(width: 8),
                          Text(
                            'Safety Check Active',
                            style: TextStyle(
                              color: CupertinoColors.systemRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStat({required String value, required String label}) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
      ],
    );
  }
}
