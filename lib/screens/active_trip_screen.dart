// lib/screens/active_trip_screen.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/active_trip_service.dart';
import '../models/models.dart';
import 'trip_details_screen.dart';

class ActiveTripScreen extends StatefulWidget {
  final String? tripTitle;
  final String? destination;
  
  const ActiveTripScreen({
    super.key,
    this.tripTitle,
    this.destination,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final ActiveTripService _tripService = ActiveTripService();
  final MapController _mapController = MapController();
  bool _isTracking = false;
  Position? _currentPosition;
  double _distance = 0.0;
  Duration _duration = Duration.zero;
  String _speed = '0 km/h';
  final List<LatLng> _routePoints = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      // Request location permissions first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Location Disabled'),
              content: const Text('Please enable location services to track your trip.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Permission Denied'),
                content: const Text('Location permission is required to track trips.'),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Permission Required'),
              content: const Text('Please enable location permissions in app settings.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Set up callbacks
      _tripService.onLocationUpdate = (Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            if (_routePoints.isEmpty || 
                _routePoints.last.latitude != position.latitude ||
                _routePoints.last.longitude != position.longitude) {
              _routePoints.add(LatLng(position.latitude, position.longitude));
            }
          });
          _updateCameraPosition(position);
        }
      };

      _tripService.onTripUpdate = (double distance, Duration duration, String speed) {
        if (mounted) {
          setState(() {
            _distance = distance;
            _duration = duration;
            _speed = speed;
          });
        }
      };

      // Start trip tracking
      await _tripService.startTrip(
        tripId: 'active_${DateTime.now().millisecondsSinceEpoch}',
        title: widget.tripTitle,
        destination: widget.destination,
      );

      if (mounted) {
        setState(() {
          _isTracking = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to start tracking: $e'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    }
  }

  void _updateCameraPosition(Position position) {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    }
  }

  Future<void> _stopTrip() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('End Trip'),
        content: const Text('Are you sure you want to end this trip?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('End Trip'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final trip = await _tripService.stopTrip(
          title: widget.tripTitle,
          destination: widget.destination,
        );
        
        if (mounted) {
          Navigator.pop(context, trip);
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to stop trip: $e'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Active Trip'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _stopTrip,
          child: const Text('End', style: TextStyle(color: CupertinoColors.systemRed)),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            // Create trip object from current tracking data
            final trip = Trip(
              tripId: _tripService.currentPosition != null 
                  ? 'active_${DateTime.now().millisecondsSinceEpoch}'
                  : null,
              title: widget.tripTitle ?? 'Active Trip',
              mode: 'Car', // Default, can be updated
              distance: _distance,
              duration: _formatDuration(_duration),
              time: DateTime.now().toString().substring(11, 16),
              destination: widget.destination ?? 'In Progress',
              icon: CupertinoIcons.car_fill,
              isCompleted: false,
              companions: 'Solo',
              purpose: 'Travel',
              notes: 'Active trip tracking',
              color: CupertinoColors.systemBlue,
              routePoints: _routePoints.map((p) => RoutePoint(
                latitude: p.latitude,
                longitude: p.longitude,
              )).toList(),
              startLocation: _routePoints.isNotEmpty
                  ? RoutePoint(
                      latitude: _routePoints.first.latitude,
                      longitude: _routePoints.first.longitude,
                    )
                  : null,
              endLocation: _routePoints.isNotEmpty
                  ? RoutePoint(
                      latitude: _routePoints.last.latitude,
                      longitude: _routePoints.last.longitude,
                    )
                  : null,
              startTime: _tripService.currentPosition != null ? DateTime.now() : null,
            );
            
            await Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => TripDetailsScreen(
                  activeTrip: trip,
                  isActive: true,
                ),
              ),
            );
          },
          child: const Icon(CupertinoIcons.info),
        ),
      ),
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(8.5244, 76.9366),
              initialZoom: 15,
              minZoom: 5,
              maxZoom: 18,
              onMapReady: () {
                if (_currentPosition != null) {
                  _updateCameraPosition(_currentPosition!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.prototype',
                maxZoom: 19,
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: CupertinoColors.systemBlue,
                    ),
                  ],
                ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemBlue,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: CupertinoColors.white, width: 2),
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Stats overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Distance',
                          '${_distance.toStringAsFixed(2)} km',
                          CupertinoIcons.location,
                        ),
                        _buildStatItem(
                          'Duration',
                          _formatDuration(_duration),
                          CupertinoIcons.timer,
                        ),
                        _buildStatItem(
                          'Speed',
                          _speed,
                          CupertinoIcons.speedometer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tracking indicator
          if (_isTracking)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.circle_fill, size: 8, color: CupertinoColors.white),
                    SizedBox(width: 6),
                    Text(
                      'Tracking',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: CupertinoColors.systemBlue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}

