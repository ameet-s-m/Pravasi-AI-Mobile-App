// lib/services/analytics_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_data_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Future<SafetyAnalytics> getSafetyAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get real trip data
    final tripService = TripDataService();
    await tripService.initialize();
    final trips = tripService.getTrips();
    
    // Calculate from real data
    final totalTrips = trips.length;
    final safeTrips = trips.where((t) => t.isCompleted && !t.notes.toLowerCase().contains('incident')).length;
    final incidentsReported = prefs.getInt('incidents_reported') ?? 0;
    final emergencyAlerts = prefs.getInt('emergency_alerts') ?? 0;
    
    // Calculate average duration from real trips
    double avgDuration = 0.0;
    if (trips.isNotEmpty) {
      final durations = trips.where((t) => t.duration != null).map((t) {
        // Parse duration string like "1h 15m" to minutes
        final parts = t.duration.split(' ');
        int totalMinutes = 0;
        for (var part in parts) {
          if (part.contains('h')) {
            totalMinutes += int.parse(part.replaceAll('h', '')) * 60;
          } else if (part.contains('m')) {
            totalMinutes += int.parse(part.replaceAll('m', ''));
          }
        }
        return totalMinutes.toDouble();
      }).toList();
      if (durations.isNotEmpty) {
        avgDuration = durations.reduce((a, b) => a + b) / durations.length;
      }
    }
    
    return SafetyAnalytics(
      totalTrips: totalTrips,
      safeTrips: safeTrips,
      incidentsReported: incidentsReported,
      emergencyAlerts: emergencyAlerts,
      averageTripDuration: avgDuration,
      mostUsedRoutes: _getMostUsedRoutes(trips),
      safetyScore: _calculateSafetyScore(totalTrips, safeTrips),
    );
  }
  
  double _calculateSafetyScore(int totalTrips, int safeTrips) {
    if (totalTrips == 0) return 0.0;
    final baseScore = (safeTrips / totalTrips) * 100;
    // Add bonus for more trips (experience)
    final experienceBonus = (totalTrips > 20) ? 5.0 : 0.0;
    return (baseScore + experienceBonus).clamp(0.0, 100.0);
  }

  Future<void> recordTrip({
    required bool wasSafe,
    required double duration,
    String? route,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final totalTrips = (prefs.getInt('total_trips') ?? 0) + 1;
    final safeTrips = (prefs.getInt('safe_trips') ?? 0) + (wasSafe ? 1 : 0);
    
    await prefs.setInt('total_trips', totalTrips);
    await prefs.setInt('safe_trips', safeTrips);
    
    // Update average duration
    final currentAvg = prefs.getDouble('avg_trip_duration') ?? 0.0;
    final newAvg = ((currentAvg * (totalTrips - 1)) + duration) / totalTrips;
    await prefs.setDouble('avg_trip_duration', newAvg);
    
    // Store route
    if (route != null) {
      final routes = prefs.getStringList('routes') ?? [];
      routes.add(route);
      await prefs.setStringList('routes', routes);
    }
  }

  Future<void> recordIncident() async {
    final prefs = await SharedPreferences.getInstance();
    final incidents = (prefs.getInt('incidents_reported') ?? 0) + 1;
    await prefs.setInt('incidents_reported', incidents);
  }

  Future<void> recordEmergencyAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = (prefs.getInt('emergency_alerts') ?? 0) + 1;
    await prefs.setInt('emergency_alerts', alerts);
  }

  List<String> _getMostUsedRoutes(List trips) {
    // Calculate most used routes from real trip data
    if (trips.isEmpty) return [];
    
    final routeCounts = <String, int>{};
    for (var trip in trips) {
      if (trip.destination != null && trip.destination!.isNotEmpty) {
        final route = trip.destination!;
        routeCounts[route] = (routeCounts[route] ?? 0) + 1;
      }
    }
    
    final sortedRoutes = routeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedRoutes.take(4).map((e) => e.key).toList();
  }
}

class SafetyAnalytics {
  final int totalTrips;
  final int safeTrips;
  final int incidentsReported;
  final int emergencyAlerts;
  final double averageTripDuration;
  final List<String> mostUsedRoutes;
  final double safetyScore;

  SafetyAnalytics({
    required this.totalTrips,
    required this.safeTrips,
    required this.incidentsReported,
    required this.emergencyAlerts,
    required this.averageTripDuration,
    required this.mostUsedRoutes,
    required this.safetyScore,
  });

  double get safetyPercentage => totalTrips > 0 ? (safeTrips / totalTrips) * 100 : 0.0;
}

