// lib/services/mock_service.dart
// Mock service for demo features that don't need real APIs

class MockService {
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal();

  // Mock AI responses
  Future<String> getMockAIResponse(String question) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
    
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('safety') || lowerQuestion.contains('safe')) {
      return 'For your safety, always share your live location with trusted contacts. '
          'Enable route deviation detection and keep emergency contacts updated. '
          'Use the SOS button if you feel unsafe.';
    } else if (lowerQuestion.contains('route') || lowerQuestion.contains('directions')) {
      return 'I recommend taking the main highway route. It\'s well-lit and has more traffic, '
          'making it safer. Estimated travel time is 45 minutes.';
    } else if (lowerQuestion.contains('weather')) {
      return 'Current weather is sunny with 28°C. No rain expected. Perfect for travel!';
    } else if (lowerQuestion.contains('hotel')) {
      return 'I found 3 hotels nearby. Grand Hotel (₹2500/night, 4.5⭐) is closest at 1.2km. '
          'Would you like me to book it?';
    } else if (lowerQuestion.contains('transport') || lowerQuestion.contains('bus') || lowerQuestion.contains('train')) {
      return 'For your route, I recommend taking the bus (₹150, 1.5 hours) as it\'s the cheapest option. '
          'Train is faster (₹200, 1 hour) but slightly more expensive.';
    } else {
      return 'I understand you\'re asking about "$question". '
          'PRAVASI AI is here to help with your travel and safety needs. '
          'You can ask me about routes, safety tips, transport options, hotels, or weather.';
    }
  }

  // Mock OCR extraction
  Future<Map<String, String>> extractTripFromImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    
    // Return mock extracted data
    return {
      'origin': 'Mumbai Central',
      'destination': 'Pune Junction',
      'time': '14:30',
      'date': DateTime.now().toString().split(' ')[0],
      'vehicle': 'Train',
      'ticketNumber': 'PNR123456',
    };
  }

  // Mock accident detection
  Future<bool> detectAccidentFromImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 3));
    // For demo, return false (no accident detected)
    // In real app, this would use Gemini Vision API
    return false;
  }

  // Mock weather data
  Future<Map<String, dynamic>> getMockWeather(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'temperature': 28.0,
      'condition': 'Sunny',
      'humidity': 65.0,
      'windSpeed': 15.0,
      'description': 'Clear sky with light breeze',
    };
  }

  // Mock transport options
  Future<List<Map<String, dynamic>>> getMockTransportOptions({
    required double distance,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'type': 'Bus',
        'price': distance * 5,
        'duration': (distance / 0.5).round(),
        'rating': 4.2,
        'available': true,
      },
      {
        'type': 'Train',
        'price': distance * 2,
        'duration': (distance / 0.8).round(),
        'rating': 4.5,
        'available': true,
      },
      {
        'type': 'Taxi',
        'price': 50 + (distance * 12),
        'duration': (distance / 0.6).round(),
        'rating': 4.0,
        'available': true,
      },
    ];
  }

  // Mock hotel data
  Future<List<Map<String, dynamic>>> getMockHotels(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'name': 'Grand Hotel',
        'price': 2500,
        'rating': 4.5,
        'distance': 1.2,
        'amenities': ['WiFi', 'AC', 'Pool'],
      },
      {
        'name': 'Budget Inn',
        'price': 800,
        'rating': 3.8,
        'distance': 0.8,
        'amenities': ['WiFi', 'AC'],
      },
    ];
  }
}

