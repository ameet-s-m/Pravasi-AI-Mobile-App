// lib/services/accident_detection_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:image/image.dart' as img; // Unused for now
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_voice_call_service.dart';
import 'dart:async';
import 'dart:typed_data';

// Conditional import for File
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class AccidentDetectionService {
  static final AccidentDetectionService _instance = AccidentDetectionService._internal();
  factory AccidentDetectionService() => _instance;
  AccidentDetectionService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _speedMonitor;
  
  double _lastSpeed = 0.0;
  DateTime? _lastSpeedUpdate;
  
  bool _isMonitoring = false;
  String? _geminiApiKey; // Set your Gemini API key
  
  Function(Position location)? onAccidentDetected;
  Function()? onAmbulanceCalled;

  Future<void> initializeGemini(String apiKey) async {
    _geminiApiKey = apiKey;
  }

  // Load API key from SharedPreferences on service initialization
  Future<void> loadApiKeyFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      _geminiApiKey = savedKey;
    }
  }

  // Detect accident from photo
  Future<bool> detectAccidentFromPhoto(dynamic imageFile) async {
    if (kIsWeb) {
      // On web, return false as this feature requires native file access
      return false;
    }
    
    // Real AI accident detection - requires API key
    if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-pro-vision',
          apiKey: _geminiApiKey!,
        );

        Uint8List imageBytes;
        if (imageFile is io.File) {
          imageBytes = await imageFile.readAsBytes();
        } else {
          return false;
        }
        final prompt = 'Analyze this image and determine if there is a road accident, '
            'injury, or medical emergency. Respond with only "YES" if there is an accident/emergency, '
            'or "NO" if there is not.';

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ])
        ];

        final response = await model.generateContent(content);
        final result = response.text?.toUpperCase().trim() ?? 'NO';
        
        return result.contains('YES');
      } catch (e) {
        print('Error analyzing image with AI: $e');
        // Return false on error - don't use mock
        return false;
      }
    }
    
    // No API key - cannot analyze image
    print('Gemini API key not set. Cannot analyze accident image.');
    return false;
  }

  // Detect motorcycle accident from sensors
  Future<void> startMotorcycleMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Monitor speed changes
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _checkForAccident(position);
    });

    // Monitor for sudden speed drops
    _speedMonitor = Timer.periodic(const Duration(seconds: 2), (timer) {
      _monitorSpeed();
    });
  }

  void _checkForAccident(Position position) {
    final speed = position.speed * 3.6; // Convert to km/h
    
    // Check for sudden speed drop (accident indicator)
    if (_lastSpeed > 30 && speed < 5) {
      final timeDiff = _lastSpeedUpdate != null 
          ? DateTime.now().difference(_lastSpeedUpdate!).inSeconds 
          : 0;
      
      if (timeDiff < 5) {
        // Sudden stop within 5 seconds - possible accident
        _detectAccident(position);
      }
    }
    
    _lastSpeed = speed;
    _lastSpeedUpdate = DateTime.now();
  }

  void _monitorSpeed() {
    // Additional monitoring logic
  }

  void _detectAccident(Position location) {
    onAccidentDetected?.call(location);
    _triggerEmergencyResponse(location);
  }

  Future<void> _triggerEmergencyResponse(Position location, [dynamic imageFile]) async {
    // Play SOS sound
    await _playSOSSound();
    
    // Call ambulance using Gemini AI (with image if available)
    await callAmbulanceWithAI(location, accidentImage: imageFile);
    
    // Notify emergency contacts
    await _notifyEmergencyContacts(location, imageFile);
  }

  Future<void> _playSOSSound() async {
    // Play loud SOS sound pattern
    try {
      // In real app, use actual audio file
      // await _audioPlayer.play(AssetSource('sos_sound.mp3'));
      print('Playing SOS sound...');
    } catch (e) {
      print('Error playing SOS sound: $e');
    }
  }

  Future<void> callAmbulanceWithAI(Position location, {dynamic accidentImage}) async {
    // Indian emergency numbers
    const ambulanceNumber = '108'; // National Emergency Number
    const policeNumber = '100';
    
    try {
      String locationDescription = 'Location: ${location.latitude}, ${location.longitude}';
      String imageDescription = '';
      
      // If image is provided, analyze it with AI to get description
      if (accidentImage != null && !kIsWeb && _geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
        try {
          final model = GenerativeModel(
            model: 'gemini-pro-vision',
            apiKey: _geminiApiKey!,
          );

          Uint8List imageBytes;
          if (accidentImage is io.File) {
            imageBytes = await accidentImage.readAsBytes();
          } else {
            return;
          }

          final prompt = 'Analyze this accident scene image and provide a brief description: '
              'What type of accident is it? How many vehicles/people are involved? '
              'What is the severity? Describe the scene in 2-3 sentences.';

          final content = [
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ])
          ];

          final response = await model.generateContent(content);
          imageDescription = response.text ?? '';
        } catch (e) {
          print('Error analyzing image for ambulance call: $e');
          imageDescription = 'Road accident detected from photo';
        }
      }

      // Generate call script with location and image description
      String callMessage = '';
      if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
        try {
          final model = GenerativeModel(
            model: 'gemini-pro',
            apiKey: _geminiApiKey!,
          );

          final prompt = 'Generate a concise emergency message for ambulance services. '
              'Include: $locationDescription. '
              '${imageDescription.isNotEmpty ? "Accident details: $imageDescription" : "Type: Road accident"}. '
              'Request immediate medical assistance. Keep it brief and clear (max 50 words).';

          final response = await model.generateContent([Content.text(prompt)]);
          callMessage = response.text ?? '';
        } catch (e) {
          print('Error generating call message: $e');
        }
      }

      // Default message if AI fails
      if (callMessage.isEmpty) {
        callMessage = '🚨 EMERGENCY - ROAD ACCIDENT 🚨\n\n'
            '$locationDescription\n'
            '${imageDescription.isNotEmpty ? imageDescription : "Road accident detected"}\n\n'
            'Please send ambulance immediately!';
      }

      // Call ambulance
      await _callAmbulance(ambulanceNumber, callMessage, location, accidentImage);
      
      // Also notify police
      await _callPolice(policeNumber, callMessage, location);
      
      onAmbulanceCalled?.call();
    } catch (e) {
      print('Error in ambulance call process: $e');
    }
  }

  Future<void> _callAmbulance(String number, String message, Position location, dynamic image) async {
    try {
      // Get ambulance settings
      final prefs = await SharedPreferences.getInstance();
      final ambulanceWhatsAppNumber = prefs.getString('ambulance_whatsapp_number') ?? '108';
      final ambulanceAutoCallEnabled = prefs.getBool('ambulance_auto_call_enabled') ?? false;
      
      // Create detailed message with location and image info
      final mapUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
      final detailedMessage = '$message\n\n'
          '📍 Exact Location:\n'
          'Latitude: ${location.latitude}\n'
          'Longitude: ${location.longitude}\n'
          'Google Maps: $mapUrl\n\n'
          '🕐 Time: ${DateTime.now().toString()}\n\n'
          '${image != null ? "📷 Accident photo analyzed by AI - details included above" : ""}';

      // If auto-call is enabled, use AI voice call service
      if (ambulanceAutoCallEnabled) {
        final aiCallService = AIVoiceCallService();
        await aiCallService.loadApiKeyFromStorage();
        
        // Get accident details from AI analysis if available
        String? accidentDetails;
        if (image != null && _geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
          try {
            final model = GenerativeModel(
              model: 'gemini-pro-vision',
              apiKey: _geminiApiKey!,
            );
            
            Uint8List imageBytes;
            if (image is io.File) {
              imageBytes = await image.readAsBytes();
            } else {
              imageBytes = Uint8List(0);
            }
            
            if (imageBytes.isNotEmpty) {
              final prompt = 'Analyze this accident scene and provide a brief description: '
                  'What type of accident? How many vehicles/people involved? Severity?';
              
              final content = [
                Content.multi([
                  TextPart(prompt),
                  DataPart('image/jpeg', imageBytes),
                ])
              ];
              
              final response = await model.generateContent(content);
              accidentDetails = response.text;
            }
          } catch (e) {
            print('Error getting AI accident details: $e');
          }
        }
        
        // Call ambulance with AI-generated message
        await aiCallService.callAmbulanceWithAI(
          phoneNumber: number,
          location: location,
          accidentDetails: accidentDetails ?? message,
        );
      } else {
        // Standard call without AI
        final callUri = Uri.parse('tel:$number');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        }

        // Send SMS with details
        final smsUri = Uri.parse('sms:$number?body=${Uri.encodeComponent(detailedMessage)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }

      // Always send WhatsApp message
      final whatsappMessage = '🚨 EMERGENCY - ACCIDENT DETECTED 🚨\n\n'
          '$message\n\n'
          '📍 Location: $mapUrl\n'
          'Coordinates: ${location.latitude}, ${location.longitude}\n\n'
          '🕐 Time: ${DateTime.now()}\n\n'
          '${image != null ? "📷 Photo analyzed by AI - Accident details included" : ""}';
      
      final cleanWhatsAppNumber = ambulanceWhatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final whatsappUri = Uri.parse('https://wa.me/$cleanWhatsAppNumber?text=${Uri.encodeComponent(whatsappMessage)}');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      }

      print('Ambulance called: $number');
      print('WhatsApp sent to: $cleanWhatsAppNumber');
    } catch (e) {
      print('Error calling ambulance: $e');
    }
  }

  Future<void> _callPolice(String number, String message, Position location) async {
    try {
      final policeMessage = '🚨 ACCIDENT ALERT 🚨\n\n'
          '$message\n\n'
          'Location: ${location.latitude}, ${location.longitude}\n'
          'Time: ${DateTime.now()}\n\n'
          'Please coordinate with ambulance services.';

      final smsUri = Uri.parse('sms:$number?body=${Uri.encodeComponent(policeMessage)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      print('Error notifying police: $e');
    }
  }

  Future<void> _notifyEmergencyContacts(Position location, [dynamic imageFile]) async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
    
    String message;
    if (imageFile != null) {
      message = '🚨 ACCIDENT REPORTED 🚨\n\n'
          'A nearby accident has been reported with photo evidence.\n\n'
          'Location: ${location.latitude}, ${location.longitude}\n'
          'Google Maps: https://www.google.com/maps?q=${location.latitude},${location.longitude}\n'
          'Time: ${DateTime.now()}\n\n'
          'Ambulance has been called automatically.\n'
          'Accident photo available in app.';
    } else {
      message = '🚨 ACCIDENT DETECTED 🚨\n\n'
          'An accident has been detected.\n'
          'Location: ${location.latitude}, ${location.longitude}\n'
          'Google Maps: https://www.google.com/maps?q=${location.latitude},${location.longitude}\n'
          'Time: ${DateTime.now()}\n\n'
          'Ambulance has been called automatically.\n'
          'Accident photo available in app.';
    }
    
    for (var contact in emergencyContacts) {
      try {
        final smsUri = Uri.parse('sms:$contact?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending SMS to $contact: $e');
      }
    }
    
    print('Emergency contacts notified: $message');
  }

  Future<void> processAccidentPhoto(dynamic imageFile, Position location) async {
    if (kIsWeb) return; // Skip on web
    final isAccident = await detectAccidentFromPhoto(imageFile);
    
    if (isAccident) {
      // Call ambulance with image and location
      await callAmbulanceWithAI(location, accidentImage: imageFile);
      
      // Also trigger full emergency response
      await _triggerEmergencyResponse(location);
    }
  }

  Future<void> reportNearbyAccident(dynamic imageFile, Position location) async {
    if (kIsWeb) {
      // On web, show message
      print('Accident reporting not available on web');
      return;
    }

    // Analyze image to confirm it's an accident
    final isAccident = await detectAccidentFromPhoto(imageFile);
    
    if (isAccident) {
      // Immediately call ambulance with location and image
      await callAmbulanceWithAI(location, accidentImage: imageFile);
      
      // Notify emergency contacts
      await _notifyEmergencyContacts(location, imageFile);
      
      // Trigger full emergency response
      await _triggerEmergencyResponse(location, imageFile);
    } else {
      // Even if AI doesn't detect accident, allow manual report
      // Still call ambulance but with basic info
      await callAmbulanceWithAI(location, accidentImage: imageFile);
      await _notifyEmergencyContacts(location, imageFile);
      await _triggerEmergencyResponse(location, imageFile);
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _positionSubscription?.cancel();
    _speedMonitor?.cancel();
  }
}

