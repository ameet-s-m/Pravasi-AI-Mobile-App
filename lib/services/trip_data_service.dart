// lib/services/trip_data_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class TripDataService {
  static final TripDataService _instance = TripDataService._internal();
  factory TripDataService() => _instance;
  TripDataService._internal();

  static const String _tripsKey = 'user_trips';
  static const String _plannedTripsKey = 'planned_trips';
  static const String _chatMessagesKey = 'chat_messages';
  static const String _achievementsKey = 'achievements';

  List<Trip> _trips = [];
  List<PlannedTrip> _plannedTrips = [];
  List<ChatMessage> _chatMessages = [];
  List<Achievement> _achievements = [];

  // Initialize with welcome message
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    await loadTrips();
    await loadPlannedTrips();
    await loadChatMessages();
    await loadAchievements();
    
    // Add welcome message if no messages exist
    if (_chatMessages.isEmpty) {
      _chatMessages.add(
        ChatMessage(
          isUser: false,
          text: 'Hello! I\'m your travel assistant. I can help you track trips, analyze your travel patterns, and connect with fellow travelers. What would you like to do today?',
          time: DateTime.now().toString().substring(11, 16),
        ),
      );
      await saveChatMessages();
    }
    
    _initialized = true;
  }

  // ========== TRIPS ==========
  Future<void> addTrip(Trip trip) async {
    _trips.insert(0, trip); // Add to beginning
    await saveTrips();
  }

  Future<void> updateTrip(int index, Trip trip) async {
    if (index >= 0 && index < _trips.length) {
      _trips[index] = trip;
      await saveTrips();
    }
  }

  Future<void> updateTripById(String tripId, Trip trip) async {
    final index = _trips.indexWhere((t) => t.tripId == tripId);
    if (index >= 0) {
      await updateTrip(index, trip);
    }
  }

  Future<void> deleteTrip(int index) async {
    if (index >= 0 && index < _trips.length) {
      _trips.removeAt(index);
      await saveTrips();
    }
  }

  List<Trip> getTrips() => List.unmodifiable(_trips);

  Trip? getTripById(String tripId) {
    try {
      return _trips.firstWhere((trip) => trip.tripId == tripId);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = prefs.getString(_tripsKey);
      
      if (tripsJson != null && tripsJson.isNotEmpty) {
        final List<dynamic> tripsList = jsonDecode(tripsJson);
        _trips = tripsList.map((json) => _tripFromJson(json)).toList();
      } else {
        _trips = [];
      }
    } catch (e) {
      print('Error loading trips: $e');
      _trips = [];
    }
  }

  Future<void> saveTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = jsonEncode(_trips.map((trip) => _tripToJson(trip)).toList());
      await prefs.setString(_tripsKey, tripsJson);
    } catch (e) {
      print('Error saving trips: $e');
    }
  }

  Map<String, dynamic> _tripToJson(Trip trip) {
    return {
      'title': trip.title,
      'mode': trip.mode,
      'distance': trip.distance,
      'duration': trip.duration,
      'time': trip.time,
      'destination': trip.destination,
      'icon': trip.icon.codePoint,
      'isCompleted': trip.isCompleted,
      'companions': trip.companions,
      'purpose': trip.purpose,
      'notes': trip.notes,
      'color': trip.color.value,
      'routePoints': trip.routePoints?.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
      'startLocation': trip.startLocation != null ? {
        'latitude': trip.startLocation!.latitude,
        'longitude': trip.startLocation!.longitude,
      } : null,
      'endLocation': trip.endLocation != null ? {
        'latitude': trip.endLocation!.latitude,
        'longitude': trip.endLocation!.longitude,
      } : null,
      'startTime': trip.startTime?.toIso8601String(),
      'endTime': trip.endTime?.toIso8601String(),
      'tripId': trip.tripId,
    };
  }

  Trip _tripFromJson(Map<String, dynamic> json) {
    return Trip(
      title: json['title'] ?? '',
      mode: json['mode'] ?? 'car',
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      time: json['time'] ?? '',
      destination: json['destination'] ?? '',
      icon: IconData(json['icon'] ?? Icons.directions_car.codePoint, fontFamily: 'MaterialIcons'),
      isCompleted: json['isCompleted'] ?? false,
      companions: json['companions'] ?? 'Solo',
      purpose: json['purpose'] ?? '',
      notes: json['notes'] ?? '',
      color: Color(json['color'] ?? Colors.blue.value),
      routePoints: json['routePoints'] != null
          ? (json['routePoints'] as List).map((p) => RoutePoint(
              latitude: (p['latitude'] ?? 0.0).toDouble(),
              longitude: (p['longitude'] ?? 0.0).toDouble(),
            )).toList()
          : null,
      startLocation: json['startLocation'] != null
          ? RoutePoint(
              latitude: (json['startLocation']['latitude'] ?? 0.0).toDouble(),
              longitude: (json['startLocation']['longitude'] ?? 0.0).toDouble(),
            )
          : null,
      endLocation: json['endLocation'] != null
          ? RoutePoint(
              latitude: (json['endLocation']['latitude'] ?? 0.0).toDouble(),
              longitude: (json['endLocation']['longitude'] ?? 0.0).toDouble(),
            )
          : null,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      tripId: json['tripId'],
    );
  }

  // ========== PLANNED TRIPS ==========
  Future<void> addPlannedTrip(PlannedTrip trip) async {
    _plannedTrips.insert(0, trip);
    await savePlannedTrips();
  }

  Future<void> deletePlannedTrip(int index) async {
    if (index >= 0 && index < _plannedTrips.length) {
      _plannedTrips.removeAt(index);
      await savePlannedTrips();
    }
  }

  List<PlannedTrip> getPlannedTrips() => List.unmodifiable(_plannedTrips);

  Future<void> loadPlannedTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = prefs.getString(_plannedTripsKey);
      
      if (tripsJson != null && tripsJson.isNotEmpty) {
        final List<dynamic> tripsList = jsonDecode(tripsJson);
        _plannedTrips = tripsList.map((json) => _plannedTripFromJson(json)).toList();
      } else {
        _plannedTrips = [];
      }
    } catch (e) {
      print('Error loading planned trips: $e');
      _plannedTrips = [];
    }
  }

  Future<void> savePlannedTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = jsonEncode(_plannedTrips.map((trip) => _plannedTripToJson(trip)).toList());
      await prefs.setString(_plannedTripsKey, tripsJson);
    } catch (e) {
      print('Error saving planned trips: $e');
    }
  }

  Map<String, dynamic> _plannedTripToJson(PlannedTrip trip) {
    return {
      'origin': trip.origin,
      'destination': trip.destination,
      'time': trip.time,
      'passengers': trip.passengers,
      'createdAt': trip.createdAt.toIso8601String(),
      'vehicleType': trip.vehicleType,
      'price': trip.price,
      'plannedRoute': trip.plannedRoute?.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
    };
  }

  PlannedTrip _plannedTripFromJson(Map<String, dynamic> json) {
    return PlannedTrip(
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      time: json['time'] ?? '',
      passengers: json['passengers'] ?? 1,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      vehicleType: json['vehicleType'],
      price: json['price'],
      plannedRoute: json['plannedRoute'] != null
          ? (json['plannedRoute'] as List).map((p) => RoutePoint(
              latitude: (p['latitude'] ?? 0.0).toDouble(),
              longitude: (p['longitude'] ?? 0.0).toDouble(),
            )).toList()
          : null,
    );
  }

  // ========== CHAT MESSAGES ==========
  Future<void> addChatMessage(ChatMessage message) async {
    _chatMessages.add(message);
    await saveChatMessages();
  }

  List<ChatMessage> getChatMessages() => List.unmodifiable(_chatMessages);

  Future<void> clearChatMessages() async {
    _chatMessages.clear();
    await saveChatMessages();
  }

  Future<void> loadChatMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_chatMessagesKey);
      
      if (messagesJson != null && messagesJson.isNotEmpty) {
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        _chatMessages = messagesList.map((json) => ChatMessage(
          isUser: json['isUser'] ?? false,
          text: json['text'] ?? '',
          time: json['time'] ?? '',
        )).toList();
      } else {
        _chatMessages = [];
      }
    } catch (e) {
      print('Error loading chat messages: $e');
      _chatMessages = [];
    }
  }

  Future<void> saveChatMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = jsonEncode(_chatMessages.map((msg) => {
        'isUser': msg.isUser,
        'text': msg.text,
        'time': msg.time,
      }).toList());
      await prefs.setString(_chatMessagesKey, messagesJson);
    } catch (e) {
      print('Error saving chat messages: $e');
    }
  }

  // ========== ACHIEVEMENTS ==========
  Future<void> updateAchievement(String title, bool isUnlocked) async {
    final index = _achievements.indexWhere((a) => a.title == title);
    if (index >= 0) {
      _achievements[index] = Achievement(
        title: _achievements[index].title,
        description: _achievements[index].description,
        icon: _achievements[index].icon,
        isUnlocked: isUnlocked,
      );
      await saveAchievements();
    }
  }

  List<Achievement> getAchievements() {
    // Initialize default achievements if empty
    if (_achievements.isEmpty) {
      _achievements = [
        Achievement(
          title: 'Data Pioneer',
          description: '1000+ data points collected',
          icon: Icons.data_exploration,
          isUnlocked: false,
        ),
        Achievement(
          title: 'Distance Master',
          description: 'Traveled 5000+ km',
          icon: Icons.social_distance,
          isUnlocked: false,
        ),
        Achievement(
          title: 'Community Leader',
          description: 'Helped 50+ researchers',
          icon: Icons.group_add,
          isUnlocked: false,
        ),
        Achievement(
          title: 'Survey Expert',
          description: 'Completed 100+ surveys',
          icon: Icons.poll,
          isUnlocked: false,
        ),
      ];
    }
    return List.unmodifiable(_achievements);
  }

  Future<void> loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      
      if (achievementsJson != null && achievementsJson.isNotEmpty) {
        final List<dynamic> achievementsList = jsonDecode(achievementsJson);
        _achievements = achievementsList.map((json) => Achievement(
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          icon: IconData(json['icon'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons'),
          isUnlocked: json['isUnlocked'] ?? false,
        )).toList();
      } else {
        _achievements = [];
      }
    } catch (e) {
      print('Error loading achievements: $e');
      _achievements = [];
    }
  }

  Future<void> saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = jsonEncode(_achievements.map((a) => {
        'title': a.title,
        'description': a.description,
        'icon': a.icon.codePoint,
        'isUnlocked': a.isUnlocked,
      }).toList());
      await prefs.setString(_achievementsKey, achievementsJson);
    } catch (e) {
      print('Error saving achievements: $e');
    }
  }

  // ========== STATISTICS ==========
  Map<String, dynamic> getStatistics() {
    final today = DateTime.now();
    final todayTrips = _trips.where((trip) {
      // Parse time if possible, or check if trip was created today
      return trip.time.contains(today.toString().substring(5, 10));
    }).toList();

    double totalDistance = _trips.fold(0.0, (sum, trip) => sum + trip.distance);
    double totalHours = _trips.fold(0.0, (sum, trip) {
      final duration = trip.duration;
      if (duration.contains('h')) {
        final parts = duration.split('h');
        final hours = double.tryParse(parts[0].trim()) ?? 0.0;
        final minutes = parts.length > 1 
            ? (double.tryParse(parts[1].replaceAll('m', '').trim()) ?? 0.0) / 60.0
            : 0.0;
        return sum + hours + minutes;
      } else if (duration.contains('m')) {
        return sum + (double.tryParse(duration.replaceAll('m', '').trim()) ?? 0.0) / 60.0;
      }
      return sum;
    });

    return {
      'tripsToday': todayTrips.length,
      'totalDistance': totalDistance,
      'totalHours': totalHours,
      'totalTrips': _trips.length,
    };
  }
}

