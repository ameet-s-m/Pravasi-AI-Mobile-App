// lib/screens/trip_details_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/active_trip_service.dart';
import '../services/trip_data_service.dart';
import '../services/carbon_footprint_service.dart';
import 'edit_trip_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip? activeTrip;
  final bool isActive;
  
  const TripDetailsScreen({
    super.key,
    this.activeTrip,
    this.isActive = false,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final ActiveTripService _activeTripService = ActiveTripService();
  final TripDataService _tripDataService = TripDataService();
  final CarbonFootprintService _carbonService = CarbonFootprintService();
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final trip = widget.activeTrip;
    if (trip == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Trip Details')),
        child: Center(child: Text('No trip data available')),
      );
    }

    final routePoints = trip.routePoints ?? [];
    final startPoint = trip.startLocation;
    final endPoint = trip.endLocation;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Trip Details'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Map
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: startPoint != null
                        ? LatLng(startPoint.latitude, startPoint.longitude)
                        : const LatLng(8.5244, 76.9366),
                    initialZoom: 13,
                    minZoom: 5,
                    maxZoom: 18,
                    onMapReady: () {
                      if (routePoints.isNotEmpty) {
                        _fitBounds();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.prototype',
                      maxZoom: 19,
                    ),
                    if (routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints
                                .map((p) => LatLng(p.latitude, p.longitude))
                                .toList(),
                            strokeWidth: 5,
                            color: trip.color,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _buildMarkers(trip, startPoint, endPoint),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Trip Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: trip.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(trip.icon, color: trip.color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.mode,
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Distance', '${trip.distance.toStringAsFixed(2)} km'),
                  _buildDetailRow('Duration', trip.duration),
                  _buildDetailRow('Time', trip.time),
                  _buildDetailRow('Destination', trip.destination),
                  if (trip.companions.isNotEmpty)
                    _buildDetailRow('Companions', trip.companions),
                  if (trip.purpose.isNotEmpty)
                    _buildDetailRow('Purpose', trip.purpose),
                  _buildDetailRow(
                    'Carbon Footprint',
                    _carbonService.formatCarbon(
                      _carbonService.calculateTripCarbon(trip),
                    ),
                  ),
                  if (trip.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.notes,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            if (widget.isActive) ...[
              CupertinoButton.filled(
                color: CupertinoColors.systemRed,
                onPressed: () async {
                  final confirmed = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Stop Trip'),
                      content: const Text('Are you sure you want to stop this trip?'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Stop'),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    try {
                      final completedTrip = await _activeTripService.stopTrip(
                        title: trip.title,
                        destination: trip.destination,
                      );
                      if (mounted) {
                        Navigator.pop(context, completedTrip);
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
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Stop Trip'),
              ),
              const SizedBox(height: 12),
            ],
            CupertinoButton.filled(
              onPressed: () async {
                final trips = _tripDataService.getTrips();
                final index = trips.indexWhere((t) => t.tripId == trip.tripId);
                if (index >= 0) {
                  final edited = await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => EditTripScreen(
                        trip: trip,
                        tripIndex: index,
                      ),
                    ),
                  );
                  if (edited != null && mounted) {
                    Navigator.pop(context, edited);
                  }
                }
              },
              child: const Text('Edit Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(Trip trip, RoutePoint? start, RoutePoint? end) {
    final markers = <Marker>[];
    
    if (start != null) {
      markers.add(Marker(
        point: LatLng(start.latitude, start.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: _getMarkerColor(trip.mode),
            shape: BoxShape.circle,
            border: Border.all(color: CupertinoColors.white, width: 2),
          ),
          child: Icon(
            trip.icon,
            color: CupertinoColors.white,
            size: 20,
          ),
        ),
      ));
    }
    
    if (end != null) {
      markers.add(Marker(
        point: LatLng(end.latitude, end.longitude),
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
      ));
    }
    
    return markers;
  }

  Color _getMarkerColor(String mode) {
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
    if (widget.activeTrip?.routePoints == null) return;
    
    final points = widget.activeTrip!.routePoints!;
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (var point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    final bounds = LatLngBounds(
      LatLng(minLat - 0.01, minLng - 0.01),
      LatLng(maxLat + 0.01, maxLng + 0.01),
    );
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }
}

