// lib/services/ocr_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';

// Conditional import for File
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  String? _geminiApiKey;

  void initializeGemini(String apiKey) {
    _geminiApiKey = apiKey;
  }

  Future<Map<String, String?>> extractTripDetails(dynamic imageFile) async {
    if (kIsWeb) {
      // On web, return empty data as ML Kit doesn't work on web
      return {
        'origin': null,
        'destination': null,
        'time': null,
        'date': null,
        'vehicle': null,
        'price': null,
        'rawText': 'OCR not available on web platform',
      };
    }
    try {
      if (imageFile is! io.File) {
        return {
          'origin': null,
          'destination': null,
          'time': null,
          'date': null,
          'vehicle': null,
          'price': null,
          'rawText': 'Invalid image file',
        };
      }
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      
      // Try AI-powered extraction first if available
      Map<String, String?> aiDetails = {};
      if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty && !kIsWeb) {
        try {
          aiDetails = await _extractWithAI(imageFile, fullText);
        } catch (e) {
          print('AI extraction failed, using pattern matching: $e');
        }
      }
      
      // Extract trip details using pattern matching (fallback or supplement)
      Map<String, String?> patternDetails = {
        'origin': _extractOrigin(fullText),
        'destination': _extractDestination(fullText),
        'time': _extractTime(fullText),
        'date': _extractDate(fullText),
        'vehicle': _extractVehicle(fullText),
        'price': _extractPrice(fullText),
      };

      // Merge results - prefer AI results, fallback to pattern matching
      Map<String, String?> details = {
        'origin': aiDetails['origin'] ?? patternDetails['origin'] ?? _extractLocationByOrder(fullText, isOrigin: true),
        'destination': aiDetails['destination'] ?? patternDetails['destination'] ?? _extractLocationByOrder(fullText, isOrigin: false),
        'time': aiDetails['time'] ?? patternDetails['time'],
        'date': aiDetails['date'] ?? patternDetails['date'],
        'vehicle': aiDetails['vehicle'] ?? patternDetails['vehicle'],
        'price': aiDetails['price'] ?? patternDetails['price'],
        'rawText': fullText,
      };

      return details;
    } catch (e) {
      print('OCR Error: $e');
      return {
        'origin': null,
        'destination': null,
        'time': null,
        'date': null,
        'vehicle': null,
        'price': null,
        'rawText': null,
      };
    }
  }

  Future<Map<String, String?>> _extractWithAI(dynamic imageFile, String text) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-pro-vision',
        apiKey: _geminiApiKey!,
      );

      Uint8List imageBytes;
      if (imageFile is io.File) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        return {};
      }

      final prompt = '''Analyze this travel ticket/receipt image and extract trip details in JSON format:
{
  "origin": "city/station name",
  "destination": "city/station name",
  "time": "departure time",
  "date": "travel date",
  "vehicle": "transport type",
  "price": "ticket price in numbers only (without currency symbol)"
}

Rules:
1. Origin is usually the first location mentioned or on the left/top
2. Destination is usually the second location or on the right/bottom
3. Look for patterns like "City1 - City2", "City1 to City2", or just two city names
4. If locations are arranged vertically, top is usually origin
5. If locations are arranged horizontally, left is usually origin
6. Extract only the city/station name, not full addresses
7. For price: Extract the ticket fare/amount. Look for keywords like "Total", "Amount", "Fare", "Price", "₹", "Rs", "INR". Extract only the numeric value (e.g., "500" not "₹500" or "Rs. 500")
8. Vehicle type: bus, train, taxi, auto, flight, etc.
9. Return only valid JSON, no explanations''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final responseText = response.text ?? '';
      
      // Try to parse JSON from response
      try {
        // Extract JSON from markdown code blocks if present
        String jsonText = responseText;
        if (responseText.contains('```')) {
          final jsonMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```').firstMatch(responseText);
          if (jsonMatch != null) {
            jsonText = jsonMatch.group(1)!;
          }
        }
        
        // Simple JSON parsing (in production, use proper JSON parser)
        final originMatch = RegExp(r'"origin"\s*:\s*"([^"]+)"').firstMatch(jsonText);
        final destMatch = RegExp(r'"destination"\s*:\s*"([^"]+)"').firstMatch(jsonText);
        final timeMatch = RegExp(r'"time"\s*:\s*"([^"]+)"').firstMatch(jsonText);
        final dateMatch = RegExp(r'"date"\s*:\s*"([^"]+)"').firstMatch(jsonText);
        final vehicleMatch = RegExp(r'"vehicle"\s*:\s*"([^"]+)"').firstMatch(jsonText);
        final priceMatch = RegExp(r'"price"\s*:\s*"([^"]+)"').firstMatch(jsonText);
        
        return {
          'origin': originMatch?.group(1)?.trim(),
          'destination': destMatch?.group(1)?.trim(),
          'time': timeMatch?.group(1)?.trim(),
          'date': dateMatch?.group(1)?.trim(),
          'vehicle': vehicleMatch?.group(1)?.trim(),
          'price': priceMatch?.group(1)?.trim(),
        };
      } catch (e) {
        print('Error parsing AI response: $e');
        return {};
      }
    } catch (e) {
      print('AI extraction error: $e');
      return {};
    }
  }

  String? _extractOrigin(String text) {
    // Look for common origin keywords
    final patterns = [
      RegExp(r'from[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'origin[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'pickup[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'boarding[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'source[:\s]+([A-Za-z\s]+)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String? result = match.group(1)?.trim();
        if (result != null && result.length > 2) {
          return result;
        }
      }
    }
    return null;
  }

  String? _extractDestination(String text) {
    // Look for common destination keywords
    final patterns = [
      RegExp(r'to[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'destination[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'drop[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'deboarding[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'arrival[:\s]+([A-Za-z\s]+)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String? result = match.group(1)?.trim();
        if (result != null && result.length > 2) {
          return result;
        }
      }
    }
    return null;
  }

  String? _extractLocationByOrder(String text, {required bool isOrigin}) {
    // Extract locations based on order/position when keywords are not present
    // Common patterns: "City1 - City2", "City1 to City2", "City1 City2", etc.
    
    // Pattern 1: "City1 - City2" or "City1–City2" (with dash)
    final dashPattern = RegExp(r'([A-Z][A-Za-z\s]+?)\s*[-–—]\s*([A-Z][A-Za-z\s]+)');
    final dashMatch = dashPattern.firstMatch(text);
    if (dashMatch != null) {
      return isOrigin ? dashMatch.group(1)?.trim() : dashMatch.group(2)?.trim();
    }
    
    // Pattern 2: "City1 to City2"
    final toPattern = RegExp(r'([A-Z][A-Za-z\s]+?)\s+to\s+([A-Z][A-Za-z\s]+)', caseSensitive: false);
    final toMatch = toPattern.firstMatch(text);
    if (toMatch != null) {
      return isOrigin ? toMatch.group(1)?.trim() : toMatch.group(2)?.trim();
    }
    
    // Pattern 3: Two consecutive capitalized words/phrases (likely city names)
    // Look for patterns like "Mumbai Pune" or "Thiruvananthapuram Aluva"
    final cityPattern = RegExp(r'([A-Z][A-Za-z]{3,}(?:\s+[A-Z][A-Za-z]+)?)\s+([A-Z][A-Za-z]{3,}(?:\s+[A-Z][A-Za-z]+)?)');
    final cityMatch = cityPattern.firstMatch(text);
    if (cityMatch != null) {
      // Check if these look like city names (not common words)
      final city1 = cityMatch.group(1)?.trim() ?? '';
      final city2 = cityMatch.group(2)?.trim() ?? '';
      
      // Filter out common non-city words
      final commonWords = ['Time', 'Date', 'Ticket', 'Price', 'Amount', 'Total', 'Passenger', 'Seat', 'Coach'];
      if (!commonWords.contains(city1) && !commonWords.contains(city2)) {
        return isOrigin ? city1 : city2;
      }
    }
    
    // Pattern 4: Extract from lines (if text is multi-line, first location might be origin)
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length >= 2) {
      // Look for lines that contain city-like names
      final cityNamePattern = RegExp(r'([A-Z][A-Za-z]{3,}(?:\s+[A-Z][A-Za-z]+)?)');
      
      List<String> potentialCities = [];
      for (var line in lines) {
        final match = cityNamePattern.firstMatch(line.trim());
        if (match != null) {
          final city = match.group(1)?.trim() ?? '';
          // Filter out common words
          if (city.length > 3 && !['Time', 'Date', 'Ticket', 'Price'].contains(city)) {
            potentialCities.add(city);
          }
        }
      }
      
      if (potentialCities.length >= 2) {
        return isOrigin ? potentialCities.first : potentialCities.last;
      } else if (potentialCities.length == 1) {
        // Only one city found - assume it's origin if we're looking for origin
        return isOrigin ? potentialCities.first : null;
      }
    }
    
    return null;
  }

  String? _extractTime(String text) {
    // Look for time patterns
    final patterns = [
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false),
      RegExp(r'(\d{1,2}):(\d{2})', caseSensitive: false),
      RegExp(r'time[:\s]+(\d{1,2}):(\d{2})', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)?.trim();
      }
    }
    return null;
  }

  String? _extractDate(String text) {
    // Look for date patterns
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      RegExp(r'date[:\s]+(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)?.trim();
      }
    }
    return null;
  }

  String? _extractVehicle(String text) {
    // Look for vehicle types
    final vehicleKeywords = ['taxi', 'cab', 'auto', 'bus', 'train', 'car', 'uber', 'ola'];
    final lowerText = text.toLowerCase();
    
    for (var keyword in vehicleKeywords) {
      if (lowerText.contains(keyword)) {
        return keyword.toUpperCase();
      }
    }
    return null;
  }

  String? _extractPrice(String text) {
    // Look for price patterns - Indian currency formats
    final patterns = [
      // ₹500, ₹1,500, ₹500.00
      RegExp(r'[₹Rs\.\s]*(\d{1,3}(?:[,\s]\d{2,3})*(?:\.\d{2})?)', caseSensitive: false),
      // Total: 500, Amount: 1500, Fare: 750
      RegExp(r'(?:total|amount|fare|price|cost)[:\s]*[₹Rs\.\s]*(\d{1,3}(?:[,\s]\d{2,3})*(?:\.\d{2})?)', caseSensitive: false),
      // INR 500, Rs. 500
      RegExp(r'(?:INR|Rs?\.?)[:\s]*(\d{1,3}(?:[,\s]\d{2,3})*(?:\.\d{2})?)', caseSensitive: false),
    ];
    
    // Try to find the largest number that looks like a price (usually the total/fare)
    double? maxPrice;
    String? priceString;
    
    for (var pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        final priceText = match.group(1)?.replaceAll(RegExp(r'[,\s]'), '') ?? '';
        final price = double.tryParse(priceText);
        if (price != null && price > 0 && price < 1000000) { // Reasonable price range
          if (maxPrice == null || price > maxPrice) {
            maxPrice = price;
            priceString = priceText;
          }
        }
      }
    }
    
    // If we found a price, return it
    if (priceString != null) {
      return priceString;
    }
    
    // Fallback: Look for standalone numbers that might be prices
    final standalonePattern = RegExp(r'\b(\d{3,6})\b');
    final standaloneMatches = standalonePattern.allMatches(text);
    double? bestPrice;
    String? bestPriceString;
    
    for (var match in standaloneMatches) {
      final numText = match.group(1) ?? '';
      final num = double.tryParse(numText);
      if (num != null && num >= 100 && num < 100000) { // Likely a ticket price
        if (bestPrice == null || num > bestPrice) {
          bestPrice = num;
          bestPriceString = numText;
        }
      }
    }
    
    return bestPriceString;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

