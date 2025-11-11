// lib/services/weather_service.dart
import 'package:geolocator/geolocator.dart';
import 'mock_service.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  Function(WeatherAlert)? onWeatherAlert;

  Future<WeatherInfo> getWeather(Position location) async {
    // Use mock service for demo (can be replaced with real API)
    final mockService = MockService();
    final weatherData = await mockService.getMockWeather(
      location.latitude,
      location.longitude,
    );
    
    return WeatherInfo(
      temperature: weatherData['temperature'] as double,
      condition: weatherData['condition'] as String,
      humidity: weatherData['humidity'] as double? ?? 65.0,
      windSpeed: weatherData['windSpeed'] as double,
      location: location,
      timestamp: DateTime.now(),
    );
  }

  Future<void> checkWeatherAlerts(Position location) async {
    final weather = await getWeather(location);
    
    // Check for severe weather
    if (weather.condition == 'Rainy' && weather.temperature < 20) {
      onWeatherAlert?.call(WeatherAlert(
        type: 'Rain',
        severity: 'Moderate',
        message: 'Heavy rain expected. Travel safely.',
        location: location,
      ));
    }
    
    if (weather.temperature > 35) {
      onWeatherAlert?.call(WeatherAlert(
        type: 'Heat',
        severity: 'High',
        message: 'Extreme heat warning. Stay hydrated.',
        location: location,
      ));
    }
  }

  Future<List<TravelAdvisory>> getTravelAdvisories(Position location) async {
    // In real app, fetch from government/advisory APIs
    return [
      TravelAdvisory(
        type: 'Safety',
        title: 'Travel Advisory',
        message: 'Exercise caution in this area after dark',
        severity: 'Moderate',
        location: location,
      ),
    ];
  }
}

class WeatherInfo {
  final double temperature;
  final String condition;
  final double humidity;
  final double windSpeed;
  final Position location;
  final DateTime timestamp;

  WeatherInfo({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.location,
    required this.timestamp,
  });

  String get formattedTemp => '${temperature.toStringAsFixed(0)}°C';
}

class WeatherAlert {
  final String type;
  final String severity;
  final String message;
  final Position location;

  WeatherAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.location,
  });
}

class TravelAdvisory {
  final String type;
  final String title;
  final String message;
  final String severity;
  final Position location;

  TravelAdvisory({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.location,
  });
}

