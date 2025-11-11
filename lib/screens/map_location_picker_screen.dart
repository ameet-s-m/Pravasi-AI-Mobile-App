// lib/screens/map_location_picker_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapLocationPickerScreen extends StatefulWidget {
  final Function(Position selectedPosition, String? address)? onLocationSelected;
  final String? title;

  const MapLocationPickerScreen({
    super.key,
    this.onLocationSelected,
    this.title,
  });

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  Position? _selectedPosition;
  Position? _currentPosition;
  String? _selectedAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_currentPosition != null) {
        _selectedPosition = _currentPosition;
        await _getAddressFromPosition(_currentPosition!);
      }
    } catch (e) {
      // Error getting location - will show error message in UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getAddressFromPosition(Position position) async {
    try {
      // In production, use geocoding package
      _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = Position(
        latitude: position.latitude,
        longitude: position.longitude,
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
    _getAddressFromPosition(_selectedPosition!);
  }

  void _confirmSelection() {
    if (_selectedPosition != null) {
      widget.onLocationSelected?.call(_selectedPosition!, _selectedAddress);
      Navigator.pop(context, _selectedPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, show a simplified version with Google Maps link
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title ?? 'Select Location'),
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.map,
                        size: 80,
                        color: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Map Selection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please use the mobile app for map-based location selection',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: () async {
                          if (_currentPosition != null) {
                            final url = 'https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          }
                        },
                        child: const Text('Open in Google Maps'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title ?? 'Select Location'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedPosition != null ? _confirmSelection : null,
          child: const Text(
            'Confirm',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _currentPosition == null
              ? const Center(
                  child: Text('Unable to get current location'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          initialZoom: 15,
                          minZoom: 5,
                          maxZoom: 18,
                          onTap: _onMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.prototype',
                            maxZoom: 19,
                          ),
                          if (_selectedPosition != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _selectedPosition!.latitude,
                                    _selectedPosition!.longitude,
                                  ),
                                  width: 50,
                                  height: 50,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: CupertinoColors.systemBlue,
                                      shape: BoxShape.circle,
                                      border: Border.fromBorderSide(
                                        BorderSide(color: CupertinoColors.white, width: 3),
                                      ),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.location_fill,
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedAddress != null)
                            Text(
                              _selectedAddress!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 8),
                          CupertinoButton.filled(
                            onPressed: _confirmSelection,
                            child: const Text('Confirm Location'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

