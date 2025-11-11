// lib/models/models.dart
import 'package:flutter/material.dart';

class Trip {
  final String title;
  final String mode;
  final double distance;
  final String duration;
  final String time;
  final String destination;
  final IconData icon;
  final bool isCompleted;
  final String companions;
  final String purpose;
  final String notes;
  final Color color;
  final List<RoutePoint>? routePoints; // Real GPS coordinates
  final RoutePoint? startLocation;
  final RoutePoint? endLocation;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? tripId; // Unique identifier for the trip

  Trip({
    required this.title,
    required this.mode,
    required this.distance,
    required this.duration,
    required this.time,
    required this.destination,
    required this.icon,
    this.isCompleted = false,
    required this.companions,
    required this.purpose,
    required this.notes,
    required this.color,
    this.routePoints,
    this.startLocation,
    this.endLocation,
    this.startTime,
    this.endTime,
    this.tripId,
  });
}

class PlannedTrip {
  final String origin;
  final String destination;
  final String time;
  final int passengers;
  final DateTime createdAt;
  final List<RoutePoint>? plannedRoute;
  final String? vehicleType;
  final String? price; // Extracted price from ticket

  PlannedTrip({
    required this.origin,
    required this.destination,
    required this.time,
    required this.passengers,
    DateTime? createdAt,
    this.plannedRoute,
    this.vehicleType,
    this.price,
  }) : createdAt = createdAt ?? DateTime.now();
}

class RoutePoint {
  final double latitude;
  final double longitude;

  RoutePoint({required this.latitude, required this.longitude});
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.isPrimary = false,
  });
}

class BlogArticle {
  final String title;
  final String author;
  final String imageUrl;

  BlogArticle({required this.title, required this.author, required this.imageUrl});
}

class TravelPackage {
  final String title;
  final String price;
  final String imageUrl;
  final double rating;

  TravelPackage({required this.title, required this.price, required this.imageUrl, required this.rating});
}

class VideoPost {
  final String username;
  final String userAvatarUrl;
  final String videoUrl;
  final String caption;
  final String likes;
  final String comments;
  final String shares;
  final String location;
  final List<String> tags;

  VideoPost({
    required this.username,
    required this.userAvatarUrl,
    required this.videoUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.location,
    required this.tags,
  });
}

class CommunityTrip {
  final String title;
  final String author;
  final String date;
  final String participants;
  final String description;
  final List<String> tags;
  final String difficulty;
  final String avatarLetter;

  CommunityTrip({
    required this.title,
    required this.author,
    required this.date,
    required this.participants,
    required this.description,
    required this.tags,
    required this.difficulty,
    required this.avatarLetter,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class Achievement {
    final String title;
    final String description;
    final IconData icon;
    final bool isUnlocked;

    Achievement({
        required this.title,
        required this.description,
        required this.icon,
        required this.isUnlocked,
    });
}

class SafeZone {
  final String name;
  final double latitude;
  final double longitude;
  final String type;
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
  final String type;
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

class DriverInfo {
  final String name;
  final String vehicleNumber;
  final String phoneNumber;
  final double rating;
  final int totalRides;
  final bool isVerified;
  final String? photoUrl;

  DriverInfo({
    required this.name,
    required this.vehicleNumber,
    required this.phoneNumber,
    required this.rating,
    required this.totalRides,
    this.isVerified = false,
    this.photoUrl,
  });
}