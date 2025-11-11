// lib/services/real_location_sharing_service.dart
// Real live location sharing via SMS, WhatsApp, Email
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class RealLocationSharingService {
  static final RealLocationSharingService _instance = RealLocationSharingService._internal();
  factory RealLocationSharingService() => _instance;
  RealLocationSharingService._internal();

  Timer? _sharingTimer;
  StreamSubscription<Position>? _positionSubscription;
  bool _isSharing = false;
  Position? _currentPosition;
  List<String> _recipients = [];

  /// Start continuous live location sharing
  Future<void> startSharing({
    required List<String> phoneNumbers,
    Duration interval = const Duration(minutes: 5),
  }) async {
    if (_isSharing) return;
    
    _isSharing = true;
    _recipients = phoneNumbers;

    // Get initial position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _shareLocationToAll();
    } catch (e) {
      print('Error getting initial position: $e');
    }

    // Start position stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
    });

    // Share location periodically
    _sharingTimer = Timer.periodic(interval, (timer) async {
      if (_isSharing && _currentPosition != null) {
        await _shareLocationToAll();
      }
    });
  }

  Future<void> _shareLocationToAll() async {
    if (_currentPosition == null || _recipients.isEmpty) return;

    for (final phoneNumber in _recipients) {
      await _shareLocationToContact(phoneNumber);
    }
  }

  /// Share location once to specific contacts
  Future<void> shareLocationOnce({
    required List<String> phoneNumbers,
    String? customMessage,
  }) async {
    if (_currentPosition == null) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        print('Error getting position: $e');
        return;
      }
    }

    for (final phoneNumber in phoneNumbers) {
      await _shareLocationToContact(phoneNumber, customMessage: customMessage);
    }
  }

  Future<void> _shareLocationToContact(String phoneNumber, {String? customMessage}) async {
    if (_currentPosition == null) return;

    try {
      String address = 'Unknown location';
      try {
        final placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      final mapUrl = 'https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final timestamp = DateTime.now().toString();
      
      final message = customMessage ?? 
          '📍 LIVE LOCATION from PRAVASI AI\n\n'
          'Location: $address\n'
          'Coordinates: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}\n'
          'Map: $mapUrl\n'
          'Time: $timestamp';

      // Send SMS
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }

      // Send WhatsApp
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      }
    } catch (e) {
      print('Error sharing location: $e');
    }
  }

  void stopSharing() {
    _isSharing = false;
    _sharingTimer?.cancel();
    _positionSubscription?.cancel();
    _recipients.clear();
  }

  bool get isSharing => _isSharing;
  Position? get currentPosition => _currentPosition;
}

