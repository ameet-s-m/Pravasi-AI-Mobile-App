// lib/services/community_safety_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CommunitySafetyService {
  static final CommunitySafetyService _instance = CommunitySafetyService._internal();
  factory CommunitySafetyService() => _instance;
  CommunitySafetyService._internal();

  final List<SafeZone> _safeZones = [];
  final List<IncidentReport> _incidentReports = [];
  final List<CommunityMember> _nearbyMembers = [];

  Future<void> addSafeZone(SafeZone zone) async {
    _safeZones.add(zone);
    final prefs = await SharedPreferences.getInstance();
    // Store safe zones
  }

  Future<void> reportIncident(IncidentReport incident) async {
    _incidentReports.add(incident);
    // Notify nearby community members
    _notifyNearbyMembers(incident);
  }

  List<SafeZone> getNearbySafeZones(Position position, {double radiusKm = 5.0}) {
    // Only return real user-added safe zones - no demo data
    if (_safeZones.isEmpty) {
      return []; // Return empty list instead of demo zones
    }
    
    // Legacy demo zones removed - uncomment only for testing
    /* if (_safeZones.isEmpty) {
      return [
        SafeZone(
          name: 'Central Police Station',
          latitude: position.latitude + 0.01,
          longitude: position.longitude + 0.01,
          type: 'police_station',
          description: '24/7 police station with emergency services. Safe place to report incidents.',
          rating: 4.8,
        ),
        SafeZone(
          name: 'City General Hospital',
          latitude: position.latitude - 0.01,
          longitude: position.longitude + 0.015,
          type: 'hospital',
          description: 'Full-service hospital with emergency department. Open 24/7.',
          rating: 4.6,
        ),
        SafeZone(
          name: 'Women\'s Safety Center',
          latitude: position.latitude + 0.008,
          longitude: position.longitude - 0.012,
          type: 'safe_house',
          description: 'Dedicated safe space for women. Provides counseling and emergency shelter.',
          rating: 4.9,
        ),
        SafeZone(
          name: 'Community Help Center',
          latitude: position.latitude - 0.015,
          longitude: position.longitude - 0.008,
          type: 'safe_house',
          description: 'Community-run safe zone. Volunteers available to help.',
          rating: 4.7,
        ),
        SafeZone(
          name: 'Metro Station Security Office',
          latitude: position.latitude + 0.012,
          longitude: position.longitude + 0.008,
          type: 'police_station',
          description: 'Security office at metro station. Staffed during operational hours.',
          rating: 4.5,
        ),
      ];
    } */
    
    return _safeZones.where((zone) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      ) / 1000; // Convert to km
      return distance <= radiusKm;
    }).toList();
  }

  List<IncidentReport> getRecentIncidents({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _incidentReports.where((incident) => 
      incident.timestamp.isAfter(cutoff)
    ).toList();
  }

  void _notifyNearbyMembers(IncidentReport incident) {
    // In real implementation, use Firebase Cloud Messaging
    // to notify nearby community members
  }

  Future<void> shareLocationWithCommunity(Position position) async {
    // Share location with trusted community members
  }

  List<SafeZone> get safeZones => _safeZones;
  List<IncidentReport> get incidentReports => _incidentReports;
}

class SafeZone {
  final String name;
  final double latitude;
  final double longitude;
  final String type; // police_station, hospital, safe_house, etc.
  final String description;
  final double rating;

  SafeZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    this.rating = 5.0,
  });
}

class IncidentReport {
  final String id;
  final double latitude;
  final double longitude;
  final String type; // harassment, theft, assault, etc.
  final String description;
  final DateTime timestamp;
  final String? reporterId;

  IncidentReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    DateTime? timestamp,
    this.reporterId,
  }) : timestamp = timestamp ?? DateTime.now();
}

class CommunityMember {
  final String id;
  final String name;
  final Position? position;
  final bool isOnline;
  final DateTime? lastSeen;

  CommunityMember({
    required this.id,
    required this.name,
    this.position,
    this.isOnline = false,
    this.lastSeen,
  });
}

