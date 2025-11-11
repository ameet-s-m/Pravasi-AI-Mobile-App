// lib/services/carbon_footprint_service.dart
import 'trip_data_service.dart';
import '../models/models.dart';

class CarbonFootprintService {
  static final CarbonFootprintService _instance = CarbonFootprintService._internal();
  factory CarbonFootprintService() => _instance;
  CarbonFootprintService._internal();

  final TripDataService _tripDataService = TripDataService();

  // Carbon emission factors (kg CO2 per km per person)
  static const Map<String, double> emissionFactors = {
    'Bus': 0.089,
    'Train': 0.014,
    'Taxi': 0.171,
    'Auto': 0.120,
    'Flight': 0.255,
    'Car': 0.171,
    'Motorcycle': 0.113,
    'Walking': 0.0,
    'Bicycle': 0.0,
  };

  /// Calculate carbon footprint for a single trip
  double calculateTripCarbon(Trip trip) {
    final factor = emissionFactors[trip.mode] ?? 0.171;
    return trip.distance * factor;
  }

  /// Get total carbon footprint from all trips
  Future<double> getTotalCarbonFootprint() async {
    await _tripDataService.initialize();
    final trips = _tripDataService.getTrips();
    double total = 0.0;

    for (var trip in trips) {
      total += calculateTripCarbon(trip);
    }

    return total;
  }

  /// Get carbon footprint breakdown by transport mode
  Future<Map<String, double>> getCarbonByMode() async {
    await _tripDataService.initialize();
    final trips = _tripDataService.getTrips();
    final Map<String, double> carbonByMode = {};

    for (var trip in trips) {
      final carbon = calculateTripCarbon(trip);
      carbonByMode[trip.mode] = (carbonByMode[trip.mode] ?? 0.0) + carbon;
    }

    return carbonByMode;
  }

  Future<String> getCarbonSavingsSuggestion() async {
    final byMode = await getCarbonByMode();
    
    if (byMode.isEmpty) {
      return 'Start tracking your trips to see your carbon footprint!';
    }

    // Find mode with highest emissions
    final highestEmissionMode = byMode.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final suggestions = {
      'Car': 'Consider using public transport or carpooling to reduce emissions.',
      'Taxi': 'Try using buses or trains for longer distances.',
      'Flight': 'For short distances, consider trains or buses instead.',
      'Auto': 'Walking or cycling for short trips can reduce your footprint.',
    };

    return suggestions[highestEmissionMode.key] ?? 
        'Great job! Keep using eco-friendly transport options.';
  }

  String formatCarbon(double kgCO2) {
    if (kgCO2 < 1) {
      return '${(kgCO2 * 1000).toStringAsFixed(0)}g CO₂';
    }
    return '${kgCO2.toStringAsFixed(2)}kg CO₂';
  }
}

