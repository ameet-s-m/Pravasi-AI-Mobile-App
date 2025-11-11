// lib/services/navigation_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  Future<NavigationRoute> getRoute({
    required Position origin,
    required Position destination,
    required String mode, // driving, walking, transit
  }) async {
    // In real app, use Google Directions API or Mapbox
    // For demo, calculate straight-line route with waypoints
    
    final distance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    final duration = _calculateDuration(distance, mode);
    
    // Generate realistic waypoints for route (not straight line)
    final waypoints = _generateWaypoints(origin, destination, 10);
    
    return NavigationRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      distance: distance / 1000, // Convert to km
      duration: duration,
      mode: mode,
      instructions: _generateInstructions(waypoints),
    );
  }

  List<Position> _generateWaypoints(Position origin, Position destination, int count) {
    final waypoints = <Position>[];
    final distance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    
    // For realistic routes, add intermediate waypoints that simulate road paths
    // Add more waypoints for longer distances
    final numWaypoints = (distance / 5000).ceil().clamp(5, 20); // One waypoint every ~5km, min 5, max 20
    
    for (int i = 1; i < numWaypoints; i++) {
      final ratio = i / numWaypoints;
      
      // Add slight curve to simulate road paths (not straight line)
      final curveOffset = (i % 2 == 0 ? 1 : -1) * 0.001 * (1 - (ratio - 0.5).abs() * 2);
      
      final lat = origin.latitude + (destination.latitude - origin.latitude) * ratio + curveOffset;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * ratio + curveOffset;
      
      waypoints.add(Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ));
    }
    return waypoints;
  }

  Duration _calculateDuration(double distanceMeters, String mode) {
    double speedKmh;
    switch (mode) {
      case 'driving':
        speedKmh = 50; // Average city speed
        break;
      case 'walking':
        speedKmh = 5;
        break;
      case 'transit':
        speedKmh = 30;
        break;
      default:
        speedKmh = 50;
    }
    
    final hours = (distanceMeters / 1000) / speedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  List<String> _generateInstructions(List<Position> waypoints) {
    return [
      'Start navigation',
      'Continue straight',
      'Turn right',
      'Continue on main road',
      'Turn left',
      'Destination ahead',
    ];
  }

  Future<String> getAddressFromLocation(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return '${position.latitude}, ${position.longitude}';
  }

  Future<Position> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
    throw Exception('Could not find location');
  }
}

class NavigationRoute {
  final Position origin;
  final Position destination;
  final List<Position> waypoints;
  final double distance; // in km
  final Duration duration;
  final String mode;
  final List<String> instructions;

  NavigationRoute({
    required this.origin,
    required this.destination,
    required this.waypoints,
    required this.distance,
    required this.duration,
    required this.mode,
    required this.instructions,
  });
}

