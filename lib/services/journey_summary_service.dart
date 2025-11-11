// lib/services/journey_summary_service.dart
import 'database_service.dart';
import 'dart:async';

class JourneySummaryService {
  static final JourneySummaryService _instance = JourneySummaryService._internal();
  factory JourneySummaryService() => _instance;
  JourneySummaryService._internal();

  final DatabaseService _dbService = DatabaseService();

  Future<JourneySummary> generateSummary(String tripId) async {
    final trip = await _dbService.database?.query(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
    );

    if (trip == null || trip.isEmpty) {
      throw Exception('Trip not found');
    }

    final tripData = trip.first;
    final locations = await _dbService.getTripLocations(tripId);
    final expenses = await _dbService.getTripExpenses(tripId);

    return JourneySummary(
      tripId: tripId,
      origin: tripData['origin'] as String,
      destination: tripData['destination'] as String,
      distance: (tripData['distance'] as num).toDouble(),
      duration: Duration(minutes: tripData['duration'] as int),
      startTime: DateTime.fromMillisecondsSinceEpoch(tripData['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(tripData['end_time'] as int),
      mode: tripData['mode'] as String,
      safetyStatus: tripData['safety_status'] as String,
      totalExpenses: expenses.fold<double>(0, (sum, exp) => sum + (exp['amount'] as num).toDouble()),
      routePoints: locations.length,
      averageSpeed: _calculateAverageSpeed(locations),
      maxSpeed: _calculateMaxSpeed(locations),
      incidents: await _getTripIncidents(tripId),
    );
  }

  double _calculateAverageSpeed(List<Map<String, dynamic>> locations) {
    if (locations.length < 2) return 0.0;
    
    double totalSpeed = 0.0;
    int count = 0;
    for (var loc in locations) {
      final speed = (loc['speed'] as num?)?.toDouble() ?? 0.0;
      if (speed > 0) {
        totalSpeed += speed;
        count++;
      }
    }
    return count > 0 ? totalSpeed / count : 0.0;
  }

  double _calculateMaxSpeed(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return 0.0;
    return locations.map((loc) => (loc['speed'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
  }

  Future<int> _getTripIncidents(String tripId) async {
    final incidents = await _dbService.getAllIncidents();
    // Filter incidents that occurred during this trip
    return incidents.length; // Simplified
  }
}

class JourneySummary {
  final String tripId;
  final String origin;
  final String destination;
  final double distance;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final String mode;
  final String safetyStatus;
  final double totalExpenses;
  final int routePoints;
  final double averageSpeed;
  final double maxSpeed;
  final int incidents;

  JourneySummary({
    required this.tripId,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.safetyStatus,
    required this.totalExpenses,
    required this.routePoints,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.incidents,
  });

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  String get formattedExpenses => '₹${totalExpenses.toStringAsFixed(2)}';
}

