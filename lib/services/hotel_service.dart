// lib/services/hotel_service.dart
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'mock_service.dart';

class HotelService {
  static final HotelService _instance = HotelService._internal();
  factory HotelService() => _instance;
  HotelService._internal();

  List<Hotel> _hotels = [];
  Function(Hotel)? onNearbyHotel;

  Future<List<Hotel>> findNearbyHotels(
    Position location, {
    double radiusKm = 10.0,
  }) async {
    // Use mock service for demo (can be replaced with real hotel API)
    final mockService = MockService();
    final mockHotels = await mockService.getMockHotels(
      location.latitude,
      location.longitude,
    );

    _hotels = mockHotels
        .map(
          (data) => Hotel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: data['name'] as String,
            latitude:
                location.latitude + (math.Random().nextDouble() - 0.5) * 0.02,
            longitude:
                location.longitude + (math.Random().nextDouble() - 0.5) * 0.02,
            price: (data['price'] as num).toDouble(),
            rating: (data['rating'] as num).toDouble(),
            distance: (data['distance'] as num).toDouble(),
            amenities: List<String>.from(data['amenities'] as List<dynamic>),
            available: true,
          ),
        )
        .toList();

    // Also add some default hotels for variety
    _hotels.addAll([
      Hotel(
        id: '1',
        name: 'Grand Hotel',
        latitude: location.latitude + 0.01,
        longitude: location.longitude + 0.01,
        price: 2500,
        rating: 4.5,
        distance: 1.2,
        amenities: ['WiFi', 'AC', 'Pool', 'Restaurant'],
        available: true,
      ),
      Hotel(
        id: '2',
        name: 'Budget Inn',
        latitude: location.latitude - 0.01,
        longitude: location.longitude - 0.01,
        price: 800,
        rating: 3.8,
        distance: 0.8,
        amenities: ['WiFi', 'AC'],
        available: true,
      ),
      Hotel(
        id: '3',
        name: 'Luxury Suites',
        latitude: location.latitude + 0.02,
        longitude: location.longitude + 0.02,
        price: 5000,
        rating: 4.8,
        distance: 2.5,
        amenities: ['WiFi', 'AC', 'Pool', 'Spa', 'Gym', 'Restaurant'],
        available: true,
      ),
    ]);

    return _hotels.where((hotel) {
      final distance =
          Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            hotel.latitude,
            hotel.longitude,
          ) /
          1000;
      return distance <= radiusKm;
    }).toList()..sort((a, b) => a.distance.compareTo(b.distance));
  }

  Future<void> startNearbyHotelMonitoring(Position location) async {
    // Monitor for nearby hotels and alert user
    final hotels = await findNearbyHotels(location, radiusKm: 5.0);

    if (hotels.isNotEmpty) {
      final nearest = hotels.first;
      if (nearest.distance < 2.0) {
        onNearbyHotel?.call(nearest);
      }
    }
  }

  Future<BookingConfirmation> bookHotel(
    String hotelId, {
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    final hotel = _hotels.firstWhere((h) => h.id == hotelId);

    // Simulate booking
    await Future.delayed(const Duration(seconds: 2));

    return BookingConfirmation(
      bookingId: 'HTL${DateTime.now().millisecondsSinceEpoch}',
      hotel: hotel,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      totalPrice: hotel.price * checkOut.difference(checkIn).inDays,
      status: 'Confirmed',
    );
  }

  List<Hotel> getHotelsByPrice({bool ascending = true}) {
    final sorted = List<Hotel>.from(_hotels);
    sorted.sort(
      (a, b) =>
          ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price),
    );
    return sorted;
  }

  List<Hotel> getHotelsByRating({bool ascending = false}) {
    final sorted = List<Hotel>.from(_hotels);
    sorted.sort(
      (a, b) => ascending
          ? a.rating.compareTo(b.rating)
          : b.rating.compareTo(a.rating),
    );
    return sorted;
  }
}

class Hotel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double price; // per night
  final double rating;
  final double distance; // from current location in km
  final List<String> amenities;
  final bool available;

  Hotel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.rating,
    required this.distance,
    required this.amenities,
    required this.available,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)}/night';
}

class BookingConfirmation {
  final String bookingId;
  final Hotel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String status;

  BookingConfirmation({
    required this.bookingId,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.status,
  });
}
