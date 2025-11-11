// lib/screens/tourism_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tourism_service.dart';

class TourismScreen extends StatefulWidget {
  const TourismScreen({super.key});

  @override
  State<TourismScreen> createState() => _TourismScreenState();
}

class _TourismScreenState extends State<TourismScreen> {
  final TourismService _tourismService = TourismService();
  Position? _currentPosition;
  List<TouristAttraction> _nearbyAttractions = [];
  TravelGuide? _travelGuide;
  LocalRecommendations? _localRecommendations;
  bool _isLoading = false;
  String _selectedCategory = 'All';
  int _selectedDays = 3;
  String? _errorMessage;

  final List<String> _categories = [
    'All',
    'Historical',
    'Museum',
    'Natural',
    'Religious',
    'Entertainment',
  ];

  @override
  void initState() {
    super.initState();
    _loadTourismData();
  }

  Future<void> _loadTourismData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _tourismService.initialize();
      _currentPosition = await Geolocator.getCurrentPosition();
      
      // Load attractions
      final category = _selectedCategory == 'All' ? null : _selectedCategory;
      final attractions = await _tourismService.getTouristAttractions(
        _currentPosition!,
        category: category,
      );
      
      setState(() {
        _nearbyAttractions = attractions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading tourism data: $e';
      });
    }
  }

  Future<void> _loadTravelGuide() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final guide = await _tourismService.getTravelGuide(
        _currentPosition!,
        days: _selectedDays,
      );
      
      setState(() {
        _travelGuide = guide;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading travel guide: $e';
      });
    }
  }

  Future<void> _loadLocalRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recommendations = await _tourismService.getLocalRecommendations(
        _currentPosition!,
      );
      
      setState(() {
        _localRecommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading recommendations: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Tourism & Attractions'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle,
                            size: 64,
                            color: CupertinoColors.systemRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton.filled(
                            onPressed: _loadTourismData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      if (_nearbyAttractions.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildCategoryFilter(),
                        const SizedBox(height: 16),
                        _buildCategorySection('Nearby Attractions', _nearbyAttractions),
                      ],
                      if (_travelGuide != null) ...[
                        const SizedBox(height: 24),
                        _buildTravelGuideSection(),
                      ],
                      if (_localRecommendations != null) ...[
                        const SizedBox(height: 24),
                        _buildRecommendationsSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildTravelTips(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.systemPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.map_fill,
            size: 50,
            color: CupertinoColors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'AI-Powered Tourism Guide',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentPosition != null
                ? 'Discover amazing places powered by Gemini AI'
                : 'Getting your location...',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            color: CupertinoColors.systemBlue,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _loadTravelGuide,
            child: const Column(
              children: [
                Icon(CupertinoIcons.book_fill, size: 24),
                SizedBox(height: 4),
                Text('Travel Guide', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoButton(
            color: CupertinoColors.systemGreen,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _loadLocalRecommendations,
            child: const Column(
              children: [
                Icon(CupertinoIcons.star_fill, size: 24),
                SizedBox(height: 4),
                Text('Local Tips', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoButton(
            color: CupertinoColors.systemOrange,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _loadTourismData,
            child: const Column(
              children: [
                Icon(CupertinoIcons.refresh, size: 24),
                SizedBox(height: 4),
                Text('Refresh', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey6,
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadTourismData();
              },
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.sparkles,
            size: 64,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Tourism Guide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get personalized travel recommendations powered by Gemini AI',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: _loadTourismData,
            child: const Text('Discover Attractions'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: Requires Gemini API key in Settings',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<TouristAttraction> attractions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...attractions.map((attraction) => _buildAttractionCard(attraction)),
      ],
    );
  }

  Widget _buildAttractionCard(TouristAttraction attraction) {
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
            offset: const Offset(0, 4),
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
                      attraction.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        attraction.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.systemYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attraction.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            attraction.description,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          if (attraction.highlights.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: attraction.highlights.take(3).map((highlight) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    highlight,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 14,
                color: CupertinoColors.secondaryLabel,
              ),
              const SizedBox(width: 4),
              Text(
                attraction.openingHours,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                CupertinoIcons.money_dollar_circle,
                size: 14,
                color: CupertinoColors.secondaryLabel,
              ),
              const SizedBox(width: 4),
              Text(
                attraction.entryFee,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          if (attraction.tips != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.lightbulb_fill,
                    size: 14,
                    color: CupertinoColors.systemYellow,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attraction.tips!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  onPressed: () => _navigateToAttraction(attraction),
                  child: const Text('Get Directions'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  onPressed: () => _viewDetails(attraction),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTravelGuideSection() {
    if (_travelGuide == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.book_fill,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 8),
              Text(
                '${_travelGuide!.days}-Day Travel Guide',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _travelGuide!.overview,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_travelGuide!.itinerary.isNotEmpty) ...[
            const Text(
              'Itinerary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._travelGuide!.itinerary.map((day) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...day.activities.map((activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(child: Text(activity, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
                ],
              ),
            )),
          ],
          if (_travelGuide!.localFood.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Must-Try Local Food',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _travelGuide!.localFood.map((food) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    food,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_localRecommendations == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                color: CupertinoColors.systemYellow,
              ),
              SizedBox(width: 8),
              Text(
                'Local Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_localRecommendations!.restaurants.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Top Restaurants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._localRecommendations!.restaurants.take(5).map((restaurant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${restaurant.cuisine} • ${restaurant.priceRange}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (_localRecommendations!.hiddenGems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Hidden Gems',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._localRecommendations!.hiddenGems.map((gem) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💎 ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(gem, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.lightbulb_fill,
                color: CupertinoColors.systemYellow,
              ),
              const SizedBox(width: 8),
              const Text(
                'Travel Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('📸 Take photos but respect local customs'),
          _buildTip('💰 Carry cash for entry fees and local vendors'),
          _buildTip('⏰ Check opening hours before visiting'),
          _buildTip('🚗 Use public transport for popular attractions'),
          _buildTip('🌡️ Check weather before outdoor activities'),
          _buildTip('📱 Keep your phone charged and share location'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAttraction(TouristAttraction attraction) async {
    final url = 'https://www.google.com/maps?q=${attraction.latitude},${attraction.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _viewDetails(TouristAttraction attraction) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(attraction.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${attraction.category}'),
              const SizedBox(height: 8),
              Text('Rating: ${attraction.rating} ⭐'),
              const SizedBox(height: 8),
              Text('Opening Hours: ${attraction.openingHours}'),
              const SizedBox(height: 8),
              Text('Entry Fee: ${attraction.entryFee}'),
              const SizedBox(height: 8),
              Text('Best Time: ${attraction.bestTimeToVisit}'),
              const SizedBox(height: 8),
              Text('Duration: ${attraction.visitDuration}'),
              const SizedBox(height: 8),
              Text(attraction.description),
              if (attraction.highlights.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Highlights:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...attraction.highlights.map((h) => Text('• $h')),
              ],
              if (attraction.tips != null) ...[
                const SizedBox(height: 8),
                Text('💡 Tip: ${attraction.tips}'),
              ],
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Get Directions'),
            onPressed: () {
              Navigator.pop(context);
              _navigateToAttraction(attraction);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
