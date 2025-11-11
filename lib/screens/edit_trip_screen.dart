// lib/screens/edit_trip_screen.dart
import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import '../services/trip_data_service.dart';
import '../services/carbon_footprint_service.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;
  final int tripIndex;
  
  const EditTripScreen({
    super.key,
    required this.trip,
    required this.tripIndex,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final _companionsController = TextEditingController();
  final _purposeController = TextEditingController();
  
  String? _selectedMode;
  double? _distance;
  String? _duration;
  bool _isLoading = false;
  
  final TripDataService _tripDataService = TripDataService();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.trip.title;
    _destinationController.text = widget.trip.destination;
    _notesController.text = widget.trip.notes;
    _companionsController.text = widget.trip.companions;
    _purposeController.text = widget.trip.purpose;
    _selectedMode = widget.trip.mode;
    _distance = widget.trip.distance;
    _duration = widget.trip.duration;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    _companionsController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _saveTrip() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a trip title');
      return;
    }
    
    if (_selectedMode == null) {
      _showError('Please select a transport mode');
      return;
    }
    
    if (_distance == null || _distance! <= 0) {
      _showError('Please enter a valid distance');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _tripDataService.initialize();
      
      final updatedTrip = Trip(
        title: _titleController.text.trim(),
        mode: _selectedMode!,
        distance: _distance!,
        duration: _duration ?? widget.trip.duration,
        time: widget.trip.time,
        destination: _destinationController.text.trim(),
        icon: widget.trip.icon,
        isCompleted: widget.trip.isCompleted,
        companions: _companionsController.text.trim(),
        purpose: _purposeController.text.trim(),
        notes: _notesController.text.trim(),
        color: widget.trip.color,
        routePoints: widget.trip.routePoints,
        startLocation: widget.trip.startLocation,
        endLocation: widget.trip.endLocation,
        startTime: widget.trip.startTime,
        endTime: widget.trip.endTime,
        tripId: widget.trip.tripId,
      );

      await _tripDataService.updateTrip(widget.tripIndex, updatedTrip);
      
      if (mounted) {
        Navigator.pop(context, updatedTrip);
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
        middle: Text('Edit Trip'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: 'Trip Title',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _destinationController,
                    placeholder: 'Destination',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: TextEditingController(
                      text: _distance?.toStringAsFixed(2) ?? '',
                    ),
                    placeholder: 'Distance (km)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    padding: const EdgeInsets.all(12),
                    onChanged: (value) {
                      _distance = double.tryParse(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: TextEditingController(text: _duration ?? ''),
                    placeholder: 'Duration (e.g., 1h 30m)',
                    padding: const EdgeInsets.all(12),
                    onChanged: (value) {
                      _duration = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transport Mode',
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
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
      ),
    );
  }
}

