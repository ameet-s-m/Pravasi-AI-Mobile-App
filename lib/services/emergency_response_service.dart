// lib/services/emergency_response_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_sms/flutter_sms.dart'; // Using url_launcher instead
import 'package:url_launcher/url_launcher.dart';
import 'video_streaming_service.dart';
import 'accident_detection_service.dart';
import 'emotion_detection_service.dart';

class EmergencyResponseService {
  static final EmergencyResponseService _instance = EmergencyResponseService._internal();
  factory EmergencyResponseService() => _instance;
  EmergencyResponseService._internal();

  final VideoStreamingService _videoService = VideoStreamingService();
  final AccidentDetectionService _accidentService = AccidentDetectionService();
  final EmotionDetectionService _emotionService = EmotionDetectionService();

  Future<void> triggerEmergencyResponse({
    required Position location,
    required String emergencyType,
    bool startVideoStream = true,
  }) async {
    // 1. Start video streaming
    if (startVideoStream) {
      await _videoService.startStreaming();
      await _videoService.shareStreamWithContacts(await _getEmergencyContacts());
    }

    // 2. Call police
    await _callPolice(location, emergencyType);

    // 3. Notify family and friends
    await _notifyContacts(location, emergencyType);

    // 4. Send location to all contacts
    await _sendLocationToAll(location);

    // 5. Play SOS sound
    await _playSOSSound();
  }

  Future<void> _callPolice(Position location, String emergencyType) async {
    final policeNumber = '100'; // Indian emergency number
    final message = '🚨 EMERGENCY ALERT 🚨\n\n'
        'Type: $emergencyType\n'
        'Location: ${location.latitude}, ${location.longitude}\n'
        'Time: ${DateTime.now()}\n\n'
        'Please send help immediately!';
    
    try {
      // Call police
      final uri = Uri.parse('tel:$policeNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      
      // Also send SMS via url_launcher
      try {
        final smsUri = Uri.parse('sms:$policeNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        // SMS sending failed, continue with other emergency actions
      }
    } catch (e) {
      print('Error calling police: $e');
    }
  }

  Future<void> _notifyContacts(Position location, String emergencyType) async {
    final contacts = await _getEmergencyContacts();
    final message = '🚨 EMERGENCY ALERT 🚨\n\n'
        'I need immediate help!\n'
        'Type: $emergencyType\n'
        'Location: https://www.google.com/maps?q=${location.latitude},${location.longitude}\n'
        'Time: ${DateTime.now()}\n\n'
        'Live stream: [Stream URL]\n'
        'Please help!';

    for (var contact in contacts) {
      try {
        final smsUri = Uri.parse('sms:$contact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending SMS to $contact: $e');
      }
    }
  }

  Future<void> _sendLocationToAll(Position location) async {
    final contacts = await _getEmergencyContacts();
    final mapUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    
    for (var contact in contacts) {
      try {
        final uri = Uri.parse('sms:$contact?body=My location: $mapUrl');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (e) {
        print('Error sending location: $e');
      }
    }
  }

  Future<void> _playSOSSound() async {
    // Play loud SOS pattern
    print('Playing SOS sound pattern...');
    // In real app, use audio player
  }

  Future<List<String>> _getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList('emergency_contacts') ?? [];
    return contacts;
  }

  Future<void> handleEmotionBasedEmergency(Position location) async {
    await triggerEmergencyResponse(
      location: location,
      emergencyType: 'Emotional Distress Detected',
      startVideoStream: true,
    );
  }

  Future<void> handleAccidentEmergency(Position location) async {
    await triggerEmergencyResponse(
      location: location,
      emergencyType: 'Road Accident',
      startVideoStream: true,
    );
    
    // Also call ambulance
    await _accidentService.callAmbulanceWithAI(location);
  }
}

