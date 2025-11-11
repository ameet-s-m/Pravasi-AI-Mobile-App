// lib/services/route_learning_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RouteLearningService {
  static final RouteLearningService _instance = RouteLearningService._internal();
  factory RouteLearningService() => _instance;
  RouteLearningService._internal();

  final Map<String, List<LearnedRoute>> _learnedRoutes = {};
  Function(String routeType)? onUnexpectedRoute;
  Function()? onRouteVerificationRequired;

  Future<void> learnRoute(String routeType, List<Position> positions) async {
    if (!_learnedRoutes.containsKey(routeType)) {
      _learnedRoutes[routeType] = [];
    }

    final route = LearnedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routeType: routeType,
      positions: positions,
      learnedAt: DateTime.now(),
      frequency: 1,
    );

    _learnedRoutes[routeType]!.add(route);
    await _saveRoutes();
  }

  Future<bool> isExpectedRoute(String routeType, Position currentPosition) async {
    final routes = _learnedRoutes[routeType] ?? [];
    if (routes.isEmpty) return true; // No learned routes, allow any

    // Check if current position is near any learned route
    for (var route in routes) {
      for (var pos in route.positions) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          pos.latitude,
          pos.longitude,
        );
        
        if (distance < 200) {
          // Within 200m of learned route - expected
          return true;
        }
      }
    }

    // Not near any learned route - unexpected
    return false;
  }

  Future<void> checkRouteDeviation(String routeType, Position currentPosition) async {
    final isExpected = await isExpectedRoute(routeType, currentPosition);
    
    if (!isExpected) {
      onUnexpectedRoute?.call(routeType);
      onRouteVerificationRequired?.call();
    }
  }

  Future<void> _saveRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = jsonEncode(_learnedRoutes.map((key, value) => 
      MapEntry(key, value.map((r) => r.toJson()).toList())
    ));
    await prefs.setString('learned_routes', routesJson);
  }

  Future<void> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = prefs.getString('learned_routes');
    if (routesJson != null) {
      // Load routes from storage
    }
  }

  Map<String, List<LearnedRoute>> get learnedRoutes => _learnedRoutes;
}

class LearnedRoute {
  final String id;
  final String routeType; // 'home_to_work', 'work_to_home', etc.
  final List<Position> positions;
  final DateTime learnedAt;
  int frequency;

  LearnedRoute({
    required this.id,
    required this.routeType,
    required this.positions,
    required this.learnedAt,
    this.frequency = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeType': routeType,
      'positions': positions.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList(),
      'learnedAt': learnedAt.toIso8601String(),
      'frequency': frequency,
    };
  }
}

