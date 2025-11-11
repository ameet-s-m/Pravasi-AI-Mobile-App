// lib/screens/incident_report_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../services/community_safety_service.dart' show CommunitySafetyService, IncidentReport;

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final CommunitySafetyService _communityService = CommunitySafetyService();
  final _descriptionController = TextEditingController();
  String _selectedType = 'harassment';
  Position? _currentPosition;
  bool _isSubmitting = false;

  final List<Map<String, String>> _incidentTypes = [
    {'value': 'harassment', 'label': 'Harassment'},
    {'value': 'theft', 'label': 'Theft'},
    {'value': 'assault', 'label': 'Assault'},
    {'value': 'suspicious_activity', 'label': 'Suspicious Activity'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please provide a description of the incident'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Location Error'),
          content: const Text('Could not get your current location'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final incident = IncidentReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      type: _selectedType,
      description: _descriptionController.text,
    );

    try {
      await _communityService.reportIncident(incident);

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        // Show success notification dialog
        await showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.systemGreen,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text('Report Submitted'),
              ],
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '✅ Your incident report has been successfully submitted.\n\n'
                'Nearby community members have been notified to help keep everyone safe.',
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        
        // Clear the form after successful submission
        _descriptionController.clear();
        
        // Navigate back after dialog is dismissed
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        // Show error notification
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: CupertinoColors.systemRed,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text('Submission Failed'),
              ],
            ),
            content: Text(
              '❌ Failed to submit your incident report.\n\n'
              'Error: ${e.toString()}\n\n'
              'Please try again.',
              textAlign: TextAlign.center,
            ),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Report Incident'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Help keep the community safe by reporting incidents',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoFormSection.insetGrouped(
              header: const Text('INCIDENT TYPE'),
              children: _incidentTypes.map((type) {
                return CupertinoListTile(
                  title: Text(type['label']!),
                  trailing: _selectedType == type['value']
                      ? const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.systemBlue,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedType = type['value']!;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CupertinoFormSection.insetGrouped(
              header: const Text('DESCRIPTION'),
              children: [
                CupertinoTextFormFieldRow(
                  placeholder: 'Describe what happened...',
                  controller: _descriptionController,
                  maxLines: 5,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.location_fill),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator()
                  : const Text('Submit Report'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info, color: CupertinoColors.systemBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your report will be shared with nearby community members to help keep everyone safe.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

