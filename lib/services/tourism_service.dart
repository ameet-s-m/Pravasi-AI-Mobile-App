// lib/services/tourism_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class TourismService {
  static final TourismService _instance = TourismService._internal();
  factory TourismService() => _instance;
  TourismService._internal();

  GenerativeModel? _model;
  String? _apiKey;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized && _model != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      await _initializeModel(savedKey);
    }
  }

  Future<void> _initializeModel(String apiKey) async {
    try {
      _apiKey = apiKey;
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 2048,
          temperature: 0.7,
        ),
      );
      _isInitialized = true;
    } catch (e) {
      print('Error initializing Gemini model for tourism: $e');
      _isInitialized = false;
      _model = null;
    }
  }

  Future<void> loadApiKeyFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      await _initializeModel(savedKey);
    }
  }

  // Get tourist attractions near a location using AI
  Future<List<TouristAttraction>> getTouristAttractions(
    Position location, {
    double radiusKm = 50.0,
    String? category,
  }) async {
    await loadApiKeyFromStorage();
    
    if (_model == null || _apiKey == null || _apiKey!.isEmpty) {
      return _getFallbackAttractions(location);
    }

    try {
      final prompt = '''You are a tourism expert. Based on the location (${location.latitude}, ${location.longitude}), provide a list of top tourist attractions within ${radiusKm}km radius.

${category != null ? 'Focus on: $category attractions' : 'Include various types: historical sites, natural attractions, cultural places, entertainment, etc.'}

For each attraction, provide in JSON format:
{
  "attractions": [
    {
      "name": "Attraction Name",
      "category": "Historical/Museum/Natural/Religious/Entertainment",
      "description": "Brief description (2-3 sentences)",
      "latitude": approximate_latitude,
      "longitude": approximate_longitude,
      "rating": 4.5,
      "openingHours": "9:00 AM - 6:00 PM",
      "entryFee": "₹100-500",
      "highlights": ["feature1", "feature2", "feature3"],
      "bestTimeToVisit": "Morning/Afternoon/Evening",
      "visitDuration": "2-3 hours",
      "tips": "Local tip or important information"
    }
  ]
}

Provide 8-12 attractions. Use realistic coordinates near the given location (within ${radiusKm}km).
Return ONLY valid JSON, no explanations.''';

      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      final responseText = response.text ?? '';
      return _parseAttractionsFromAI(responseText, location);
    } catch (e) {
      print('Error getting tourist attractions from AI: $e');
      return _getFallbackAttractions(location);
    }
  }

  // Get travel guide for a location
  Future<TravelGuide> getTravelGuide(Position location, {int days = 3}) async {
    await loadApiKeyFromStorage();
    
    if (_model == null || _apiKey == null || _apiKey!.isEmpty) {
      return _getFallbackTravelGuide(location, days);
    }

    try {
      final prompt = '''You are a travel expert. Create a comprehensive ${days}-day travel guide for location (${location.latitude}, ${location.longitude}).

Provide:
1. Overview of the destination
2. Best time to visit
3. How to reach
4. Day-by-day itinerary
5. Must-try local food
6. Cultural tips and etiquette
7. Budget estimate
8. Safety tips

Format as JSON:
{
  "overview": "Destination overview",
  "bestTimeToVisit": "Season/Months",
  "howToReach": "Transportation options",
  "itinerary": [
    {
      "day": 1,
      "title": "Day 1 Title",
      "activities": ["activity1", "activity2"],
      "places": ["place1", "place2"]
    }
  ],
  "localFood": ["food1", "food2"],
  "culturalTips": ["tip1", "tip2"],
  "budgetEstimate": "₹5000-10000 per day",
  "safetyTips": ["tip1", "tip2"]
}

Return ONLY valid JSON.''';

      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));

      final responseText = response.text ?? '';
      return _parseTravelGuideFromAI(responseText, location, days);
    } catch (e) {
      print('Error getting travel guide from AI: $e');
      return _getFallbackTravelGuide(location, days);
    }
  }

  // Get local recommendations (restaurants, experiences, etc.)
  Future<LocalRecommendations> getLocalRecommendations(Position location) async {
    await loadApiKeyFromStorage();
    
    if (_model == null || _apiKey == null || _apiKey!.isEmpty) {
      return _getFallbackRecommendations(location);
    }

    try {
      final prompt = '''You are a local travel expert. For location (${location.latitude}, ${location.longitude}), provide local recommendations:

1. Top restaurants (local cuisine)
2. Street food spots
3. Shopping areas
4. Nightlife options
5. Local experiences/activities
6. Hidden gems

Format as JSON:
{
  "restaurants": [
    {"name": "Restaurant Name", "cuisine": "Type", "priceRange": "₹₹", "specialty": "Dish"}
  ],
  "streetFood": ["item1", "item2"],
  "shopping": ["area1", "area2"],
  "nightlife": ["place1", "place2"],
  "experiences": ["experience1", "experience2"],
  "hiddenGems": ["gem1", "gem2"]
}

Return ONLY valid JSON.''';

      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      final responseText = response.text ?? '';
      return _parseRecommendationsFromAI(responseText, location);
    } catch (e) {
      print('Error getting local recommendations from AI: $e');
      return _getFallbackRecommendations(location);
    }
  }

  // Get weather-based recommendations
  Future<String> getWeatherBasedRecommendations(Position location, String weatherCondition) async {
    await loadApiKeyFromStorage();
    
    if (_model == null || _apiKey == null || _apiKey!.isEmpty) {
      return '• Check weather before planning outdoor activities\n• Carry appropriate clothing\n• Stay hydrated';
    }

    try {
      final prompt = '''For location (${location.latitude}, ${location.longitude}) with weather condition: $weatherCondition

Provide specific tourism recommendations based on this weather:
- Best activities for this weather
- Indoor alternatives if needed
- What to wear/carry
- Safety precautions

Format as bullet points. Keep it concise and actionable.''';

      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));

      return response.text ?? 'Weather-based recommendations not available.';
    } catch (e) {
      print('Error getting weather recommendations: $e');
      return 'Weather-based recommendations not available.';
    }
  }

  // Get budget-friendly travel suggestions
  Future<String> getBudgetFriendlySuggestions(Position location, double budget) async {
    await loadApiKeyFromStorage();
    
    if (_model == null || _apiKey == null || _apiKey!.isEmpty) {
      return '• Look for free attractions\n• Use public transport\n• Try local street food\n• Book budget accommodations';
    }

    try {
      final prompt = '''For location (${location.latitude}, ${location.longitude}) with budget: ₹$budget

Provide budget-friendly travel suggestions:
- Free/cheap attractions
- Affordable accommodation options
- Budget food options
- Cost-saving tips
- Public transport options

Format as bullet points. Be specific and practical.''';

      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));

      return response.text ?? 'Budget suggestions not available.';
    } catch (e) {
      print('Error getting budget suggestions: $e');
      return 'Budget suggestions not available.';
    }
  }

  List<TouristAttraction> _parseAttractionsFromAI(String responseText, Position location) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        return _getFallbackAttractions(location);
      }

      final jsonText = jsonMatch.group(0)!;
      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      final attractionsList = data['attractions'] as List<dynamic>?;

      if (attractionsList == null) {
        return _getFallbackAttractions(location);
      }

      return attractionsList.map((item) {
        final att = item as Map<String, dynamic>;
        return TouristAttraction(
          name: att['name'] as String? ?? 'Unknown',
          category: att['category'] as String? ?? 'Tourist Attraction',
          description: att['description'] as String? ?? 'A popular tourist destination',
          latitude: (att['latitude'] as num?)?.toDouble() ?? location.latitude + (0.01 * (attractionsList.indexOf(item) - 5)),
          longitude: (att['longitude'] as num?)?.toDouble() ?? location.longitude + (0.01 * (attractionsList.indexOf(item) - 5)),
          rating: (att['rating'] as num?)?.toDouble() ?? 4.0,
          openingHours: att['openingHours'] as String? ?? '9:00 AM - 6:00 PM',
          entryFee: att['entryFee'] as String? ?? 'Varies',
          highlights: (att['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          bestTimeToVisit: att['bestTimeToVisit'] as String? ?? 'Morning',
          visitDuration: att['visitDuration'] as String? ?? '2-3 hours',
          tips: att['tips'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error parsing attractions: $e');
      return _getFallbackAttractions(location);
    }
  }

  TravelGuide _parseTravelGuideFromAI(String responseText, Position location, int days) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        return _getFallbackTravelGuide(location, days);
      }

      final jsonText = jsonMatch.group(0)!;
      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      final itineraryList = data['itinerary'] as List<dynamic>? ?? [];
      final itinerary = itineraryList.map((item) {
        final day = item as Map<String, dynamic>;
        return DayItinerary(
          day: day['day'] as int? ?? 1,
          title: day['title'] as String? ?? 'Day ${day['day']}',
          activities: (day['activities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          places: (day['places'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      }).toList();

      return TravelGuide(
        location: location,
        days: days,
        overview: data['overview'] as String? ?? 'A beautiful destination worth exploring',
        bestTimeToVisit: data['bestTimeToVisit'] as String? ?? 'Year-round',
        howToReach: data['howToReach'] as String? ?? 'By road, rail, or air',
        itinerary: itinerary,
        localFood: (data['localFood'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        culturalTips: (data['culturalTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        budgetEstimate: data['budgetEstimate'] as String? ?? 'Varies',
        safetyTips: (data['safetyTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
    } catch (e) {
      print('Error parsing travel guide: $e');
      return _getFallbackTravelGuide(location, days);
    }
  }

  LocalRecommendations _parseRecommendationsFromAI(String responseText, Position location) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        return _getFallbackRecommendations(location);
      }

      final jsonText = jsonMatch.group(0)!;
      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      return LocalRecommendations(
        location: location,
        restaurants: (data['restaurants'] as List<dynamic>?)?.map((r) {
          final rest = r as Map<String, dynamic>;
          return Restaurant(
            name: rest['name'] as String? ?? 'Restaurant',
            cuisine: rest['cuisine'] as String? ?? 'Local',
            priceRange: rest['priceRange'] as String? ?? '₹₹',
            specialty: rest['specialty'] as String?,
          );
        }).toList() ?? [],
        streetFood: (data['streetFood'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        shopping: (data['shopping'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        nightlife: (data['nightlife'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        experiences: (data['experiences'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        hiddenGems: (data['hiddenGems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
    } catch (e) {
      print('Error parsing recommendations: $e');
      return _getFallbackRecommendations(location);
    }
  }

  List<TouristAttraction> _getFallbackAttractions(Position location) {
    // Return empty list - let UI show message about needing API key
    return [];
  }

  TravelGuide _getFallbackTravelGuide(Position location, int days) {
    return TravelGuide(
      location: location,
      days: days,
      overview: 'A beautiful destination worth exploring. Set up Gemini API key for detailed travel guide.',
      bestTimeToVisit: 'Year-round',
      howToReach: 'By road, rail, or air',
      itinerary: [],
      localFood: [],
      culturalTips: [],
      budgetEstimate: 'Varies',
      safetyTips: [],
    );
  }

  LocalRecommendations _getFallbackRecommendations(Position location) {
    return LocalRecommendations(
      location: location,
      restaurants: [],
      streetFood: [],
      shopping: [],
      nightlife: [],
      experiences: [],
      hiddenGems: [],
    );
  }
}

class TouristAttraction {
  final String name;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final double rating;
  final String openingHours;
  final String entryFee;
  final List<String> highlights;
  final String bestTimeToVisit;
  final String visitDuration;
  final String? tips;

  TouristAttraction({
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.openingHours,
    required this.entryFee,
    this.highlights = const [],
    this.bestTimeToVisit = 'Morning',
    this.visitDuration = '2-3 hours',
    this.tips,
  });
}

class TravelGuide {
  final Position location;
  final int days;
  final String overview;
  final String bestTimeToVisit;
  final String howToReach;
  final List<DayItinerary> itinerary;
  final List<String> localFood;
  final List<String> culturalTips;
  final String budgetEstimate;
  final List<String> safetyTips;

  TravelGuide({
    required this.location,
    required this.days,
    required this.overview,
    required this.bestTimeToVisit,
    required this.howToReach,
    required this.itinerary,
    required this.localFood,
    required this.culturalTips,
    required this.budgetEstimate,
    required this.safetyTips,
  });
}

class DayItinerary {
  final int day;
  final String title;
  final List<String> activities;
  final List<String> places;

  DayItinerary({
    required this.day,
    required this.title,
    required this.activities,
    required this.places,
  });
}

class LocalRecommendations {
  final Position location;
  final List<Restaurant> restaurants;
  final List<String> streetFood;
  final List<String> shopping;
  final List<String> nightlife;
  final List<String> experiences;
  final List<String> hiddenGems;

  LocalRecommendations({
    required this.location,
    required this.restaurants,
    required this.streetFood,
    required this.shopping,
    required this.nightlife,
    required this.experiences,
    required this.hiddenGems,
  });
}

class Restaurant {
  final String name;
  final String cuisine;
  final String priceRange;
  final String? specialty;

  Restaurant({
    required this.name,
    required this.cuisine,
    required this.priceRange,
    this.specialty,
  });
}

