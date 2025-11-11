// lib/services/ai_copilot_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AICopilotMessage {
  final String question;
  final String answer;
  final DateTime timestamp;
  final bool isUser;

  AICopilotMessage({
    required this.question,
    required this.answer,
    required this.timestamp,
    this.isUser = false,
  });
}

class AICopilotService {
  static final AICopilotService _instance = AICopilotService._internal();
  factory AICopilotService() => _instance;
  AICopilotService._internal();

  GenerativeModel? _model;
  String? _apiKey;
  final List<AICopilotMessage> _conversationHistory = [];
  bool _isInitialized = false;
  DateTime? _lastInitTime;

  Future<void> initialize(String apiKey) async {
    if (_apiKey == apiKey && _model != null) {
      return; // Already initialized with same key
    }
    _apiKey = apiKey;
    if (apiKey.isNotEmpty) {
      try {
        _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            maxOutputTokens: 1024, // Limit response length for faster responses
            temperature: 0.7, // Balanced creativity
          ),
        );
        _isInitialized = true;
        _lastInitTime = DateTime.now();
      } catch (e) {
        print('Error initializing Gemini model: $e');
        _isInitialized = false;
        _model = null;
      }
    }
  }

  // Load API key from SharedPreferences on service initialization
  Future<void> loadApiKeyFromStorage() async {
    if (_isInitialized && _lastInitTime != null && 
        DateTime.now().difference(_lastInitTime!).inMinutes < 5) {
      return; // Already initialized recently, skip
    }
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      await initialize(savedKey);
    }
  }

  Future<String> askQuestion(String question, {Map<String, dynamic>? context}) async {
    // Ensure API key is loaded
    if (!_isInitialized || _model == null) {
      await loadApiKeyFromStorage();
    }
    
    // Check if API key is available
    if (_apiKey == null || _apiKey!.isEmpty) {
      final noApiKeyMessage = '• AI Assistant requires Gemini API key.\n'
          '• Go to Settings > AI Configuration.\n'
          '• Get free key: https://makersuite.google.com/app/apikey';
      
      _conversationHistory.add(AICopilotMessage(
        question: question,
        answer: noApiKeyMessage,
        timestamp: DateTime.now(),
      ));
      
      return noApiKeyMessage;
    }
    
    // Real AI service - requires API key
    if (_model != null && _apiKey != null && _apiKey!.isNotEmpty) {
      try {
        // Build optimized prompt (shorter for faster response)
        String prompt = _buildOptimizedPrompt(question, context ?? {});
        
        // Use faster timeout and optimized generation config
        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(
          content,
        ).timeout(
          const Duration(seconds: 8), // Reduced from 15s to 8s for faster response
          onTimeout: () {
            throw TimeoutException('Request timed out. Please try again.');
          },
        );
        
        var answer = response.text ?? 'I could not generate a response.';
        
        // Ensure answer is formatted as bullet points
        answer = _formatAsBulletPoints(answer);
        
        // Save to conversation history (limit to last 20 messages)
        _conversationHistory.add(AICopilotMessage(
          question: question,
          answer: answer,
          timestamp: DateTime.now(),
        ));
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeAt(0);
        }

        return answer;
      } on TimeoutException {
        return '• Request timed out. Please try again.\n• Check your internet connection.\n• Try asking a shorter question.';
      } catch (e) {
        // Real error - return informative message
        print('AI API error: $e');
        String errorMsg = e.toString();
        if (errorMsg.length > 100) {
          errorMsg = '${errorMsg.substring(0, 100)}...';
        }
        final errorMessage = '• Unable to process request right now.\n'
            '• Check internet connection.\n'
            '• Verify Gemini API key in Settings.\n'
            '• Error: $errorMsg';
        
        _conversationHistory.add(AICopilotMessage(
          question: question,
          answer: errorMessage,
          timestamp: DateTime.now(),
        ));
        
        return errorMessage;
      }
    }
    
    // Model is null but API key exists - initialization may have failed
    final initErrorMessage = '• AI model initialization failed.\n'
        '• Please check your API key in Settings > AI Configuration.\n'
        '• Verify your internet connection and try again.';
    
    _conversationHistory.add(AICopilotMessage(
      question: question,
      answer: initErrorMessage,
      timestamp: DateTime.now(),
    ));

    return initErrorMessage;
  }

  String _buildOptimizedPrompt(String question, Map<String, dynamic> context) {
    // Optimized shorter prompt for faster responses
    String prompt = '''You are PRAVASI AI travel assistant. Answer concisely in bullet points.

APP: SOS button (home), Add Trip (Trips tab), Safe Zones, Navigation, Transport Booking, Expense Tracking, Settings (Profile tab).

''';
    
    if (context.containsKey('location')) {
      prompt += 'Location: ${context['location']}\n';
    }
    
    prompt += 'Question: $question\n\n';
    
    // Special handling for trip planning
    if (question.toLowerCase().contains('plan') || 
        question.toLowerCase().contains('trip') || 
        question.toLowerCase().contains('route') ||
        question.toLowerCase().contains('travel')) {
      prompt += '''Format: For each stop include distance, transport options, cheapest option with cost, time, next stop. Use bullet points. Include totals at end.
''';
    } else {
      prompt += '''Format: Use bullet points (•). Keep concise. Be actionable.
''';
    }
    
    return prompt;
  }

  Future<String> getTravelAdvice(Position location) async {
    return await askQuestion(
      'What travel advice do you have for someone at this location? Include safety tips, weather, and local information.',
      context: {'location': '${location.latitude}, ${location.longitude}'},
    );
  }

  Future<String> suggestRoute(String origin, String destination) async {
    return await askQuestion(
      'Suggest the best route from $origin to $destination. Consider safety, time, and cost.',
    );
  }

  Future<String> getSafetyTips(String situation) async {
    return await askQuestion(
      'Provide safety tips for: $situation',
    );
  }

  Future<String> analyzeTripData(Map<String, dynamic> tripData) async {
    return await askQuestion(
      'Analyze this trip data and provide insights: $tripData',
    );
  }

  String _formatAsBulletPoints(String text) {
    // If already has bullet points, return as is
    if (text.contains('•') || text.contains('-') || text.contains('*')) {
      return text;
    }
    
    // Split by newlines and format
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length > 1) {
      return lines.map((line) {
        final trimmed = line.trim();
        // If line already starts with number or bullet, keep it
        if (trimmed.startsWith(RegExp(r'^\d+[.)]')) || 
            trimmed.startsWith('•') || 
            trimmed.startsWith('-') ||
            trimmed.startsWith('*')) {
          return trimmed;
        }
        return '• $trimmed';
      }).join('\n');
    } else {
      // Single line - split by sentences and make bullets
      final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
      if (sentences.length > 1) {
        return sentences.map((s) => '• ${s.trim()}').join('\n');
      } else {
        return '• $text';
      }
    }
  }

  List<AICopilotMessage> getConversationHistory() => _conversationHistory;
  
  void clearHistory() {
    _conversationHistory.clear();
  }
}

class ChatMessage {
  final String question;
  final String answer;
  final DateTime timestamp;

  ChatMessage({
    required this.question,
    required this.answer,
    required this.timestamp,
  });
}

