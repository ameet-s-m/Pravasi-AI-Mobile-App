// lib/services/family_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  List<FamilyMember> _members = [];
  String? _currentProfile;

  Future<void> initialize() async {
    await _loadMembers();
    await _loadCurrentProfile();
  }

  Future<void> _loadMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = prefs.getString('family_members');
    if (membersJson != null) {
      final List<dynamic> decoded = jsonDecode(membersJson);
      _members = decoded.map((m) => FamilyMember.fromJson(m)).toList();
    }
  }

  Future<void> _loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _currentProfile = prefs.getString('current_profile') ?? 'personal';
  }

  Future<void> addMember(FamilyMember member) async {
    _members.add(member);
    await _saveMembers();
  }

  Future<void> removeMember(String memberId) async {
    _members.removeWhere((m) => m.id == memberId);
    await _saveMembers();
  }

  Future<void> _saveMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = jsonEncode(_members.map((m) => m.toJson()).toList());
    await prefs.setString('family_members', membersJson);
  }

  Future<void> switchProfile(String profileId) async {
    _currentProfile = profileId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_profile', profileId);
  }

  List<FamilyMember> getMembers() => _members;
  String? getCurrentProfile() => _currentProfile;
  
  FamilyMember? getMember(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}

class FamilyMember {
  final String id;
  final String name;
  final String relationship; // parent, child, spouse, etc.
  final String? phoneNumber;
  final String? email;
  final DateTime? dateOfBirth;
  final Map<String, dynamic>? preferences;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.preferences,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'phoneNumber': phoneNumber,
    'email': email,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'preferences': preferences,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    relationship: json['relationship'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    email: json['email'] as String?,
    dateOfBirth: json['dateOfBirth'] != null 
        ? DateTime.parse(json['dateOfBirth'] as String)
        : null,
    preferences: json['preferences'] as Map<String, dynamic>?,
  );
}

