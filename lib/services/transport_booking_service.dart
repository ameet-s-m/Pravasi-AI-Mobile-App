// lib/services/transport_booking_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

class TransportBookingService {
  static final TransportBookingService _instance =
      TransportBookingService._internal();
  factory TransportBookingService() => _instance;
  TransportBookingService._internal();

  Future<List<TransportOption>> getTransportOptions({
    required Position origin,
    required Position destination,
    required DateTime departureTime,
    String? extractedPrice,
    String? vehicleType,
  }) async {
    final distance =
        Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ) /
        1000; // Convert to km

    // Generate MakeMyTrip-style transport options
    // In production, this would call MakeMyTrip API
    final options = _generateMakeMyTripOptions(
      distance: distance,
      extractedPrice: extractedPrice,
      vehicleType: vehicleType,
    );

    // Sort by price (cheapest first) - default behavior
    options.sort((a, b) => a.price.compareTo(b.price));
    return options;
  }

  List<TransportOption> _generateMakeMyTripOptions({
    required double distance,
    String? extractedPrice,
    String? vehicleType,
  }) {
    final options = <TransportOption>[];

    // Bus Options (Multiple providers like MakeMyTrip)
    options.addAll([
      TransportOption(
        type: 'Bus',
        price: distance * 4.5, // ₹4.5 per km - cheapest
        duration: Duration(minutes: (distance / 0.5).round()),
        distance: distance,
        provider: 'MakeMyTrip Bus',
        rating: 4.3,
        available: true,
        amenities: ['AC', 'WiFi', 'Charging', 'Reclining Seats'],
      ),
      TransportOption(
        type: 'Bus',
        price: distance * 5.5, // ₹5.5 per km
        duration: Duration(minutes: (distance / 0.5).round()),
        distance: distance,
        provider: 'RedBus',
        rating: 4.5,
        available: true,
        amenities: ['AC', 'WiFi', 'Charging', 'Reclining Seats', 'Blanket'],
      ),
      TransportOption(
        type: 'Bus',
        price: distance * 6.0, // ₹6.0 per km
        duration: Duration(minutes: (distance / 0.5).round()),
        distance: distance,
        provider: 'AbhiBus',
        rating: 4.2,
        available: true,
        amenities: ['AC', 'WiFi', 'Charging'],
      ),
      TransportOption(
        type: 'Bus',
        price: distance * 7.0, // ₹7.0 per km - premium
        duration: Duration(minutes: (distance / 0.5).round()),
        distance: distance,
        provider: 'MakeMyTrip Premium',
        rating: 4.7,
        available: true,
        amenities: ['AC', 'WiFi', 'Charging', 'Reclining Seats', 'Blanket', 'Meals'],
      ),
    ]);

    // Train Options
    options.addAll([
      TransportOption(
        type: 'Train',
        price: distance * 1.8, // ₹1.8 per km - cheapest
        duration: Duration(minutes: (distance / 0.8).round()),
        distance: distance,
        provider: 'Indian Railways (Sleeper)',
        rating: 4.0,
        available: true,
        amenities: ['Food', 'Water', 'Berth'],
      ),
      TransportOption(
        type: 'Train',
        price: distance * 3.5, // ₹3.5 per km
        duration: Duration(minutes: (distance / 0.8).round()),
        distance: distance,
        provider: 'Indian Railways (AC 3 Tier)',
        rating: 4.3,
        available: true,
        amenities: ['AC', 'Food', 'Water', 'Berth'],
      ),
      TransportOption(
        type: 'Train',
        price: distance * 5.0, // ₹5.0 per km
        duration: Duration(minutes: (distance / 0.8).round()),
        distance: distance,
        provider: 'Indian Railways (AC 2 Tier)',
        rating: 4.5,
        available: true,
        amenities: ['AC', 'Food', 'Water', 'Berth', 'Bedding'],
      ),
      TransportOption(
        type: 'Train',
        price: distance * 8.0, // ₹8.0 per km - premium
        duration: Duration(minutes: (distance / 0.8).round()),
        distance: distance,
        provider: 'Indian Railways (AC First)',
        rating: 4.7,
        available: true,
        amenities: ['AC', 'Food', 'Water', 'Private Berth', 'Bedding', 'Meals'],
      ),
    ]);

    // Taxi/Cab Options
    options.addAll([
      TransportOption(
        type: 'Taxi',
        price: 50 + (distance * 10), // Base + ₹10 per km
        duration: Duration(minutes: (distance / 0.6).round()),
        distance: distance,
        provider: 'MakeMyTrip Cabs',
        rating: 4.2,
        available: true,
        amenities: ['AC', 'Direct', 'Driver'],
      ),
      TransportOption(
        type: 'Taxi',
        price: 60 + (distance * 12), // Base + ₹12 per km
        duration: Duration(minutes: (distance / 0.6).round()),
        distance: distance,
        provider: 'Ola',
        rating: 4.4,
        available: true,
        amenities: ['AC', 'Direct', 'Driver', 'GPS'],
      ),
      TransportOption(
        type: 'Taxi',
        price: 70 + (distance * 13), // Base + ₹13 per km
        duration: Duration(minutes: (distance / 0.6).round()),
        distance: distance,
        provider: 'Uber',
        rating: 4.5,
        available: true,
        amenities: ['AC', 'Direct', 'Driver', 'GPS', 'Premium'],
      ),
    ]);

    // Auto Rickshaw
    options.add(TransportOption(
      type: 'Auto',
      price: 30 + (distance * 7), // Base + ₹7 per km - cheapest
      duration: Duration(minutes: (distance / 0.4).round()),
      distance: distance,
      provider: 'Local Auto',
      rating: 3.8,
      available: true,
      amenities: ['Economical', 'Direct'],
    ));

    // Flight (for long distances)
    if (distance > 200) {
      options.add(TransportOption(
        type: 'Flight',
        price: 2000 + (distance * 8), // Base + ₹8 per km
        duration: Duration(minutes: (distance / 8).round() + 60),
        distance: distance,
        provider: 'MakeMyTrip Flights',
        rating: 4.7,
        available: true,
        amenities: ['Fast', 'Comfort', 'Meals', 'Entertainment'],
      ));
    }

    // Apply extracted price if available
    if (extractedPrice != null && vehicleType != null) {
      final extractedPriceNum = double.tryParse(extractedPrice);
      if (extractedPriceNum != null) {
        for (var i = 0; i < options.length; i++) {
          final vehicleTypeUpper = vehicleType.toUpperCase();
          final optionTypeUpper = options[i].type.toUpperCase();
          
          if ((vehicleTypeUpper.contains('BUS') && optionTypeUpper == 'BUS') ||
              (vehicleTypeUpper.contains('TRAIN') && optionTypeUpper == 'TRAIN') ||
              ((vehicleTypeUpper.contains('CAR') || vehicleTypeUpper.contains('TAXI')) && 
               (optionTypeUpper == 'TAXI' || optionTypeUpper == 'AUTO'))) {
            // Adjust price to match extracted price
            options[i] = TransportOption(
              type: options[i].type,
              price: extractedPriceNum,
              duration: options[i].duration,
              distance: options[i].distance,
              provider: options[i].provider,
              rating: options[i].rating,
              available: options[i].available,
              amenities: options[i].amenities,
            );
          }
        }
      }
    }

    return options;
  }


  Future<BookingConfirmation> bookTransport(TransportOption option) async {
    // Simulate booking process
    await Future.delayed(const Duration(seconds: 2));

    return BookingConfirmation(
      bookingId: 'BK${DateTime.now().millisecondsSinceEpoch}',
      transportOption: option,
      bookingTime: DateTime.now(),
      status: 'Confirmed',
      qrCode: 'QR_CODE_DATA',
    );
  }

  List<TransportOption> getCheapestOptions(List<TransportOption> options) {
    if (options.isEmpty) return [];
    final cheapestPrice = options.map((o) => o.price).reduce(math.min);
    return options.where((o) => o.price == cheapestPrice).toList();
  }

  List<TransportOption> getFastestOptions(List<TransportOption> options) {
    if (options.isEmpty) return [];
    final fastestDuration = options
        .map((o) => o.duration.inMinutes)
        .reduce(math.min);
    return options
        .where((o) => o.duration.inMinutes == fastestDuration)
        .toList();
  }

  List<TransportOption> getBestRatedOptions(List<TransportOption> options) {
    if (options.isEmpty) return [];
    final bestRating = options.map((o) => o.rating).reduce(math.max);
    return options.where((o) => o.rating == bestRating).toList();
  }

  Future<String> getAddressFromLocation(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty) parts.add(place.country!);
        return parts.isNotEmpty ? parts.join(', ') : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
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
    throw Exception('Could not find location for: $address');
  }
}

class TransportOption {
  final String type;
  final double price;
  final Duration duration;
  final double distance;
  final String provider;
  final double rating;
  final bool available;
  final List<String> amenities;

  TransportOption({
    required this.type,
    required this.price,
    required this.duration,
    required this.distance,
    required this.provider,
    required this.rating,
    required this.available,
    required this.amenities,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class BookingConfirmation {
  final String bookingId;
  final TransportOption transportOption;
  final DateTime bookingTime;
  final String status;
  final String qrCode;

  BookingConfirmation({
    required this.bookingId,
    required this.transportOption,
    required this.bookingTime,
    required this.status,
    required this.qrCode,
  });
}
