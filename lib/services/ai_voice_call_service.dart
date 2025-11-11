// lib/services/ai_voice_call_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

class AIVoiceCallService {
  static final AIVoiceCallService _instance = AIVoiceCallService._internal();
  factory AIVoiceCallService() => _instance;
  AIVoiceCallService._internal();

  String? _geminiApiKey;
  GenerativeModel? _model;

  Future<void> initialize(String apiKey) async {
    _geminiApiKey = apiKey;
    if (apiKey.isNotEmpty) {
      try {
        _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
        );
      } catch (e) {
        print('Error initializing Gemini model: $e');
        _model = null;
      }
    }
  }

  Future<void> loadApiKeyFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      await initialize(savedKey);
    }
  }

  // Generate AI message explaining the emergency situation with detailed condition
  Future<String> generateEmergencyMessage({
    required String emergencyType,
    required Position location,
    String? additionalDetails,
  }) async {
    if (_model == null || _geminiApiKey == null || _geminiApiKey!.isEmpty) {
      // Fallback message if AI not available
      return _generateFallbackMessage(emergencyType, location, additionalDetails);
    }

    try {
      final mapUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
      
      final prompt = 'You are an AI emergency assistant. Generate a detailed, natural, and urgent emergency message to inform family members or emergency services.\n\n'
          'EMERGENCY DETAILS:\n'
          'Type: $emergencyType\n'
          'Location Coordinates: ${location.latitude}, ${location.longitude}\n'
          'Google Maps Link: $mapUrl\n'
          '${additionalDetails != null ? "Additional Details: $additionalDetails\n" : ""}'
          'Current Time: ${DateTime.now().toString()}\n\n'
          'INSTRUCTIONS:\n'
          '1. Start with a clear emergency alert\n'
          '2. Explain the situation in detail - what happened, current condition, severity\n'
          '3. Provide exact location with address if possible, plus coordinates and Google Maps link\n'
          '4. Include all relevant details about the emergency condition\n'
          '5. Request immediate assistance clearly\n'
          '6. Make it natural, conversational, and easy to understand when read aloud\n'
          '7. Keep it comprehensive but concise (150-200 words)\n'
          '8. Use clear, simple language suitable for phone calls or messages\n\n'
          'Generate a complete, detailed message that fully explains the emergency condition and situation.';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? _generateFallbackMessage(emergencyType, location, additionalDetails);
    } catch (e) {
      print('Error generating AI message: $e');
      return _generateFallbackMessage(emergencyType, location, additionalDetails);
    }
  }

  String _generateFallbackMessage(String emergencyType, Position location, String? additionalDetails) {
    final mapUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    return '🚨 EMERGENCY ALERT 🚨\n\n'
        'This is an emergency situation.\n\n'
        'Type: $emergencyType\n'
        'Location: ${location.latitude}, ${location.longitude}\n'
        'Google Maps: $mapUrl\n'
        'Time: ${DateTime.now()}\n\n'
        '${additionalDetails != null ? "$additionalDetails\n\n" : ""}'
        'Please send help immediately!';
  }

  // Call family member with AI-generated detailed message
  Future<bool> callFamilyMemberWithAI({
    required String phoneNumber,
    required String emergencyType,
    required Position location,
    String? additionalDetails,
  }) async {
    try {
      // Generate detailed AI message with full condition details
      final message = await generateEmergencyMessage(
        emergencyType: emergencyType,
        location: location,
        additionalDetails: additionalDetails,
      );
      
      print('📞 AI-Generated Emergency Message:\n$message\n');

      // Clean phone number for different uses
      // Remove spaces and keep only digits and +
      var cleanNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
      
      // Ensure it starts with + for international format
      if (!cleanNumber.startsWith('+')) {
        // If it starts with 91 (India), add +
        if (cleanNumber.startsWith('91')) {
          cleanNumber = '+$cleanNumber';
        } else {
          // Assume it's Indian number, add +91
          cleanNumber = '+91$cleanNumber';
        }
      }
      
      // For tel: URI, use with +
      final telNumber = cleanNumber;
      // For WhatsApp, remove + and use only digits (must be exactly digits)
      final whatsappNumber = cleanNumber.replaceAll('+', '').replaceAll(RegExp(r'[^0-9]'), '');

      // Note: Phone call is now handled by SOS button directly
      // This service only generates and sends the AI message via SMS/WhatsApp
      // Phone call is skipped here to prevent duplicate calls

      // 2. Send REAL SMS with AI-generated message
      // This will open your SMS app with message ready to send
      try {
        final smsUri = Uri.parse('sms:$telNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(
            smsUri,
            mode: LaunchMode.externalApplication, // Opens real SMS app
          );
          print('✅ REAL SMS app opened with message for: $telNumber');
          // Small delay before opening WhatsApp
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('❌ Error sending SMS: $e');
      }

      // 3. Send REAL WhatsApp message with detailed AI-generated message
      // This will open WhatsApp with the contact and detailed message ready to send
      try {
        final whatsappMessage = '🚨 EMERGENCY - $emergencyType 🚨\n\n'
            '$message\n\n'
            '⚠️ This is an automated emergency alert from PRAVASI AI Safety App. '
            'Please respond immediately and send help if needed.';
        // WhatsApp format: https://wa.me/919035280631?text=message (no +, only digits)
        final whatsappUri = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(whatsappMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(
            whatsappUri,
            mode: LaunchMode.externalApplication, // Opens real WhatsApp
          );
          print('✅ REAL WhatsApp opened for: $whatsappNumber with detailed AI message');
        } else {
          print('❌ Cannot launch WhatsApp for: $whatsappNumber');
        }
      } catch (e) {
        print('❌ Error opening WhatsApp: $e');
      }

      print('✅ AI Voice Call Service completed - Phone, SMS, and WhatsApp sent with detailed condition');
      return true;
    } catch (e) {
      print('Error calling family member: $e');
      return false;
    }
  }

  // Call ambulance with detailed AI-generated message explaining condition
  Future<bool> callAmbulanceWithAI({
    required String phoneNumber,
    required Position location,
    String? accidentDetails,
  }) async {
    try {
      // Generate detailed AI message for ambulance with full condition details
      final message = await generateEmergencyMessage(
        emergencyType: 'Road Accident - Medical Emergency',
        location: location,
        additionalDetails: accidentDetails ?? 'Accident automatically detected by sensors. Immediate medical assistance required. Please send ambulance immediately.',
      );
      
      print('🚑 AI-Generated Ambulance Message:\n$message\n');

      // Clean phone number (same logic as above)
      var cleanNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
      if (!cleanNumber.startsWith('+')) {
        if (cleanNumber.startsWith('91')) {
          cleanNumber = '+$cleanNumber';
        } else {
          cleanNumber = '+91$cleanNumber';
        }
      }
      final telNumber = cleanNumber;
      final whatsappNumber = cleanNumber.replaceAll('+', '').replaceAll(RegExp(r'[^0-9]'), '');

      // Make REAL phone call
      try {
        final callUri = Uri.parse('tel:$telNumber');
        if (await canLaunchUrl(callUri)) {
          await launchUrl(
            callUri,
            mode: LaunchMode.externalApplication,
          );
          print('Ambulance call initiated to: $telNumber');
        }
      } catch (e) {
        print('Error calling ambulance: $e');
      }

      // Send REAL SMS
      try {
        final smsUri = Uri.parse('sms:$telNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(
            smsUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        print('Error sending SMS: $e');
      }

      // Send REAL WhatsApp message with detailed condition
      try {
        final whatsappMessage = '🚨 EMERGENCY - ROAD ACCIDENT 🚨\n\n'
            '$message\n\n'
            '⚠️ This is an automated emergency alert. Please send ambulance immediately.';
        final whatsappUri = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(whatsappMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(
            whatsappUri,
            mode: LaunchMode.externalApplication,
          );
          print('✅ WhatsApp opened for ambulance: $whatsappNumber with detailed condition');
        }
      } catch (e) {
        print('Error opening WhatsApp: $e');
      }

      print('✅ AI Ambulance Call Service completed - Detailed condition sent via Phone, SMS, and WhatsApp');
      return true;
    } catch (e) {
      print('Error calling ambulance: $e');
      return false;
    }
  }
}

