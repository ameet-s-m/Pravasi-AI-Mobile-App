// lib/screens/plan_trip_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'active_trip_screen.dart';
import '../models/models.dart';
import '../services/ocr_service.dart';
import 'transport_booking_screen.dart';
import 'navigation_screen.dart';

// Conditional import for File
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class PlanTripScreen extends StatefulWidget {
  final PlannedTrip? editTrip;
  const PlanTripScreen({super.key, this.editTrip});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _timeController = TextEditingController();
  final OCRService _ocrService = OCRService();
  dynamic _uploadedImage;
  bool _isProcessingOCR = false;
  String? _selectedVehicle;
  String? _extractedPrice; // Price extracted from OCR
  List<RoutePoint>? _plannedRoute;
  Position? _currentOrigin;
  Position? _currentDestination;

  @override
  void initState() {
    super.initState();
    if (widget.editTrip != null) {
      _originController.text = widget.editTrip!.origin;
      _destinationController.text = widget.editTrip!.destination;
      _timeController.text = widget.editTrip!.time;
      _selectedVehicle = widget.editTrip!.vehicleType;
      _extractedPrice = widget.editTrip!.price;
      _plannedRoute = widget.editTrip!.plannedRoute;
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          if (!kIsWeb) {
            _uploadedImage = io.File(image.path);
          } else {
            _uploadedImage = image; // Use XFile on web
          }
          _isProcessingOCR = true;
        });

        // Process OCR
        final details = await _ocrService.extractTripDetails(_uploadedImage!);
        
        setState(() {
          _isProcessingOCR = false;
        });

        // Populate fields with OCR results
        bool hasOrigin = false;
        bool hasDestination = false;
        
        if (details['origin'] != null && details['origin']!.isNotEmpty) {
          _originController.text = details['origin']!;
          hasOrigin = true;
        }
        if (details['destination'] != null && details['destination']!.isNotEmpty) {
          _destinationController.text = details['destination']!;
          hasDestination = true;
        }
        if (details['time'] != null && details['time']!.isNotEmpty) {
          _timeController.text = details['time']!;
        }
        if (details['vehicle'] != null && details['vehicle']!.isNotEmpty) {
          // Map vehicle type to our format
          final vehicle = details['vehicle']!.toUpperCase();
          if (vehicle.contains('BUS')) {
            _selectedVehicle = 'BUS';
          } else if (vehicle.contains('TRAIN')) {
            _selectedVehicle = 'TRAIN';
          } else if (vehicle.contains('CAR') || vehicle.contains('TAXI') || vehicle.contains('CAB')) {
            _selectedVehicle = 'CAR';
          }
        }
        if (details['price'] != null && details['price']!.isNotEmpty) {
          // Store extracted price
          setState(() {
            _extractedPrice = details['price']!;
          });
        }

        // Show confirmation with better feedback
        if (mounted) {
          final missingFields = <String>[];
          if (!hasOrigin) missingFields.add('Origin');
          if (!hasDestination) missingFields.add('Destination');
          
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(hasOrigin && hasDestination ? '✅ Trip Details Extracted' : '⚠️ Partial Extraction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Origin: ${details['origin'] ?? 'Not found'}'),
                  const SizedBox(height: 4),
                  Text('Destination: ${details['destination'] ?? 'Not found'}'),
                  if (details['time'] != null) ...[
                    const SizedBox(height: 4),
                    Text('Time: ${details['time']}'),
                  ],
                  if (details['date'] != null) ...[
                    const SizedBox(height: 4),
                    Text('Date: ${details['date']}'),
                  ],
                  if (details['price'] != null && details['price']!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Price: ₹${details['price']}'),
                  ],
                  if (details['vehicle'] != null) ...[
                    const SizedBox(height: 4),
                    Text('Vehicle: ${details['vehicle']}'),
                  ],
                  if (missingFields.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Please manually enter: ${missingFields.join(", ")}',
                      style: const TextStyle(
                        color: CupertinoColors.systemOrange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
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
    } catch (e) {
      setState(() {
        _isProcessingOCR = false;
      });
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to process image: $e'),
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

  Future<void> _generateRoute() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please enter both origin and destination'),
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

    try {
      // Geocode origin and destination
      List<Location> originLocations = await locationFromAddress(_originController.text);
      List<Location> destLocations = await locationFromAddress(_destinationController.text);

      if (originLocations.isEmpty || destLocations.isEmpty) {
        throw Exception('Could not find locations');
      }

      // Generate route points (simplified - in production, use Google Directions API)
      List<RoutePoint> routePoints = [];
      final origin = originLocations.first;
      final dest = destLocations.first;
      
      setState(() {
        _currentOrigin = Position(
          latitude: origin.latitude,
          longitude: origin.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _currentDestination = Position(
          latitude: dest.latitude,
          longitude: dest.longitude,
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

      // Create intermediate points for route
      int steps = 10;
      for (int i = 0; i <= steps; i++) {
        double lat = origin.latitude + (dest.latitude - origin.latitude) * (i / steps);
        double lng = origin.longitude + (dest.longitude - origin.longitude) * (i / steps);
        routePoints.add(RoutePoint(latitude: lat, longitude: lng));
      }

      setState(() {
        _plannedRoute = routePoints;
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Route Generated'),
            content: const Text('Route has been planned successfully'),
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
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to generate route: $e'),
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

  void _startTracking() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please enter both origin and destination before starting tracking.'),
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

    // Always generate route before tracking to ensure we have valid coordinates
    _generateRoute().then((_) {
      if (_plannedRoute != null && _plannedRoute!.isNotEmpty && mounted) {
        _navigateToTrackingWithRoute();
      } else if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Route Generation Failed'),
            content: const Text('Could not generate route. Please check your origin and destination.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    });
  }

  void _navigateToTrackingWithRoute() {
    // Navigate to new real-time active trip tracking screen
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => ActiveTripScreen(
          tripTitle: '${_originController.text} → ${_destinationController.text}',
          destination: _destinationController.text,
        ),
      ),
    ).then((completedTrip) {
      // Trip completed, return to previous screen
      if (completedTrip != null && mounted) {
        Navigator.pop(context, completedTrip);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.editTrip == null ? 'Plan a Trip' : 'Edit Trip'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  CupertinoFormSection.insetGrouped(
                    header: const Text('UPLOAD TRIP DETAILS (OCR)'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.camera),
                        title: const Text('Upload Trip Image'),
                        subtitle: _uploadedImage != null
                            ? const Text('Image uploaded')
                            : const Text('Upload ticket/receipt with trip details'),
                        trailing: _isProcessingOCR
                            ? const CupertinoActivityIndicator()
                            : const CupertinoListTileChevron(),
                        onTap: _pickImage,
                      ),
                      if (_uploadedImage != null)
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_uploadedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('TRIP DETAILS'),
                    children: [
                      CupertinoTextFormFieldRow(
                        prefix: const Text('Origin'),
                        placeholder: 'e.g., Thiruvananthapuram',
                        controller: _originController,
                      ),
                      CupertinoTextFormFieldRow(
                        prefix: const Text('Destination'),
                        placeholder: 'e.g., Aluva Metro Station',
                        controller: _destinationController,
                      ),
                      CupertinoTextFormFieldRow(
                        prefix: const Text('Time'),
                        placeholder: 'e.g., 10:00 AM',
                        controller: _timeController,
                      ),
                    ],
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('TRANSPORT OPTIONS'),
                    children: [
                      _buildTransportOption(
                        icon: CupertinoIcons.bus,
                        name: 'Bus',
                        price: _extractedPrice != null && _selectedVehicle == 'BUS' 
                            ? '₹$_extractedPrice' 
                            : '₹350',
                        duration: '6h 30m',
                        value: 'BUS',
                      ),
                      _buildTransportOption(
                        icon: CupertinoIcons.train_style_one,
                        name: 'Train',
                        price: _extractedPrice != null && _selectedVehicle == 'TRAIN' 
                            ? '₹$_extractedPrice' 
                            : '₹500',
                        duration: '5h 15m',
                        value: 'TRAIN',
                      ),
                      _buildTransportOption(
                        icon: CupertinoIcons.car_detailed,
                        name: 'Car/Taxi',
                        price: _extractedPrice != null && _selectedVehicle == 'CAR' 
                            ? '₹$_extractedPrice' 
                            : '₹2,500',
                        duration: '4h 45m',
                        value: 'CAR',
                      ),
                    ],
                  ),
                  if (_plannedRoute != null)
                    CupertinoFormSection.insetGrouped(
                      header: const Text('ROUTE STATUS'),
                      children: [
                        const CupertinoListTile(
                          leading: Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemGreen),
                          title: Text('Route Planned'),
                          subtitle: Text('Safety monitoring will be active'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_plannedRoute == null)
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: _generateRoute,
                        child: const Text('Generate Route'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: CupertinoColors.systemBlue,
                          onPressed: () async {
                            if (_originController.text.isNotEmpty && 
                                _destinationController.text.isNotEmpty) {
                              if (_currentOrigin == null || _currentDestination == null) {
                                await _generateRoute();
                              }
                              if (_currentOrigin != null && _currentDestination != null) {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => TransportBookingScreen(
                                      origin: _currentOrigin,
                                      destination: _currentDestination,
                                      extractedPrice: _extractedPrice,
                                      vehicleType: _selectedVehicle,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Book Transport'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton(
                          color: CupertinoColors.systemGreen,
                          onPressed: () async {
                            if (_plannedRoute == null || _plannedRoute!.isEmpty) {
                              await _generateRoute();
                            }
                            if (_plannedRoute != null && _plannedRoute!.isNotEmpty) {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => NavigationScreen(
                                    origin: _currentOrigin,
                                    destination: _currentDestination,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Navigate'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _startTracking,
                      child: const Text('Start Tracking with Safety'),
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

  Widget _buildTransportOption({
    required IconData icon,
    required String name,
    required String price,
    required String duration,
    required String value,
  }) {
    final isSelected = _selectedVehicle == value;
    return CupertinoListTile(
      leading: Icon(icon),
      title: Text(name),
      subtitle: Text(duration),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.systemGreen)),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemBlue),
          ],
        ],
      ),
      onTap: () {
        setState(() {
          _selectedVehicle = value;
        });
      },
    );
  }
}
