// lib/screens/trips_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/trip_data_service.dart';
import '../models/models.dart';
import '../utils/string_extension.dart';
import 'journey_summary_screen.dart';
import 'expense_tracking_screen.dart';
import 'edit_trip_screen.dart';
import 'add_trip_screen.dart';
import '../services/carbon_footprint_service.dart';
import '../services/ai_copilot_service.dart';
import 'package:geolocator/geolocator.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final MapController _mapController = MapController();
  final TripDataService _tripDataService = TripDataService();
  final CarbonFootprintService _carbonService = CarbonFootprintService();
  final AICopilotService _aiService = AICopilotService();
  List<Trip> _trips = [];
  String? _smartSuggestion;
  bool _isLoadingSuggestion = false;
  
  // Sample coordinates for Kerala/Trivandrum area
  static const LatLng _center = LatLng(8.5244, 76.9366); // Trivandrum center

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadSmartSuggestions() async {
    if (_trips.isEmpty) return;
    
    setState(() {
      _isLoadingSuggestion = true;
    });
    
    try {
      await _aiService.loadApiKeyFromStorage();
      
      // Get current location
      Position? currentLocation;
      try {
        currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
      } catch (e) {
        // Location not critical
      }
      
      // Build trip history summary
      final recentTrips = _trips.take(5).map((t) => 
        '${t.mode} trip: ${t.title} to ${t.destination}'
      ).join(', ');
      
      final suggestion = await _aiService.askQuestion(
        'Based on my recent trips: $recentTrips. Suggest 3 smart trip recommendations for me. Include destinations, best time to visit, transport options, and approximate costs. Keep it concise in bullet points.',
        context: currentLocation != null 
          ? {'location': '${currentLocation.latitude}, ${currentLocation.longitude}'}
          : {},
      );
      
      if (mounted) {
        setState(() {
          _smartSuggestion = suggestion;
          _isLoadingSuggestion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestion = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      await _tripDataService.initialize();
      if (mounted) {
        setState(() {
          _trips = _tripDataService.getTrips();
        });
        // Fit bounds after loading trips
        if (_trips.isNotEmpty) {
          _fitBounds();
          // Load smart suggestions after trips are loaded
          _loadSmartSuggestions();
        }
      }
    } catch (e) {
      print('Error loading trips: $e');
      if (mounted) {
        setState(() {
          _trips = [];
        });
      }
    }
  }
  
  // Get real GPS route points from trip, or generate fallback
  List<LatLng> _getRoutePoints(Trip trip) {
    // Use real GPS coordinates if available
    if (trip.routePoints != null && trip.routePoints!.isNotEmpty) {
      return trip.routePoints!.map((p) => LatLng(p.latitude, p.longitude)).toList();
    }
    
    // If we have start and end locations but no route points, fetch route
    if (trip.startLocation != null && trip.endLocation != null) {
      // Return simple route for now - will be enhanced with async route fetching if needed
      return [
        LatLng(trip.startLocation!.latitude, trip.startLocation!.longitude),
        LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
      ];
    }
    
    // Fallback: generate route points if no GPS data (for old trips)
    final baseLat = trip.startLocation?.latitude ?? _center.latitude;
    final baseLng = trip.startLocation?.longitude ?? _center.longitude;
    
    if (trip.endLocation != null) {
      // Create a simple route from start to end
      return [
        LatLng(baseLat, baseLng),
        LatLng(
          (baseLat + trip.endLocation!.latitude) / 2,
          (baseLng + trip.endLocation!.longitude) / 2,
        ),
        LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
      ];
    }
    
    // Last resort: use center point
    return [LatLng(baseLat, baseLng)];
  }

  Widget _buildMapWidget() {
    if (_trips.isEmpty) {
      return Container(
        color: CupertinoColors.systemGrey6,
        child: const Center(
          child: Text(
            'No trips to display\nStart tracking to see your routes here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      );
    }
    
    // Build polylines and markers
    final polylines = _buildPolylines();
    final markers = _buildMarkers();
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 11.5,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.prototype',
          maxZoom: 19,
        ),
        // Polylines layer
        PolylineLayer(
          polylines: polylines,
        ),
        // Markers layer
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }
  
  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];
    
    if (_trips.isEmpty) {
      return polylines;
    }
    
    try {
      for (int i = 0; i < _trips.length; i++) {
        final trip = _trips[i];
        final points = _getRoutePoints(trip);
        
        // Validate points
        final validPoints = <LatLng>[];
        for (var point in points) {
          if (point.latitude.isFinite &&
              point.longitude.isFinite &&
              point.latitude >= -90 && point.latitude <= 90 &&
              point.longitude >= -180 && point.longitude <= 180) {
            validPoints.add(point);
          }
        }
        
        if (validPoints.isEmpty || validPoints.length < 2) {
          continue;
        }
        
        polylines.add(
          Polyline(
            points: validPoints,
            strokeWidth: 5,
            color: trip.color,
          ),
        );
      }
    } catch (e) {
      print('Error building polylines: $e');
    }
    
    return polylines;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    if (_trips.isEmpty) {
      return markers;
    }
    
    try {
      for (int i = 0; i < _trips.length; i++) {
        final trip = _trips[i];
        final points = _getRoutePoints(trip);
        
        if (points.isEmpty) continue;
        
        // Validate start point
        final startPoint = points.first;
        if (!startPoint.latitude.isFinite ||
            !startPoint.longitude.isFinite ||
            startPoint.latitude < -90 || startPoint.latitude > 90 ||
            startPoint.longitude < -180 || startPoint.longitude > 180) {
          continue;
        }
        
        // Add start marker
        markers.add(
          Marker(
            point: startPoint,
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: trip.color,
                shape: BoxShape.circle,
                border: Border.all(color: CupertinoColors.white, width: 2),
              ),
              child: Icon(
                trip.icon,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
          ),
        );
        
        // Add end marker if different from start
        if (points.length > 1) {
          final endPoint = points.last;
          if (endPoint.latitude.isFinite &&
              endPoint.longitude.isFinite &&
              endPoint.latitude >= -90 && endPoint.latitude <= 90 &&
              endPoint.longitude >= -180 && endPoint.longitude <= 180 &&
              (startPoint.latitude != endPoint.latitude || 
               startPoint.longitude != endPoint.longitude)) {
            markers.add(
              Marker(
                point: endPoint,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getEndMarkerColor(trip.mode),
                    shape: BoxShape.circle,
                    border: Border.all(color: CupertinoColors.white, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.flag_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error building markers: $e');
    }
    
    return markers;
  }

  Color _getEndMarkerColor(String mode) {
    switch (mode) {
      case 'Car': return CupertinoColors.systemBlue;
      case 'Bus': return CupertinoColors.systemGreen;
      case 'Train': return CupertinoColors.systemOrange;
      case 'Taxi': return CupertinoColors.systemYellow;
      case 'Auto': return CupertinoColors.systemRed;
      case 'Flight': return CupertinoColors.systemPurple;
      case 'Motorcycle': return CupertinoColors.systemTeal;
      default: return CupertinoColors.systemGrey;
    }
  }

  void _fitBounds() {
    if (_trips.isEmpty) return;
    
    try {
      final bounds = _calculateBounds();
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (e) {
      print('Error fitting bounds: $e');
    }
  }

  LatLngBounds _calculateBounds() {
    if (_trips.isEmpty) {
      return LatLngBounds(_center, _center);
    }
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final trip in _trips) {
      final points = _getRoutePoints(trip);
      for (final point in points) {
        if (point.latitude.isFinite && point.longitude.isFinite) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }
      }
    }
    
    // Fallback to center if no valid points
    if (!minLat.isFinite || !maxLat.isFinite) {
      return LatLngBounds(_center, _center);
    }
    
    return LatLngBounds(
      LatLng(minLat - 0.01, minLng - 0.01),
      LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int tripsToday = 0;
    double totalDistance = 0;
    double totalHours = 0;
    
    for (final trip in _trips) {
      if (trip.startTime != null) {
        final tripDate = DateTime(
          trip.startTime!.year,
          trip.startTime!.month,
          trip.startTime!.day,
        );
        
        if (tripDate.isAtSameMomentAs(today)) {
          tripsToday++;
        }
      }
      
      totalDistance += trip.distance;
      // Parse duration string (e.g., "1h 30m" or "90m")
      try {
        final durationParts = trip.duration.toLowerCase().split(' ');
        double hours = 0;
        for (var part in durationParts) {
          if (part.contains('h')) {
            hours += double.tryParse(part.replaceAll('h', '')) ?? 0;
          } else if (part.contains('m')) {
            hours += (double.tryParse(part.replaceAll('m', '')) ?? 0) / 60;
          }
        }
        totalHours += hours;
      } catch (e) {
        // If parsing fails, skip this trip's duration
      }
    }
    
    return {
      'tripsToday': tripsToday,
      'totalDistance': totalDistance,
      'totalHours': totalHours,
    };
  }

  Widget _buildTripStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).brightness == Brightness.light
            ? CupertinoColors.white
            : CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final tripModes = <String, Map<String, dynamic>>{};
    
    for (final trip in _trips) {
      tripModes[trip.mode] = {
        'count': (tripModes[trip.mode]?['count'] ?? 0) + 1,
        'icon': trip.icon,
      };
    }
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('My Trips'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const AddTripScreen(),
              ),
            ).then((_) => _loadTrips());
          },
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: _buildTripStat('${stats['tripsToday']}', 'Trips Today')),
                const SizedBox(width: 16),
                Expanded(child: _buildTripStat('${stats['totalDistance'].toStringAsFixed(0)}', 'km Traveled')),
                const SizedBox(width: 16),
                Expanded(child: _buildTripStat('${stats['totalHours'].toStringAsFixed(1)}', 'hrs Active')),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).brightness == Brightness.light
                    ? CupertinoColors.white
                    : CupertinoColors.secondarySystemGroupedBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Routes Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.separator,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _trips.isEmpty
                        ? Container(
                            color: CupertinoColors.systemGrey6,
                            child: const Center(
                              child: Text(
                                'No trips to display\nStart tracking to see your routes here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ),
                          )
                        : _buildMapWidget(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tripModes.entries.map((entry) {
              return _buildLegendItem(
                entry.value['icon'],
                '${entry.key.capitalize()} (${entry.value['count']})',
                _getModeColor(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Smart Trip Suggestions
          if (_trips.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.systemBlue,
                      CupertinoColors.systemPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Smart Trip Suggestions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingSuggestion)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          ),
                        ),
                      )
                    else if (_smartSuggestion != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _smartSuggestion!,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Tap to get AI-powered trip suggestions',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _loadSmartSuggestions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.refresh,
                              color: CupertinoColors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Refresh Suggestions',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (_trips.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.map,
                      size: 64,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No trips yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start a trip to see it here',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._trips.asMap().entries.map((entry) {
              final index = entry.key;
              final trip = entry.value;
              final carbonFootprint = _carbonService.calculateTripCarbon(trip);
              return _buildTripCard(trip, carbonFootprint, index);
            }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'Car': return CupertinoColors.systemBlue;
      case 'Bus': return CupertinoColors.systemGreen;
      case 'Train': return CupertinoColors.systemOrange;
      case 'Taxi': return CupertinoColors.systemYellow;
      case 'Auto': return CupertinoColors.systemRed;
      case 'Flight': return CupertinoColors.systemPurple;
      case 'Motorcycle': return CupertinoColors.systemTeal;
      default: return CupertinoColors.systemGrey;
    }
  }

  Widget _buildTripCard(Trip trip, double carbonFootprint, int tripIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => JourneySummaryScreen(tripId: trip.tripId ?? 'unknown'),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).brightness == Brightness.light
                ? CupertinoColors.white
                : CupertinoColors.secondarySystemGroupedBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: trip.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  trip.icon,
                  color: trip.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location,
                          size: 14,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.startLocation != null 
                                ? 'From: ${trip.startLocation!.latitude.toStringAsFixed(4)}, ${trip.startLocation!.longitude.toStringAsFixed(4)}'
                                : 'From: Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.flag,
                          size: 14,
                          color: CupertinoColors.systemGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'To: ${trip.destination}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${trip.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                        Text(
                          trip.duration,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        if (carbonFootprint > 0) ...[
                          const Text(' • ', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                          Text(
                            '${carbonFootprint.toStringAsFixed(1)} kg CO₂',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => EditTripScreen(trip: trip, tripIndex: tripIndex),
                        ),
                      ).then((_) => _loadTrips());
                    },
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 20,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => ExpenseTrackingScreen(tripId: trip.tripId),
                        ),
                      );
                    },
                    child: const Icon(
                      CupertinoIcons.money_dollar,
                      size: 20,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
