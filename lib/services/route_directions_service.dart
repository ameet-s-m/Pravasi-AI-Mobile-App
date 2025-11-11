// lib/services/route_directions_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class RouteDirectionsService {
  static final RouteDirectionsService _instance = RouteDirectionsService._internal();
  factory RouteDirectionsService() => _instance;
  RouteDirectionsService._internal();

  // Using free OSRM (Open Source Routing Machine) API
  // No API key required, free for use
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Get route directions between two points using OSRM API
  /// Returns a list of RoutePoints representing the route
  Future<List<RoutePoint>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // OSRM API format: /route/v1/{profile}/{coordinates}?overview=full&geometries=geojson
      final url = Uri.parse(
        '$_osrmBaseUrl/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Route request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            
            // Convert GeoJSON coordinates [lng, lat] to RoutePoints [lat, lng]
            return coordinates.map((coord) {
              return RoutePoint(
                latitude: (coord[1] as num).toDouble(),
                longitude: (coord[0] as num).toDouble(),
              );
            }).toList();
          }
        }
      }
      
      // Fallback: return simple straight-line route
      return [
        RoutePoint(latitude: startLat, longitude: startLng),
        RoutePoint(latitude: endLat, longitude: endLng),
      ];
    } catch (e) {
      print('Error getting route directions: $e');
      // Fallback: return simple straight-line route
      return [
        RoutePoint(latitude: startLat, longitude: startLng),
        RoutePoint(latitude: endLat, longitude: endLng),
      ];
    }
  }

  /// Get route with distance and duration estimates
  Future<Map<String, dynamic>> getRouteWithDetails({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Route request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final distance = route['distance'] ?? 0.0; // in meters
          final duration = route['duration'] ?? 0.0; // in seconds
          
          List<RoutePoint> routePoints = [];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            routePoints = coordinates.map((coord) {
              return RoutePoint(
                latitude: (coord[1] as num).toDouble(),
                longitude: (coord[0] as num).toDouble(),
              );
            }).toList();
          }
          
          return {
            'routePoints': routePoints,
            'distance': distance / 1000.0, // Convert to km
            'duration': Duration(seconds: duration.toInt()),
            'distanceMeters': distance,
            'durationSeconds': duration,
          };
        }
      }
      
      // Fallback
      return {
        'routePoints': [
          RoutePoint(latitude: startLat, longitude: startLng),
          RoutePoint(latitude: endLat, longitude: endLng),
        ],
        'distance': 0.0,
        'duration': Duration.zero,
        'distanceMeters': 0.0,
        'durationSeconds': 0.0,
      };
    } catch (e) {
      print('Error getting route details: $e');
      return {
        'routePoints': [
          RoutePoint(latitude: startLat, longitude: startLng),
          RoutePoint(latitude: endLat, longitude: endLng),
        ],
        'distance': 0.0,
        'duration': Duration.zero,
        'distanceMeters': 0.0,
        'durationSeconds': 0.0,
      };
    }
  }
}

