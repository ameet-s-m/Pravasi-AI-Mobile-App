// lib/screens/navigation_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/navigation_service.dart';

class NavigationScreen extends StatefulWidget {
  final Position? origin;
  final Position? destination;
  final String? destinationAddress;
  const NavigationScreen({
    super.key,
    this.origin,
    this.destination,
    this.destinationAddress,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationService _navService = NavigationService();
  final MapController _mapController = MapController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  
  NavigationRoute? _currentRoute;
  bool _isLoading = false;
  bool _isNavigating = false;
  Position? _currentPosition;
  Position? _originPosition;
  Position? _destinationPosition;
  String _selectedMode = 'driving';
  int _currentInstructionIndex = 0;
  List<LatLng> _routePoints = [];

  final List<Map<String, String>> _travelModes = [
    {'value': 'driving', 'label': '🚗 Driving', 'icon': 'car'},
    {'value': 'walking', 'label': '🚶 Walking', 'icon': 'person'},
    {'value': 'transit', 'label': '🚌 Transit', 'icon': 'bus'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      _currentPosition = widget.origin ?? await Geolocator.getCurrentPosition();
      _originPosition = _currentPosition;
      
      // Get address for current location
      if (_originPosition != null) {
        final address = await _navService.getAddressFromLocation(_originPosition!);
        _originController.text = address;
      }
      
      if (widget.destination != null) {
        _destinationPosition = widget.destination;
        await _calculateRoute();
      } else if (widget.destinationAddress != null) {
        _destinationController.text = widget.destinationAddress!;
        await _searchDestination();
      }
    } catch (e) {
      print('Error initializing navigation: $e');
    }
  }

  Future<void> _searchOrigin() async {
    if (_originController.text.isEmpty) {
      // Use current location
      try {
        _originPosition = await Geolocator.getCurrentPosition();
        final address = await _navService.getAddressFromLocation(_originPosition!);
        setState(() {
          _originController.text = address;
        });
        if (_destinationPosition != null) {
          await _calculateRoute();
        }
      } catch (e) {
        _showError('Could not get current location: $e');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _originPosition = await _navService.getLocationFromAddress(_originController.text);
      if (_destinationPosition != null) {
        await _calculateRoute();
      } else {
        _updateMapView();
      }
    } catch (e) {
      _showError('Could not find origin: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchDestination() async {
    if (_destinationController.text.isEmpty) {
      _showError('Please enter a destination');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _destinationPosition = await _navService.getLocationFromAddress(_destinationController.text);
      if (_originPosition != null) {
        await _calculateRoute();
      } else {
        _updateMapView();
      }
    } catch (e) {
      _showError('Could not find destination: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_originPosition == null || _destinationPosition == null) {
      _showError('Please set both origin and destination');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final route = await _navService.getRoute(
        origin: _originPosition!,
        destination: _destinationPosition!,
        mode: _selectedMode,
      );

      // Convert waypoints to LatLng for map
      _routePoints = [
        LatLng(_originPosition!.latitude, _originPosition!.longitude),
        ...route.waypoints.map((wp) => LatLng(wp.latitude, wp.longitude)),
        LatLng(_destinationPosition!.latitude, _destinationPosition!.longitude),
      ];

      setState(() {
        _currentRoute = route;
        _isLoading = false;
      });

      _updateMapView();
    } catch (e) {
      _showError('Could not calculate route: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMapView() {
    if (_originPosition != null && _destinationPosition != null) {
      // Center map to show both origin and destination
      final centerLat = (_originPosition!.latitude + _destinationPosition!.latitude) / 2;
      final centerLng = (_originPosition!.longitude + _destinationPosition!.longitude) / 2;
      
      _mapController.move(
        LatLng(centerLat, centerLng),
        _calculateZoomLevel(),
      );
    } else if (_originPosition != null) {
      _mapController.move(
        LatLng(_originPosition!.latitude, _originPosition!.longitude),
        14.0,
      );
    } else if (_destinationPosition != null) {
      _mapController.move(
        LatLng(_destinationPosition!.latitude, _destinationPosition!.longitude),
        14.0,
      );
    }
  }

  double _calculateZoomLevel() {
    if (_originPosition == null || _destinationPosition == null) return 14.0;
    
    final distance = Geolocator.distanceBetween(
      _originPosition!.latitude,
      _originPosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );
    
    // Calculate appropriate zoom level based on distance
    if (distance < 1000) return 15.0;
    if (distance < 5000) return 13.0;
    if (distance < 20000) return 11.0;
    return 10.0;
  }

  void _showError(String message) {
    if (mounted) {
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
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _currentInstructionIndex = 0;
    });
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });
  }

  void _nextInstruction() {
    if (_currentRoute != null && 
        _currentInstructionIndex < _currentRoute!.instructions.length - 1) {
      setState(() {
        _currentInstructionIndex++;
      });
    }
  }

  void _previousInstruction() {
    if (_currentInstructionIndex > 0) {
      setState(() {
        _currentInstructionIndex--;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_originPosition == null || _destinationPosition == null) {
      _showError('Please set both origin and destination');
      return;
    }
    
    try {
      // Encode coordinates properly
      final originLat = _originPosition!.latitude.toStringAsFixed(6);
      final originLng = _originPosition!.longitude.toStringAsFixed(6);
      final destLat = _destinationPosition!.latitude.toStringAsFixed(6);
      final destLng = _destinationPosition!.longitude.toStringAsFixed(6);
      
      // Map travel mode to Google Maps format
      String travelMode = 'd';
      switch (_selectedMode) {
        case 'walking':
          travelMode = 'w';
          break;
        case 'transit':
          travelMode = 'r';
          break;
        default:
          travelMode = 'd';
      }
      
      // Try Google Maps app URL scheme first (comgooglemaps://)
      final appUrl = Uri.parse(
        'comgooglemaps://?saddr=$originLat,$originLng&daddr=$destLat,$destLng&directionsmode=$travelMode'
      );
      
      // Fallback to web URL
      final webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&'
        'origin=$originLat,$originLng&'
        'destination=$destLat,$destLng&'
        'travelmode=${_selectedMode}'
      );
      
      // Try to launch app first, then fallback to web
      try {
        if (await canLaunchUrl(appUrl)) {
          await launchUrl(appUrl, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          _showError('Could not open Google Maps. Please install Google Maps app.');
        }
      } catch (e) {
        // If app URL fails, try web URL
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          _showError('Could not open Google Maps.');
        }
      }
    } catch (e) {
      _showError('Error opening Google Maps: $e');
    }
  }

  Future<void> _useCurrentLocationAsOrigin() async {
    try {
      _originPosition = await Geolocator.getCurrentPosition();
      final address = await _navService.getAddressFromLocation(_originPosition!);
      setState(() {
        _originController.text = address;
      });
      if (_destinationPosition != null) {
        await _calculateRoute();
      } else {
        _updateMapView();
      }
    } catch (e) {
      _showError('Could not get current location: $e');
    }
  }

  Future<void> _useCurrentLocationAsDestination() async {
    try {
      _destinationPosition = await Geolocator.getCurrentPosition();
      final address = await _navService.getAddressFromLocation(_destinationPosition!);
      setState(() {
        _destinationController.text = address;
      });
      if (_originPosition != null) {
        await _calculateRoute();
      } else {
        _updateMapView();
      }
    } catch (e) {
      _showError('Could not get current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Navigation'),
        trailing: _currentRoute != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openInGoogleMaps,
                child: const Icon(CupertinoIcons.arrow_up_right_square),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Input Section
            Container(
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.systemBackground,
              child: Column(
                children: [
                  // Origin Input
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.circle_fill,
                          color: CupertinoColors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _originController,
                          placeholder: 'Origin (tap to use current location)',
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSubmitted: (_) => _searchOrigin(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: _useCurrentLocationAsOrigin,
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Destination Input
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.flag_fill,
                          color: CupertinoColors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _destinationController,
                          placeholder: 'Destination',
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSubmitted: (_) => _searchDestination(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: _useCurrentLocationAsDestination,
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Travel Mode Selector
                  Row(
                    children: _travelModes.map((mode) {
                      final isSelected = _selectedMode == mode['value'];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: isSelected
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.systemGrey6,
                            onPressed: () {
                              setState(() {
                                _selectedMode = mode['value']!;
                              });
                              if (_originPosition != null && _destinationPosition != null) {
                                _calculateRoute();
                              }
                            },
                            child: Text(
                              mode['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? CupertinoColors.white
                                    : CupertinoColors.label,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_currentRoute != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRouteInfo(
                            CupertinoIcons.clock,
                            _currentRoute!.formattedDuration,
                          ),
                          _buildRouteInfo(
                            CupertinoIcons.location,
                            '${_currentRoute!.distance.toStringAsFixed(1)} km',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Map Preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _originPosition != null
                                ? LatLng(_originPosition!.latitude, _originPosition!.longitude)
                                : const LatLng(0, 0),
                            initialZoom: 14.0,
                            minZoom: 5,
                            maxZoom: 18,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            // Map Tiles
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.prototype',
                              maxZoom: 19,
                            ),
                            // Route Polyline
                            if (_routePoints.length > 1)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    strokeWidth: 5,
                                    color: CupertinoColors.systemBlue,
                                    borderStrokeWidth: 2,
                                    borderColor: CupertinoColors.white,
                                  ),
                                ],
                              ),
                            // Origin Marker
                            if (_originPosition != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _originPosition!.latitude,
                                      _originPosition!.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: CupertinoColors.systemGreen,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(
                                          BorderSide(color: CupertinoColors.white, width: 3),
                                        ),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.circle_fill,
                                        color: CupertinoColors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            // Destination Marker
                            if (_destinationPosition != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _destinationPosition!.latitude,
                                      _destinationPosition!.longitude,
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: CupertinoColors.systemRed,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(
                                          BorderSide(color: CupertinoColors.white, width: 3),
                                        ),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.flag_fill,
                                        color: CupertinoColors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
            ),

            // Navigation Controls
            if (_currentRoute != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isNavigating) ...[
                      CupertinoButton.filled(
                        onPressed: _startNavigation,
                        child: const Text('Start Navigation'),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        onPressed: _openInGoogleMaps,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.arrow_up_right_square, size: 16),
                            SizedBox(width: 4),
                            Text('Open in Google Maps'),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Current Instruction
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _currentRoute!.instructions[_currentInstructionIndex],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_currentInstructionIndex + 1} of ${_currentRoute!.instructions.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              onPressed: _previousInstruction,
                              child: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemRed,
                              onPressed: _stopNavigation,
                              child: const Text('Stop'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              onPressed: _nextInstruction,
                              child: const Text('Next'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CupertinoColors.systemBlue),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

}

extension NavigationRouteExtension on NavigationRoute {
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

