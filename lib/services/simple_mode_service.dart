// lib/services/simple_mode_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SimpleModeService {
  static final SimpleModeService _instance = SimpleModeService._internal();
  factory SimpleModeService() => _instance;
  SimpleModeService._internal();

  static const String _simpleModeKey = 'simple_mode_enabled';

  // Essential features only - Important buttons for simple mode
  static const List<String> essentialFeatures = [
    'Emergency Report',
    'Report',
    // Fake Call removed - not a real safety feature
    'Woman Safety',
    'Child Safety',
    'Safe Zones',
    'Driving Mode',
    'New Trip',
    'Navigation',
  ];

  // All features
  static const List<String> allFeatures = [
    'New Trip',
    'SOS Button',
    'Emergency Contacts',
    'Safe Zones',
    'Woman Safety',
    'Child Safety',
    'Driving Mode',
    'Navigation',
    'Book Transport',
    'AI Copilot',
    'Hotels',
    'Rewards',
    'Explore VR',
    'Tourism',
    'Emergency Report',
    'Report',
    'Carbon Footprint',
    'Scan Receipt',
    'Student',
    'Data Export',
    'Analytics',
    // Fake Call removed - not a real safety feature
  ];

  Future<bool> isSimpleModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_simpleModeKey) ?? false;
  }

  Future<void> setSimpleMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simpleModeKey, enabled);
  }

  Future<List<String>> getAvailableFeatures() async {
    final isSimple = await isSimpleModeEnabled();
    return isSimple ? essentialFeatures : allFeatures;
  }

  bool isFeatureAvailable(String feature, List<String> availableFeatures) {
    return availableFeatures.contains(feature);
  }
}

