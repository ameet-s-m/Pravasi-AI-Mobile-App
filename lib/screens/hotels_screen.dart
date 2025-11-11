// lib/screens/hotels_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../services/hotel_service.dart';

class HotelsScreen extends StatefulWidget {
  final Position? location;
  const HotelsScreen({super.key, this.location});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  final HotelService _hotelService = HotelService();
  List<Hotel> _hotels = [];
  bool _isLoading = true;
  String _sortBy = 'distance';

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    Position? location = widget.location;
    if (location == null) {
      try {
        location = await Geolocator.getCurrentPosition();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    final hotels = await _hotelService.findNearbyHotels(location);
    setState(() {
      _hotels = _sortHotels(hotels);
      _isLoading = false;
    });
  }

  List<Hotel> _sortHotels(List<Hotel> hotels) {
    switch (_sortBy) {
      case 'price':
        return hotels..sort((a, b) => a.price.compareTo(b.price));
      case 'rating':
        return hotels..sort((a, b) => b.rating.compareTo(a.rating));
      case 'distance':
      default:
        return hotels..sort((a, b) => a.distance.compareTo(b.distance));
    }
  }

  Future<void> _bookHotel(Hotel hotel) async {
    final checkIn = DateTime.now().add(const Duration(days: 1));
    final checkOut = checkIn.add(const Duration(days: 1));

    try {
      final confirmation = await _hotelService.bookHotel(
        hotel.id,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: 1,
      );

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Booking Confirmed'),
            content: Text(
              'Hotel: ${hotel.name}\n'
              'Booking ID: ${confirmation.bookingId}\n'
              'Total: ₹${confirmation.totalPrice.toStringAsFixed(0)}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Booking Failed'),
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Nearby Hotels'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                title: const Text('Sort By'),
                actions: [
                  CupertinoActionSheetAction(
                    child: const Text('Distance'),
                    onPressed: () {
                      setState(() {
                        _sortBy = 'distance';
                        _hotels = _sortHotels(_hotels);
                      });
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoActionSheetAction(
                    child: const Text('Price (Lowest)'),
                    onPressed: () {
                      setState(() {
                        _sortBy = 'price';
                        _hotels = _sortHotels(_hotels);
                      });
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoActionSheetAction(
                    child: const Text('Rating (Highest)'),
                    onPressed: () {
                      setState(() {
                        _sortBy = 'rating';
                        _hotels = _sortHotels(_hotels);
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          },
          child: const Icon(CupertinoIcons.sort_down),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_hotels.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No hotels found nearby'),
                    ),
                  )
                else
                  ..._hotels.map((hotel) => _buildHotelCard(hotel)),
              ],
            ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 16,
                          color: CupertinoColors.systemYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hotel.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        const Icon(CupertinoIcons.location, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${hotel.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hotel.formattedPrice,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: hotel.amenities.map((amenity) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                amenity,
                style: const TextStyle(fontSize: 12),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          CupertinoButton.filled(
            onPressed: () => _bookHotel(hotel),
            child: const Text('Book Hotel'),
          ),
        ],
      ),
    );
  }
}

