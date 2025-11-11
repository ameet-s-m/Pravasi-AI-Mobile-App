// lib/screens/safe_zones_screen.dart
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/safe_zone_monitoring_service.dart';
import 'map_location_picker_screen.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key});

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  final SafeZoneMonitoringService _monitoringService = SafeZoneMonitoringService();
  List<UserSafeZone> _safeZones = [];
  bool _isLoading = true;
  bool _isMonitoring = false;
  bool _autoSOSEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _monitoringService.loadSafeZones();
    await _monitoringService.loadSettings();
    
    _monitoringService.onLeftSafeZone = (zone, position) {
      if (mounted) {
        _showLeftZoneAlert(zone, position);
      }
    };
    
    _monitoringService.onEnteredSafeZone = (zone, position) {
      if (mounted) {
        _showEnteredZoneAlert(zone);
      }
    };

    setState(() {
      _safeZones = _monitoringService.safeZones;
      _isMonitoring = _monitoringService.isMonitoring;
      _autoSOSEnabled = _monitoringService.autoSOSEnabled;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Safe Zones'),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildMonitoringControls(),
                const SizedBox(height: 16),
                if (_safeZones.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.location_slash,
                            size: 48,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No safe zones set',
                            style: TextStyle(color: CupertinoColors.secondaryLabel),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add multiple safe zones (Home, Office, etc.)\nEach can have its own radius.\nYou\'ll get alerts when you leave any zone.',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.info,
                              size: 20,
                              color: CupertinoColors.systemBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Monitoring ${_safeZones.length} safe zone${_safeZones.length > 1 ? 's' : ''}. You\'re safe if you\'re in ANY of them.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._safeZones.map((zone) => _buildSafeZoneCard(zone)),
                    ],
                  ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: _addSafeZone,
                  child: const Text('Add Safe Zone'),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Safe Zones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _safeZones.isEmpty
                ? 'Set multiple safe zones (Home, Office, etc.) with different radii. Get alerts when you leave any of them. Enable auto-SOS to automatically trigger emergency alerts.'
                : 'You have ${_safeZones.length} safe zone${_safeZones.length > 1 ? 's' : ''} set. You\'ll get alerts when you leave any of them. Enable auto-SOS for automatic emergency alerts.',
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringControls() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monitor Safe Zones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CupertinoSwitch(
                value: _isMonitoring,
                onChanged: (value) {
                  setState(() {
                    _isMonitoring = value;
                  });
                  if (value) {
                    _monitoringService.startMonitoring();
                  } else {
                    _monitoringService.stopMonitoring();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-SOS on Exit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Automatically trigger SOS when leaving safe zone',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _autoSOSEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoSOSEnabled = value;
                  });
                  _monitoringService.updateSettings(autoSOS: value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeZoneCard(UserSafeZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  zone.type == 'road' 
                      ? CupertinoIcons.map_fill 
                      : CupertinoIcons.shield_fill,
                  color: zone.type == 'road' 
                      ? CupertinoColors.systemOrange 
                      : CupertinoColors.systemGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.type == 'road' ? 'Road' : 'Place',
                          style: TextStyle(
                            fontSize: 11,
                            color: zone.type == 'road' 
                                ? CupertinoColors.systemOrange 
                                : CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          zone.radius < 1000
                              ? 'Radius: ${zone.radius.toInt()} m'
                              : 'Radius: ${(zone.radius / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _deleteSafeZone(zone),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _navigateToZone(zone),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.location, size: 16),
                SizedBox(width: 4),
                Text('View on Map'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToZone(UserSafeZone zone) async {
    final url = 'https://www.google.com/maps?q=${zone.latitude},${zone.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Could not open maps app'),
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

  Future<void> _deleteSafeZone(UserSafeZone zone) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Safe Zone'),
        content: Text('Are you sure you want to delete "${zone.name}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _monitoringService.removeSafeZone(zone);
      setState(() {
        _safeZones = _monitoringService.safeZones;
      });
    }
  }

  void _showLeftZoneAlert(UserSafeZone zone, Position position) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('⚠️ Left Safe Zone'),
        content: Text('You have left your safe zone "${zone.name}".\n\n'
            'Location will be shared with your emergency contacts.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              _monitoringService.acknowledgeAlert();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEnteredZoneAlert(UserSafeZone zone) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('✅ Entered Safe Zone'),
        content: Text('You are now in your safe zone "${zone.name}".'),
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

  void _addSafeZone() async {
    // Show options for adding safe zone
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Safe Zone'),
        message: const Text('Select how you want to add a safe zone'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addSafeZoneFromMap();
            },
            child: const Text('Select from Map'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addSafeZoneFromCurrentLocation();
            },
            child: const Text('Use Current Location'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSafeZoneFromMap() async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select Safe Zone Location',
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      _showAddSafeZoneForm(selectedPosition);
    }
  }

  Future<void> _addSafeZoneFromCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _showAddSafeZoneForm(position);
      }
    } catch (e) {
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

  List<LatLng> _generateCirclePoints(LatLng center, double radiusInMeters) {
    // Convert meters to degrees (approximate)
    // 1 degree latitude ≈ 111,000 meters
    final radiusInDegrees = radiusInMeters / 111000.0;
    const int points = 64; // Number of points to approximate circle
    
    final pointsList = <LatLng>[];
    for (int i = 0; i < points; i++) {
      final angle = (i * 360.0 / points) * (math.pi / 180.0);
      final lat = center.latitude + radiusInDegrees * math.cos(angle);
      final lng = center.longitude + radiusInDegrees * math.sin(angle) / math.cos(center.latitude * (math.pi / 180.0));
      pointsList.add(LatLng(lat, lng));
    }
    return pointsList;
  }

  void _showAddSafeZoneForm(Position position) {
    final nameController = TextEditingController();
    double radius = 500.0; // Default 500 meters
    String selectedType = 'place'; // 'place' or 'road'
    final MapController mapController = MapController();

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Add Safe Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Zone Name (e.g., Home, Office)',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                // Map preview
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
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(position.latitude, position.longitude),
                      initialZoom: 14,
                      minZoom: 5,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.prototype',
                        maxZoom: 19,
                      ),
                      // Draw circle using polygon approximation
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _generateCirclePoints(
                              LatLng(position.latitude, position.longitude),
                              radius,
                            ),
                            color: (selectedType == 'road' 
                                ? CupertinoColors.systemOrange 
                                : CupertinoColors.systemGreen).withOpacity(0.2),
                            borderColor: selectedType == 'road' 
                                ? CupertinoColors.systemOrange 
                                : CupertinoColors.systemGreen,
                            borderStrokeWidth: 2,
                            isFilled: true,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(position.latitude, position.longitude),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedType == 'road'
                                    ? CupertinoColors.systemOrange
                                    : CupertinoColors.systemGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CupertinoColors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                selectedType == 'road'
                                    ? CupertinoIcons.map_fill
                                    : CupertinoIcons.shield_fill,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zone Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: selectedType == 'place' 
                            ? CupertinoColors.systemBlue 
                            : CupertinoColors.systemGrey5,
                        onPressed: () {
                          setState(() {
                            selectedType = 'place';
                          });
                          // Refresh map to show updated marker
                          mapController.move(LatLng(position.latitude, position.longitude), mapController.camera.zoom);
                        },
                        child: const Text('Place'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: selectedType == 'road' 
                            ? CupertinoColors.systemBlue 
                            : CupertinoColors.systemGrey5,
                        onPressed: () {
                          setState(() {
                            selectedType = 'road';
                          });
                          // Refresh map to show updated marker
                          mapController.move(LatLng(position.latitude, position.longitude), mapController.camera.zoom);
                        },
                        child: const Text('Road'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Safe Zone Radius',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        radius < 1000 
                            ? '${radius.toInt()} m'
                            : '${(radius / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: CupertinoSlider(
                        value: radius,
                        min: 100, // Minimum 100 meters
                        max: 5000,
                        divisions: 49, // 100m increments
                        onChanged: (value) {
                          setState(() {
                            radius = value;
                            // Update map zoom to show the circle better
                            final zoom = value < 500 ? 15.0 : value < 1000 ? 14.0 : value < 2000 ? 13.0 : 12.0;
                            mapController.move(LatLng(position.latitude, position.longitude), zoom);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  radius < 1000
                      ? 'You will get alerts when you leave this ${radius.toInt()} meter radius'
                      : 'You will get alerts when you leave this ${(radius / 1000).toStringAsFixed(1)} km radius',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final zone = UserSafeZone(
                    name: nameController.text,
                    latitude: position.latitude,
                    longitude: position.longitude,
                    radius: radius,
                    type: selectedType,
                  );
                  _monitoringService.addSafeZone(zone);
                  Navigator.pop(context);
                  setState(() {
                    _safeZones = _monitoringService.safeZones;
                  });
                  
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Success'),
                        content: Text('Safe zone "${nameController.text}" added!\n\n'
                            'Enable monitoring to get alerts when you leave it.'),
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
              },
            ),
          ],
        ),
      ),
    );
  }
}

