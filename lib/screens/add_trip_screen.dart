// lib/screens/add_trip_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../models/models.dart';
import '../services/trip_data_service.dart';
import '../services/carbon_footprint_service.dart';
import '../services/route_directions_service.dart';
import 'map_location_picker_screen.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _titleController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final _companionsController = TextEditingController();
  final _purposeController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  
  String? _selectedMode;
  bool _isLoading = false;
  bool _isCalculating = false;
  Position? _selectedOrigin;
  Position? _selectedDestination;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  final MapController _mapController = MapController();
  List<RoutePoint>? _routePoints; // Store actual route points
  
  final TripDataService _tripDataService = TripDataService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    _companionsController.dispose();
    _purposeController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_currentPosition != null) {
        // Set origin to current location by default
        if (_selectedOrigin == null) {
          _selectedOrigin = _currentPosition;
          await _updateOriginAddress(_currentPosition!);
        }
        // Set destination to current location if not set
        if (_selectedDestination == null) {
          _selectedDestination = _currentPosition;
          await _updateDestinationAddress(_currentPosition!);
        }
      }
    } catch (e) {
      // Error getting location - will show error message in UI
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _selectOriginFromMap() async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select Origin',
        ),
      ),
    );

    if (selectedPosition != null) {
      setState(() {
        _selectedOrigin = selectedPosition;
      });
      await _updateOriginAddress(selectedPosition);
      _updateMapView();
      await _calculateDistanceAndDuration();
    }
  }

  Future<void> _updateOriginAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        if (address.isNotEmpty) {
          _originController.text = address;
        } else {
          _originController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      }
    } catch (e) {
      _originController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  Future<void> _selectDestinationFromMap() async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select Destination',
        ),
      ),
    );

    if (selectedPosition != null) {
      setState(() {
        _selectedDestination = selectedPosition;
      });
      await _updateDestinationAddress(selectedPosition);
      _updateMapView();
      await _calculateDistanceAndDuration();
    }
  }

  Future<void> _updateDestinationAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        if (address.isNotEmpty) {
          _destinationController.text = address;
        } else {
          _destinationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      }
    } catch (e) {
      _destinationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  Future<void> _calculateDistanceAndDuration() async {
    if (_selectedOrigin == null || _selectedDestination == null || _selectedMode == null) {
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      // Try to use RouteDirectionsService for accurate route-based calculation
      final routeService = RouteDirectionsService();
      final routeDetails = await routeService.getRouteWithDetails(
        startLat: _selectedOrigin!.latitude,
        startLng: _selectedOrigin!.longitude,
        endLat: _selectedDestination!.latitude,
        endLng: _selectedDestination!.longitude,
      );

      double distanceKm = routeDetails['distance'] as double;
      Duration duration = routeDetails['duration'] as Duration;
      List<RoutePoint> routePoints = routeDetails['routePoints'] as List<RoutePoint>;

      // If route service didn't return valid data, use straight-line distance
      if (distanceKm == 0.0 || routePoints.isEmpty) {
        distanceKm = Geolocator.distanceBetween(
          _selectedOrigin!.latitude,
          _selectedOrigin!.longitude,
          _selectedDestination!.latitude,
          _selectedDestination!.longitude,
        ) / 1000.0; // Convert meters to km

        // Calculate estimated duration based on transport mode
        duration = _estimateDuration(distanceKm, _selectedMode!);
        
        // Create simple route points
        routePoints = [
          RoutePoint(latitude: _selectedOrigin!.latitude, longitude: _selectedOrigin!.longitude),
          RoutePoint(latitude: _selectedDestination!.latitude, longitude: _selectedDestination!.longitude),
        ];
      } else {
        // Adjust duration based on transport mode (OSRM gives driving estimates)
        duration = _adjustDurationForMode(duration, _selectedMode!);
      }

      // Update distance and duration fields, and store route points
      setState(() {
        _distanceController.text = distanceKm.toStringAsFixed(2);
        _durationController.text = _formatDuration(duration);
        _routePoints = routePoints;
      });
      
      // Update map view to show route
      _updateMapView();
    } catch (e) {
      // Fallback to straight-line distance calculation
      try {
        final distanceMeters = Geolocator.distanceBetween(
          _selectedOrigin!.latitude,
          _selectedOrigin!.longitude,
          _selectedDestination!.latitude,
          _selectedDestination!.longitude,
        );
        final distanceKm = distanceMeters / 1000.0;
        final duration = _estimateDuration(distanceKm, _selectedMode!);

        // Create simple route points for fallback
        final fallbackRoutePoints = [
          RoutePoint(latitude: _selectedOrigin!.latitude, longitude: _selectedOrigin!.longitude),
          RoutePoint(latitude: _selectedDestination!.latitude, longitude: _selectedDestination!.longitude),
        ];

        setState(() {
          _distanceController.text = distanceKm.toStringAsFixed(2);
          _durationController.text = _formatDuration(duration);
          _routePoints = fallbackRoutePoints;
        });
        
        // Update map view
        _updateMapView();
      } catch (e) {
        // Error calculating - leave fields empty
      }
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Duration _estimateDuration(double distanceKm, String mode) {
    // Average speeds in km/h for different transport modes
    double averageSpeedKmh;
    switch (mode) {
      case 'Car':
      case 'Taxi':
        averageSpeedKmh = 50.0; // City driving
        break;
      case 'Bus':
        averageSpeedKmh = 30.0; // City bus
        break;
      case 'Train':
        averageSpeedKmh = 80.0; // Average train speed
        break;
      case 'Auto':
        averageSpeedKmh = 25.0; // Auto-rickshaw
        break;
      case 'Flight':
        averageSpeedKmh = 800.0; // Average flight speed
        break;
      case 'Motorcycle':
        averageSpeedKmh = 40.0; // Motorcycle
        break;
      default:
        averageSpeedKmh = 50.0;
    }

    // Add buffer time for stops, traffic, etc.
    final hours = distanceKm / averageSpeedKmh;
    final totalMinutes = (hours * 60).round();
    
    // Add buffer: 10% for short trips, 5% for long trips
    final bufferMinutes = distanceKm < 50 ? (totalMinutes * 0.1).round() : (totalMinutes * 0.05).round();
    
    return Duration(minutes: totalMinutes + bufferMinutes);
  }

  Duration _adjustDurationForMode(Duration baseDuration, String mode) {
    // OSRM gives driving estimates, adjust for other modes
    final baseMinutes = baseDuration.inMinutes;
    double multiplier = 1.0;

    switch (mode) {
      case 'Bus':
        multiplier = 1.5; // Buses are slower
        break;
      case 'Train':
        multiplier = 0.6; // Trains are faster
        break;
      case 'Auto':
        multiplier = 1.8; // Auto-rickshaws are slower
        break;
      case 'Flight':
        multiplier = 0.1; // Flights are much faster
        break;
      case 'Motorcycle':
        multiplier = 1.2; // Slightly slower than car
        break;
      default:
        multiplier = 1.0; // Car/Taxi same as driving
    }

    return Duration(minutes: (baseMinutes * multiplier).round());
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  LatLng _getMapCenter() {
    if (_selectedOrigin != null && _selectedDestination != null) {
      // Center between origin and destination
      return LatLng(
        (_selectedOrigin!.latitude + _selectedDestination!.latitude) / 2,
        (_selectedOrigin!.longitude + _selectedDestination!.longitude) / 2,
      );
    } else if (_selectedOrigin != null) {
      return LatLng(_selectedOrigin!.latitude, _selectedOrigin!.longitude);
    } else if (_selectedDestination != null) {
      return LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude);
    } else if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    return const LatLng(28.6139, 77.2090); // Default to Delhi
  }

  double _getMapZoom() {
    if (_selectedOrigin != null && _selectedDestination != null) {
      // Calculate zoom based on distance
      final distance = Geolocator.distanceBetween(
        _selectedOrigin!.latitude,
        _selectedOrigin!.longitude,
        _selectedDestination!.latitude,
        _selectedDestination!.longitude,
      );
      if (distance > 100000) return 8.0; // > 100km
      if (distance > 50000) return 9.0; // > 50km
      if (distance > 10000) return 11.0; // > 10km
      return 13.0; // < 10km
    }
    return 13.0;
  }

  void _updateMapView() {
    if (_selectedOrigin != null && _selectedDestination != null) {
      final center = _getMapCenter();
      final zoom = _getMapZoom();
      _mapController.move(center, zoom);
    } else if (_selectedOrigin != null) {
      _mapController.move(
        LatLng(_selectedOrigin!.latitude, _selectedOrigin!.longitude),
        15.0,
      );
    } else if (_selectedDestination != null) {
      _mapController.move(
        LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
        15.0,
      );
    }
  }

  Future<void> _saveTrip() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a trip title');
      return;
    }

    if (_selectedOrigin == null) {
      _showError('Please select an origin location');
      return;
    }

    if (_selectedDestination == null) {
      _showError('Please select a destination location');
      return;
    }
    
    if (_selectedMode == null) {
      _showError('Please select a transport mode');
      return;
    }
    
    // Calculate distance and duration if not already calculated
    if (_distanceController.text.isEmpty || _durationController.text.isEmpty) {
      await _calculateDistanceAndDuration();
    }
    
    final distance = double.tryParse(_distanceController.text);
    if (distance == null || distance <= 0) {
      _showError('Unable to calculate distance. Please try selecting locations again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _tripDataService.initialize();
      
      // Get mode icon and color
      final modeData = _getModeData(_selectedMode!);
      
      final newTrip = Trip(
        title: _titleController.text.trim(),
        mode: _selectedMode!,
        distance: distance,
        duration: _durationController.text.trim().isEmpty 
            ? 'N/A' 
            : _durationController.text.trim(),
        time: DateTime.now().toString().substring(11, 16),
        destination: _destinationController.text.trim().isEmpty
            ? 'Unknown'
            : _destinationController.text.trim(),
        startLocation: _selectedOrigin != null
            ? RoutePoint(
                latitude: _selectedOrigin!.latitude,
                longitude: _selectedOrigin!.longitude,
              )
            : null,
        endLocation: _selectedDestination != null
            ? RoutePoint(
                latitude: _selectedDestination!.latitude,
                longitude: _selectedDestination!.longitude,
              )
            : null,
        routePoints: _routePoints,
        icon: modeData['icon'] as IconData,
        isCompleted: true,
        companions: _companionsController.text.trim().isEmpty
            ? 'Solo'
            : _companionsController.text.trim(),
        purpose: _purposeController.text.trim().isEmpty
            ? 'Travel'
            : _purposeController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? 'Manually added trip'
            : _notesController.text.trim(),
        color: modeData['color'] as Color,
        tripId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _tripDataService.addTrip(newTrip);
      
      if (mounted) {
        Navigator.pop(context, newTrip);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error saving trip: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getModeData(String mode) {
    final modeMap = {
      'Car': {
        'icon': CupertinoIcons.car_fill,
        'color': Colors.blue,
      },
      'Bus': {
        'icon': CupertinoIcons.bus,
        'color': Colors.green,
      },
      'Train': {
        'icon': CupertinoIcons.train_style_one,
        'color': Colors.orange,
      },
      'Taxi': {
        'icon': CupertinoIcons.car,
        'color': Colors.yellow.shade700,
      },
      'Auto': {
        'icon': CupertinoIcons.car_detailed,
        'color': Colors.red,
      },
      'Flight': {
        'icon': CupertinoIcons.airplane,
        'color': Colors.purple,
      },
      'Motorcycle': {
        'icon': CupertinoIcons.car_detailed,
        'color': Colors.teal,
      },
    };
    
    return modeMap[mode] ?? {
      'icon': CupertinoIcons.location,
      'color': Colors.grey,
    };
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add Trip'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: 'Trip Title *',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Origin *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _originController,
                    placeholder: 'Origin address',
                    padding: const EdgeInsets.all(12),
                    readOnly: true,
                    onTap: _selectOriginFromMap,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Destination *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _destinationController,
                    placeholder: 'Destination address',
                    padding: const EdgeInsets.all(12),
                    readOnly: true,
                    onTap: _selectDestinationFromMap,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.separator,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isLoadingLocation
                        ? const Center(child: CupertinoActivityIndicator())
                        : _currentPosition == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.location_slash,
                                      size: 32,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Unable to load map',
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CupertinoButton(
                                      onPressed: _getCurrentLocation,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _getMapCenter(),
                                      initialZoom: _getMapZoom(),
                                      minZoom: 5,
                                      maxZoom: 18,
                                      onTap: (tapPosition, point) {
                                        // If origin is not set or both are set, set destination
                                        // Otherwise, set origin
                                        if (_selectedOrigin == null) {
                                          setState(() {
                                            _selectedOrigin = Position(
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
                                            );
                                          });
                                          _updateOriginAddress(_selectedOrigin!);
                                          _updateMapView();
                                          _calculateDistanceAndDuration();
                                        } else {
                                          setState(() {
                                            _selectedDestination = Position(
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
                                            );
                                          });
                                          _updateDestinationAddress(_selectedDestination!);
                                          _updateMapView();
                                          _calculateDistanceAndDuration();
                                        }
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.prototype',
                                        maxZoom: 19,
                                      ),
                                      if (_routePoints != null && _routePoints!.isNotEmpty)
                                        PolylineLayer(
                                          polylines: [
                                            Polyline(
                                              points: _routePoints!.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                                              strokeWidth: 4,
                                              color: _selectedMode != null 
                                                  ? _getModeData(_selectedMode!)['color'] as Color
                                                  : CupertinoColors.systemBlue,
                                            ),
                                          ],
                                        )
                                      else if (_selectedOrigin != null && _selectedDestination != null)
                                        PolylineLayer(
                                          polylines: [
                                            Polyline(
                                              points: [
                                                LatLng(_selectedOrigin!.latitude, _selectedOrigin!.longitude),
                                                LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
                                              ],
                                              strokeWidth: 3,
                                              color: CupertinoColors.systemBlue.withValues(alpha: 0.6),
                                            ),
                                          ],
                                        ),
                                      if (_selectedOrigin != null)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: LatLng(
                                                _selectedOrigin!.latitude,
                                                _selectedOrigin!.longitude,
                                              ),
                                              width: 40,
                                              height: 40,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: CupertinoColors.systemBlue,
                                                  shape: BoxShape.circle,
                                                  border: Border.fromBorderSide(
                                                    BorderSide(
                                                      color: CupertinoColors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  CupertinoIcons.location_solid,
                                                  color: CupertinoColors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_selectedDestination != null)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: LatLng(
                                                _selectedDestination!.latitude,
                                                _selectedDestination!.longitude,
                                              ),
                                              width: 40,
                                              height: 40,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: CupertinoColors.systemGreen,
                                                  shape: BoxShape.circle,
                                                  border: Border.fromBorderSide(
                                                    BorderSide(
                                                      color: CupertinoColors.white,
                                                      width: 2,
                                                    ),
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
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.all(8),
                                      color: CupertinoColors.white.withOpacity(0.9),
                                      onPressed: _selectDestinationFromMap,
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.map, size: 16),
                                          SizedBox(width: 4),
                                          Text('Full Map'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Distance (km) *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                              controller: _distanceController,
                              placeholder: 'Auto-calculated',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              padding: const EdgeInsets.all(12),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duration *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                              controller: _durationController,
                              placeholder: 'Auto-calculated',
                              padding: const EdgeInsets.all(12),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isCalculating)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const CupertinoActivityIndicator(radius: 10),
                          const SizedBox(width: 8),
                          Text(
                            'Calculating distance and time...',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transport Mode *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...CarbonFootprintService.emissionFactors.keys
                      .where((mode) => mode != 'Walking' && mode != 'Bicycle')
                      .map((mode) => CupertinoListTile(
                            title: Text(mode),
                            trailing: _selectedMode == mode
                                ? const Icon(CupertinoIcons.check_mark)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedMode = mode;
                              });
                              // Calculate distance and duration when mode is selected
                              _calculateDistanceAndDuration();
                            },
                          )),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _companionsController,
                    placeholder: 'Companions',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _purposeController,
                    placeholder: 'Purpose',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _notesController,
                    placeholder: 'Notes',
                    padding: const EdgeInsets.all(12),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  CupertinoButton.filled(
                    onPressed: _saveTrip,
                    child: const Text('Add Trip'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '* Required fields',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

