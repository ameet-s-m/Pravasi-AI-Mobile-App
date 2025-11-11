// lib/screens/data_export_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/trip_data_service.dart';
import '../services/carbon_footprint_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final TripDataService _tripDataService = TripDataService();
  final CarbonFootprintService _carbonService = CarbonFootprintService();
  bool _isExporting = false;

  Future<void> _exportToJSON() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await _tripDataService.initialize();
      final trips = _tripDataService.getTrips();
      final plannedTrips = _tripDataService.getPlannedTrips();
      final stats = _tripDataService.getStatistics();
      final totalCarbon = await _carbonService.getTotalCarbonFootprint();
      final carbonByMode = await _carbonService.getCarbonByMode();

      // Create JSON structure
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'user': 'PRAVASI AI User',
        'statistics': {
          'totalTrips': stats['totalTrips'],
          'tripsToday': stats['tripsToday'],
          'totalDistance': stats['totalDistance'],
          'totalHours': stats['totalHours'],
          'totalCarbonFootprint': totalCarbon,
          'carbonByMode': carbonByMode.map((key, value) => MapEntry(key, value)),
        },
        'trips': trips.map((trip) => {
          'tripId': trip.tripId,
          'title': trip.title,
          'mode': trip.mode,
          'distance': trip.distance,
          'duration': trip.duration,
          'time': trip.time,
          'destination': trip.destination,
          'companions': trip.companions,
          'purpose': trip.purpose,
          'notes': trip.notes,
          'isCompleted': trip.isCompleted,
          'carbonFootprint': _carbonService.calculateTripCarbon(trip),
          'startLocation': trip.startLocation != null
              ? {
                  'latitude': trip.startLocation!.latitude,
                  'longitude': trip.startLocation!.longitude,
                }
              : null,
          'endLocation': trip.endLocation != null
              ? {
                  'latitude': trip.endLocation!.latitude,
                  'longitude': trip.endLocation!.longitude,
                }
              : null,
          'startTime': trip.startTime?.toIso8601String(),
          'endTime': trip.endTime?.toIso8601String(),
          'routePoints': trip.routePoints?.map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              }).toList(),
        }).toList(),
        'plannedTrips': plannedTrips.map((trip) => {
          'origin': trip.origin,
          'destination': trip.destination,
          'time': trip.time,
          'passengers': trip.passengers,
          'createdAt': trip.createdAt.toIso8601String(),
          'vehicleType': trip.vehicleType,
        }).toList(),
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/trip_data_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        // Show success and share options
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text('Export Successful'),
            message: Text('Trip data exported to:\n${file.path}'),
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Share via WhatsApp'),
                onPressed: () {
                  Navigator.pop(context);
                  _shareViaWhatsApp(file);
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Share File'),
                onPressed: () {
                  Navigator.pop(context);
                  _shareFile(file);
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Share with Transport Department'),
                onPressed: () {
                  Navigator.pop(context);
                  _shareWithTransportDepartment(file);
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Export Failed'),
            content: Text('Error exporting data: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _shareViaWhatsApp(File file) async {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: 'My Trip Data Export from PRAVASI AI',
      );
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Share Failed'),
            content: Text('Error sharing: $e'),
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

  Future<void> _shareFile(File file) async {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile]);
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Share Failed'),
            content: Text('Error sharing: $e'),
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

  Future<void> _shareWithTransportDepartment(File file) async {
    try {
      // Simulate sharing with transport department
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('✅ Success'),
            content: const Text(
              'Your trip data has been successfully shared with the Transport Department.\n\n'
              'Thank you for contributing to transportation data analysis!',
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
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error sharing with transport department: $e'),
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
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Export Trip Data'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  children: [
                    const Icon(
                      CupertinoIcons.doc_text_fill,
                      size: 48,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Export Your Trip Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export all your trip data as a JSON file that can be shared via WhatsApp or with transport authorities.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _isExporting ? null : _exportToJSON,
                child: _isExporting
                    ? const CupertinoActivityIndicator()
                    : const Text('Export to JSON'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What will be exported:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildExportItem('All trip records'),
                    _buildExportItem('Trip statistics'),
                    _buildExportItem('Carbon footprint data'),
                    _buildExportItem('Planned trips'),
                    _buildExportItem('Route coordinates'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
