// lib/screens/transport_booking_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/transport_booking_service.dart';

class TransportBookingScreen extends StatefulWidget {
  final Position? origin;
  final Position? destination;
  final String? extractedPrice; // Price extracted from OCR ticket
  final String? vehicleType; // Vehicle type from OCR
  const TransportBookingScreen({
    super.key,
    this.origin,
    this.destination,
    this.extractedPrice,
    this.vehicleType,
  });

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  final TransportBookingService _bookingService = TransportBookingService();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  
  List<TransportOption> _options = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _sortBy = 'price'; // Default: price (cheapest first)
  Position? _originPosition;
  Position? _destinationPosition;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    if (widget.origin != null) {
      _originPosition = widget.origin;
      try {
        final address = await _bookingService.getAddressFromLocation(_originPosition!);
        _originController.text = address;
      } catch (e) {
        _originController.text = '${_originPosition!.latitude.toStringAsFixed(6)}, ${_originPosition!.longitude.toStringAsFixed(6)}';
      }
    } else {
      // Try to get current location
      try {
        _originPosition = await Geolocator.getCurrentPosition();
        final address = await _bookingService.getAddressFromLocation(_originPosition!);
        _originController.text = address;
      } catch (e) {
        print('Could not get current location: $e');
      }
    }

    if (widget.destination != null) {
      _destinationPosition = widget.destination;
      try {
        final address = await _bookingService.getAddressFromLocation(_destinationPosition!);
        _destinationController.text = address;
      } catch (e) {
        _destinationController.text = '${_destinationPosition!.latitude.toStringAsFixed(6)}, ${_destinationPosition!.longitude.toStringAsFixed(6)}';
      }
      // Auto-load options if destination is provided
      await _searchTransport();
    }
  }

  Future<void> _searchOrigin() async {
    if (_originController.text.isEmpty) {
      // Use current location
      try {
        _originPosition = await Geolocator.getCurrentPosition();
        final address = await _bookingService.getAddressFromLocation(_originPosition!);
        setState(() {
          _originController.text = address;
        });
        if (_destinationPosition != null) {
          await _searchTransport();
        }
      } catch (e) {
        _showError('Could not get current location: $e');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _originPosition = await _bookingService.getLocationFromAddress(_originController.text);
      if (_destinationPosition != null) {
        await _searchTransport();
      }
    } catch (e) {
      _showError('Could not find origin: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchDestination() async {
    if (_destinationController.text.isEmpty) {
      _showError('Please enter a destination');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _destinationPosition = await _bookingService.getLocationFromAddress(_destinationController.text);
      if (_originPosition != null) {
        await _searchTransport();
      }
    } catch (e) {
      _showError('Could not find destination: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchTransport() async {
    // Check if positions are set, if not try to get from controllers
    if (_originPosition == null && _originController.text.isNotEmpty) {
      try {
        _originPosition = await _bookingService.getLocationFromAddress(_originController.text);
      } catch (e) {
        print('Could not get origin from text: $e');
      }
    }
    
    if (_destinationPosition == null && _destinationController.text.isNotEmpty) {
      try {
        _destinationPosition = await _bookingService.getLocationFromAddress(_destinationController.text);
      } catch (e) {
        print('Could not get destination from text: $e');
      }
    }
    
    if (_originPosition == null || _destinationPosition == null) {
      _showError('Please set both origin and destination');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    try {
      final options = await _bookingService.getTransportOptions(
        origin: _originPosition!,
        destination: _destinationPosition!,
        departureTime: DateTime.now(),
        extractedPrice: widget.extractedPrice,
        vehicleType: widget.vehicleType,
      );

      // Sort by price (cheapest first) by default
      options.sort((a, b) => a.price.compareTo(b.price));

      setState(() {
        _options = _sortOptions(options);
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      _showError('Could not load transport options: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TransportOption> _sortOptions(List<TransportOption> options) {
    final sorted = List<TransportOption>.from(options);
    switch (_sortBy) {
      case 'price':
        sorted.sort((a, b) => a.price.compareTo(b.price)); // Cheapest first
        break;
      case 'duration':
        sorted.sort((a, b) => a.duration.compareTo(b.duration)); // Fastest first
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating)); // Highest rating first
        break;
    }
    return sorted;
  }

  void _showError(String message) {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _bookTransport(TransportOption option) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate booking delay
      await Future.delayed(const Duration(seconds: 1));
      
      final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';
      
      if (mounted) {
        await showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.systemGreen,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text('Booking Confirmed'),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✅ Your booking has been confirmed!\n\n'
                    'Booking ID: $bookingId\n'
                    'Provider: ${option.provider}\n'
                    'Type: ${option.type}\n'
                    'Price: ${option.formattedPrice}\n'
                    'Duration: ${option.formattedDuration}\n'
                    'Distance: ${option.distance.toStringAsFixed(1)} km\n\n'
                    'Status: Confirmed',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You will receive a confirmation SMS shortly.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
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
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openInMakeMyTrip(TransportOption option) async {
    if (_originPosition == null || _destinationPosition == null) return;
    
    // Open MakeMyTrip website/app with search parameters
    final url = 'https://www.makemytrip.com/bus-tickets/?'
        'fromCity=${_originController.text}&'
        'toCity=${_destinationController.text}&'
        'date=${DateTime.now().toString().split(' ')[0]}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Book Transport'),
        trailing: _options.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: const Text('Sort By'),
                      actions: [
                        CupertinoActionSheetAction(
                          child: const Text('💰 Price (Cheapest First)'),
                          onPressed: () {
                            setState(() {
                              _sortBy = 'price';
                              _options = _sortOptions(_options);
                            });
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoActionSheetAction(
                          child: const Text('⏱️ Duration (Fastest First)'),
                          onPressed: () {
                            setState(() {
                              _sortBy = 'duration';
                              _options = _sortOptions(_options);
                            });
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoActionSheetAction(
                          child: const Text('⭐ Rating (Highest First)'),
                          onPressed: () {
                            setState(() {
                              _sortBy = 'rating';
                              _options = _sortOptions(_options);
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
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.systemBackground,
              child: Column(
                children: [
                  // Origin Input
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.circle_fill,
                          color: CupertinoColors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _originController,
                          placeholder: 'From (Origin)',
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSubmitted: (_) => _searchOrigin(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () async {
                          try {
                            _originPosition = await Geolocator.getCurrentPosition();
                            final address = await _bookingService.getAddressFromLocation(_originPosition!);
                            setState(() {
                              _originController.text = address;
                            });
                            if (_destinationPosition != null) {
                              await _searchTransport();
                            }
                          } catch (e) {
                            _showError('Could not get current location: $e');
                          }
                        },
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Destination Input
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.flag_fill,
                          color: CupertinoColors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _destinationController,
                          placeholder: 'To (Destination)',
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSubmitted: (_) => _searchDestination(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () async {
                          try {
                            _destinationPosition = await Geolocator.getCurrentPosition();
                            final address = await _bookingService.getAddressFromLocation(_destinationPosition!);
                            setState(() {
                              _destinationController.text = address;
                            });
                            if (_originPosition != null) {
                              await _searchTransport();
                            }
                          } catch (e) {
                            _showError('Could not get current location: $e');
                          }
                        },
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: _isLoading ? null : _searchTransport,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('Search Transport'),
                  ),
                ],
              ),
            ),

            // Results Section
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _options.isEmpty && _hasSearched
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.car,
                                  size: 64,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No transport options available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please try different origin or destination',
                                  style: TextStyle(
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _options.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.search,
                                      size: 64,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Search for Transport',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Enter origin and destination to find available transport options',
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_sortBy == 'price')
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: CupertinoColors.systemGreen,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.info,
                                          color: CupertinoColors.systemGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Sorted by price (cheapest first) - ${_options.length} options found',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ..._options.map((option) => _buildTransportCard(option)),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(TransportOption option) {
    final isCheapest = _options.isNotEmpty && option.price == _options.first.price;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCheapest
            ? Border.all(color: CupertinoColors.systemGreen, width: 2)
            : Border.all(color: CupertinoColors.systemGrey5, width: 1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTransportIcon(option.type),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.type,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCheapest && _sortBy == 'price')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CHEAPEST',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          option.provider,
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              size: 14,
                              color: CupertinoColors.systemYellow,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              option.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
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
                    option.formattedPrice,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                  Text(
                    'per person',
                    style: TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.clock, size: 16, color: CupertinoColors.secondaryLabel),
              const SizedBox(width: 4),
              Text(
                option.formattedDuration,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 16),
              const Icon(CupertinoIcons.location, size: 16, color: CupertinoColors.secondaryLabel),
              const SizedBox(width: 4),
              Text(
                '${option.distance.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          if (option.amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.amenities.map((amenity) => Container(
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
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemGrey6,
                  onPressed: () => _openInMakeMyTrip(option),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.arrow_up_right_square, size: 16),
                      SizedBox(width: 4),
                      Text('View on MakeMyTrip'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CupertinoButton.filled(
                  onPressed: () => _bookTransport(option),
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTransportIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return '🚌';
      case 'train':
        return '🚂';
      case 'taxi':
        return '🚕';
      case 'auto':
        return '🛺';
      case 'flight':
        return '✈️';
      default:
        return '🚗';
    }
  }
}
