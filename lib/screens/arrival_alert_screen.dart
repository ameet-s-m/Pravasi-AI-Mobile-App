// lib/screens/arrival_alert_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/arrival_alert_service.dart';
import 'map_location_picker_screen.dart';

class ArrivalAlertScreen extends StatefulWidget {
  const ArrivalAlertScreen({super.key});

  @override
  State<ArrivalAlertScreen> createState() => _ArrivalAlertScreenState();
}

class _ArrivalAlertScreenState extends State<ArrivalAlertScreen> {
  final ArrivalAlertService _alertService = ArrivalAlertService();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isActive = false;
  Position? _selectedDestination;
  String _destinationName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final settings = await _alertService.getAlertSettings();
    setState(() {
      _isActive = settings['isActive'] as bool? ?? false;
      if (_isActive && settings['destinationLat'] != null) {
        _selectedDestination = Position(
          latitude: settings['destinationLat'] as double,
          longitude: settings['destinationLng'] as double,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _destinationName = settings['destinationName'] as String? ?? 'Destination';
        _destinationController.text = _destinationName;
        _distanceController.text = (settings['alertDistance'] as double? ?? 5.0).toString();
        _timeController.text = (settings['alertTime'] as int? ?? 10).toString();
      }
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _distanceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDestinationFromMap() async {
    final result = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => const MapLocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDestination = result;
        _isLoading = true;
      });

      try {
        // Get address from coordinates
        final placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          _destinationName = '${place.street}, ${place.locality}, ${place.administrativeArea}';
          _destinationController.text = _destinationName;
        } else {
          _destinationName = '${result.latitude}, ${result.longitude}';
          _destinationController.text = _destinationName;
        }
      } catch (e) {
        _destinationName = '${result.latitude}, ${result.longitude}';
        _destinationController.text = _destinationName;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        _destinationName = '${place.street}, ${place.locality}, ${place.administrativeArea}';
      } else {
        _destinationName = '${position.latitude}, ${position.longitude}';
      }

      setState(() {
        _selectedDestination = position;
        _destinationController.text = _destinationName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not get current location: $e'),
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

  Future<void> _saveAlert() async {
    if (_selectedDestination == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please select a destination'),
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

    final distance = double.tryParse(_distanceController.text) ?? 5.0;
    final time = int.tryParse(_timeController.text) ?? 10;

    if (distance <= 0 || time <= 0) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Distance and time must be greater than 0'),
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
      _isLoading = true;
    });

    await _alertService.setAlert(
      latitude: _selectedDestination!.latitude,
      longitude: _selectedDestination!.longitude,
      name: _destinationController.text.isNotEmpty 
          ? _destinationController.text 
          : _destinationName,
      alertDistanceKm: distance,
      alertTimeMinutes: time,
    );

    setState(() {
      _isActive = true;
      _isLoading = false;
    });

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Alert Set'),
          content: const Text('Arrival alert is now active. Your device will vibrate when you are near the destination.'),
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

  Future<void> _stopAlert() async {
    await _alertService.stopMonitoring();
    setState(() {
      _isActive = false;
      _selectedDestination = null;
      _destinationController.clear();
      _distanceController.text = '5.0';
      _timeController.text = '10';
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Arrival Alert'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.bell_fill,
                              color: CupertinoColors.systemBlue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Wake Me Up',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Perfect for travelers who sleep during journeys. Set your destination and alert distance/time. Your device will vibrate when you\'re near your destination.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Destination',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _destinationController,
                    placeholder: 'Select destination',
                    readOnly: true,
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: null,
                      child: const Icon(CupertinoIcons.map),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: CupertinoColors.systemBlue,
                          onPressed: _selectDestinationFromMap,
                          child: const Text('Select from Map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          color: CupertinoColors.systemGrey,
                          onPressed: _useCurrentLocation,
                          child: const Text('Use Current'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Alert Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Distance (km)'),
                            const SizedBox(height: 4),
                            CupertinoTextField(
                              controller: _distanceController,
                              placeholder: '5.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time (minutes)'),
                            const SizedBox(height: 4),
                            CupertinoTextField(
                              controller: _timeController,
                              placeholder: '10',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alert will trigger when you are within the set distance OR estimated arrival time',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isActive)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.check_mark_circled_solid,
                                color: CupertinoColors.systemGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alert Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Destination: $_destinationName',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
                          color: CupertinoColors.systemRed,
                          onPressed: _stopAlert,
                          child: const Text('Stop Alert'),
                        ),
                      ],
                    )
                  else
                    CupertinoButton.filled(
                      onPressed: _saveAlert,
                      child: const Text('Set Alert'),
                    ),
                ],
              ),
      ),
    );
  }
}

