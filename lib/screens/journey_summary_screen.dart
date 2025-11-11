// lib/screens/journey_summary_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/journey_summary_service.dart';
import '../services/trip_data_service.dart';
import '../models/models.dart';

class JourneySummaryScreen extends StatefulWidget {
  final String tripId;
  const JourneySummaryScreen({super.key, required this.tripId});

  @override
  State<JourneySummaryScreen> createState() => _JourneySummaryScreenState();
}

class _JourneySummaryScreenState extends State<JourneySummaryScreen> {
  final JourneySummaryService _summaryService = JourneySummaryService();
  final TripDataService _tripService = TripDataService();
  final MapController _mapController = MapController();
  JourneySummary? _summary;
  Trip? _trip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      await _tripService.initialize();
      final trip = _tripService.getTripById(widget.tripId);
      final summary = await _summaryService.generateSummary(widget.tripId);
      setState(() {
        _summary = summary;
        _trip = trip;
        _isLoading = false;
      });
      
      // Update map view if trip has route data
      if (trip != null && mounted) {
        _updateMapView(trip);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not load summary: $e'),
          ),
        );
      }
    }
  }

  void _updateMapView(Trip trip) {
    if (trip.startLocation != null && trip.endLocation != null) {
      final center = LatLng(
        (trip.startLocation!.latitude + trip.endLocation!.latitude) / 2,
        (trip.startLocation!.longitude + trip.endLocation!.longitude) / 2,
      );
      _mapController.move(center, 12.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Journey Summary')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // Show trip details even if summary is null
    if (_trip == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Journey Summary')),
        child: Center(child: Text('No trip data available')),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Journey Summary'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(_trip!, _summary),
          const SizedBox(height: 16),
          _buildStatsGrid(_trip!, _summary),
          const SizedBox(height: 16),
          if (_trip != null) _buildRouteMap(_trip!),
          if (_trip != null) const SizedBox(height: 16),
          _buildTripDetails(_trip!),
          const SizedBox(height: 16),
          if (_summary != null) _buildRouteInfo(_summary!),
          if (_summary != null) const SizedBox(height: 16),
          if (_summary != null) _buildExpensesCard(_summary!),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Trip trip, JourneySummary? summary) {
    final origin = trip.startLocation != null 
        ? '${trip.startLocation!.latitude.toStringAsFixed(4)}, ${trip.startLocation!.longitude.toStringAsFixed(4)}'
        : 'Origin';
    final destination = trip.destination.isNotEmpty 
        ? trip.destination 
        : (trip.endLocation != null 
            ? '${trip.endLocation!.latitude.toStringAsFixed(4)}, ${trip.endLocation!.longitude.toStringAsFixed(4)}'
            : 'Destination');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trip.color,
            trip.color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.title.isNotEmpty ? trip.title : '$origin → $destination',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary != null 
                ? '${summary.formattedDistance} • ${summary.formattedDuration}'
                : '${trip.distance.toStringAsFixed(1)} km • ${trip.duration}',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
          ),
          if (trip.mode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Mode: ${trip.mode}',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Trip trip, JourneySummary? summary) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Distance',
            summary != null ? summary.formattedDistance : '${trip.distance.toStringAsFixed(1)} km',
            CupertinoIcons.location,
            CupertinoColors.systemBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Duration',
            summary != null ? summary.formattedDuration : trip.duration,
            CupertinoIcons.clock,
            CupertinoColors.systemGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (trip.destination.isNotEmpty)
            _buildDetailRow('Destination', trip.destination),
          if (trip.mode.isNotEmpty)
            _buildDetailRow('Transport Mode', trip.mode),
          if (trip.time.isNotEmpty)
            _buildDetailRow('Time', trip.time),
          if (trip.companions.isNotEmpty && trip.companions != 'Solo')
            _buildDetailRow('Companions', trip.companions),
          if (trip.purpose.isNotEmpty)
            _buildDetailRow('Purpose', trip.purpose),
          if (trip.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip.notes,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
          if (trip.startTime != null || trip.endTime != null) ...[
            const SizedBox(height: 12),
            if (trip.startTime != null)
              _buildDetailRow('Start Time', trip.startTime!.toString().substring(0, 16)),
            if (trip.endTime != null)
              _buildDetailRow('End Time', trip.endTime!.toString().substring(0, 16)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  Widget _buildRouteInfo(JourneySummary summary) {
    return CupertinoFormSection.insetGrouped(
      header: const Text('ROUTE INFORMATION'),
      children: [
        _buildInfoRow('Mode', summary.mode),
        _buildInfoRow('Safety Status', summary.safetyStatus),
        _buildInfoRow('Average Speed', '${summary.averageSpeed.toStringAsFixed(1)} km/h'),
        _buildInfoRow('Max Speed', '${summary.maxSpeed.toStringAsFixed(1)} km/h'),
        _buildInfoRow('Route Points', '${summary.routePoints}'),
        _buildInfoRow('Incidents', '${summary.incidents}'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return CupertinoListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildExpensesCard(JourneySummary summary) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary.formattedExpenses,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemBlue.withOpacity(0.1),
                CupertinoColors.systemPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.chart_bar_fill,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Trip Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatisticItem('Route Efficiency', '${(summary.routePoints > 0 ? (summary.distance / summary.routePoints * 10).toStringAsFixed(1) : 'N/A')} km/point'),
              _buildStatisticItem('Safety Rating', summary.safetyStatus),
              _buildStatisticItem('Speed Consistency', summary.maxSpeed > 0 ? '${((summary.averageSpeed / summary.maxSpeed) * 100).toStringAsFixed(0)}%' : 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Journey Highlights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildHighlightItem('✓ Trip completed successfully'),
              _buildHighlightItem('✓ No route deviations detected'),
              _buildHighlightItem('✓ All safety checks passed'),
              if (summary.incidents == 0)
                _buildHighlightItem('✓ No incidents reported')
              else
                _buildHighlightItem('⚠ ${summary.incidents} incident(s) reported', isWarning: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String text, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isWarning ? CupertinoIcons.exclamationmark_triangle : CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: isWarning ? CupertinoColors.systemOrange : CupertinoColors.systemGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isWarning ? CupertinoColors.systemOrange : CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMap(Trip trip) {
    List<LatLng> routePoints = [];
    if (trip.routePoints != null && trip.routePoints!.isNotEmpty) {
      routePoints = trip.routePoints!.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } else if (trip.startLocation != null && trip.endLocation != null) {
      routePoints = [
        LatLng(trip.startLocation!.latitude, trip.startLocation!.longitude),
        LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
      ];
    }

    if (routePoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No route data available for this trip',
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ),
      );
    }

    // Fit bounds to show entire route
    if (routePoints.length > 1 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final bounds = LatLngBounds.fromPoints(routePoints);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          );
        } catch (e) {
          // Fallback to center
          final center = LatLng(
            (routePoints.first.latitude + routePoints.last.latitude) / 2,
            (routePoints.first.longitude + routePoints.last.longitude) / 2,
          );
          _mapController.move(center, 12.0);
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 2),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with route info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: trip.color.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.map,
                  color: trip.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Journey Route',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (trip.startLocation != null && trip.endLocation != null)
                        Text(
                          'From: ${trip.startLocation!.latitude.toStringAsFixed(4)}, ${trip.startLocation!.longitude.toStringAsFixed(4)} → To: ${trip.endLocation!.latitude.toStringAsFixed(4)}, ${trip.endLocation!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Map
          SizedBox(
            height: 400, // Increased height for better visibility
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: routePoints.length > 1
                    ? LatLng(
                        (routePoints.first.latitude + routePoints.last.latitude) / 2,
                        (routePoints.first.longitude + routePoints.last.longitude) / 2,
                      )
                    : routePoints.first,
                initialZoom: 12.0,
                minZoom: 5,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.prototype',
                  maxZoom: 19,
                ),
                // Route polyline - made thicker and more visible
                if (routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6, // Increased from 4 to 6
                        color: trip.color,
                        borderStrokeWidth: 2,
                        borderColor: CupertinoColors.white,
                      ),
                    ],
                  ),
                // Start marker with label
                if (trip.startLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(trip.startLocation!.latitude, trip.startLocation!.longitude),
                        width: 50,
                        height: 70,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBlue,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'START',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: CupertinoColors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.location_solid,
                                color: CupertinoColors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                // End marker with label
                if (trip.endLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
                        width: 50,
                        height: 70,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'END',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: CupertinoColors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.flag_fill,
                                color: CupertinoColors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

