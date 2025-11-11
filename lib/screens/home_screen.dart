// lib/screens/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar; // For CircleAvatar widget
// Removed dummy_data import - using real trip data service instead
import '../models/models.dart';
import 'data_export_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';
import 'plan_trip_screen.dart' show PlanTripScreen;
import '../widgets/sos_button.dart';
import 'safe_zones_screen.dart';
import 'analytics_screen.dart';
// Fake call feature removed - not a real safety feature
import 'incident_report_screen.dart';
import 'child_safety_screen.dart';
import 'accident_report_screen.dart';
import 'navigation_screen.dart';
import 'transport_booking_screen.dart';
import 'ai_copilot_screen.dart';
import 'rewards_screen.dart';
import 'hotels_screen.dart';
import 'user_manual_screen.dart';
import 'permissions_disclaimer_screen.dart';
import 'receipt_scanning_screen.dart';
import 'student_features_screen.dart';
import 'carbon_footprint_screen.dart';
import 'vr_explore_screen.dart';
import 'driving_mode_screen.dart';
import 'woman_safety_screen.dart';
import 'tourism_screen.dart';
import 'active_trip_screen.dart';
import 'trip_details_screen.dart';
import 'arrival_alert_screen.dart';
import '../services/active_trip_service.dart';
import '../services/simple_mode_service.dart';
import '../services/trip_data_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(PlannedTrip) onNewTripCreated;
  const HomeScreen({super.key, required this.onNewTripCreated});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SimpleModeService _simpleModeService = SimpleModeService();
  final TripDataService _tripDataService = TripDataService();
  List<String> _availableFeatures = [];
  bool _isLoadingFeatures = true;
  bool _isSimpleMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isSimple = await _simpleModeService.isSimpleModeEnabled();
    final features = await _simpleModeService.getAvailableFeatures();
    setState(() {
      _isSimpleMode = isSimple;
      _availableFeatures = features;
      _isLoadingFeatures = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload settings when returning to this screen
    _loadSettings();
  }

  bool _isFeatureAvailable(String feature) {
    return _availableFeatures.contains(feature);
  }

  Future<void> _handleQuickAction(String label) async {
    if (label == 'New Trip') {
      // Show options: Plan Trip or Start Tracking Now
      final action = await showCupertinoModalPopup<String>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('New Trip'),
          message: const Text('Choose how you want to start your trip'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Start Tracking Now'),
              onPressed: () => Navigator.pop(context, 'track'),
            ),
            CupertinoActionSheetAction(
              child: const Text('Plan Trip First'),
              onPressed: () => Navigator.pop(context, 'plan'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );

      if (action == 'track' && mounted) {
        // Start real-time tracking immediately
        final completedTrip = await Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (_) => const ActiveTripScreen(
              tripTitle: 'Quick Trip',
            ),
          ),
        );
        if (completedTrip != null && mounted) {
          // Trip was completed and saved
          setState(() {});
        }
      } else if (action == 'plan' && mounted) {
        // Plan trip first
        final planned = await Navigator.of(context, rootNavigator: true)
          .push(CupertinoPageRoute(builder: (_) => PlanTripScreen()));
        if (planned != null && mounted) {
          widget.onNewTripCreated(planned);
        }
      }
    } else if (label == 'Safe Zones') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const SafeZonesScreen()),
      );
    } else if (label == 'Analytics') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const AnalyticsScreen()),
      );
    // Fake Call feature removed - not a real safety feature
    } else if (label == 'Navigation') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const NavigationScreen()),
      );
    } else if (label == 'Arrival Alert') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const ArrivalAlertScreen()),
      );
    } else if (label == 'Book Transport') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const TransportBookingScreen()),
      );
    } else if (label == 'AI Copilot') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const AICopilotScreen()),
      );
    } else if (label == 'Hotels') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const HotelsScreen()),
      );
    } else if (label == 'Rewards') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const RewardsScreen()),
      );
    } else if (label == 'Carbon Footprint') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const CarbonFootprintScreen()),
      );
    } else if (label == 'Scan Receipt') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const ReceiptScanningScreen()),
      );
    } else if (label == 'Student') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const StudentFeaturesScreen()),
      );
    } else if (label == 'Child Safety') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const ChildSafetyScreen()),
      );
    } else if (label == 'Emergency Report') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const AccidentReportScreen()),
      );
    } else if (label == 'Incident Report' || label == 'Report') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const IncidentReportScreen()),
      );
    } else if (label == 'Analytics') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const AnalyticsScreen()),
      );
    } else if (label == 'Data Export') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const DataExportScreen()),
      );
    } else if (label == 'Explore VR') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const VRExploreScreen()),
      );
    } else if (label == 'Driving Mode') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const DrivingModeScreen()),
      );
    } else if (label == 'Woman Safety') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const WomanSafetyScreen()),
      );
    } else if (label == 'Tourism') {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (context) => const TourismScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // SIMPLE MODE: Show only important buttons in a clean grid
    if (_isSimpleMode) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: const CircleAvatar(
            radius: 16,
            backgroundColor: CupertinoColors.systemGrey5, 
            child: Text('PA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
          ),
          middle: const Text('PRAVASI AI'),
          trailing: GestureDetector(
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(builder: (_) => const SettingsScreen())
              );
              // Always reload settings when returning from settings screen
              _loadSettings();
            },
            child: const Icon(CupertinoIcons.settings, size: 24),
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Essential safety and travel features',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Grid of important buttons
                    _buildSimpleModeGrid(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 20,
              right: 20,
              child: SOSButton(),
            ),
          ],
        ),
      );
    }

    // NORMAL MODE: Full featured view
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const CircleAvatar(
          radius: 16,
          backgroundColor: CupertinoColors.systemGrey5, 
          child: Text('PA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ),
        middle: const Text('PRAVASI AI'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(builder: (_) => const UserManualScreen())
              ),
              child: const Icon(CupertinoIcons.book_fill, size: 24),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(builder: (_) => const NotificationScreen())
              ),
              child: const Icon(CupertinoIcons.bell, size: 24),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(builder: (_) => const SettingsScreen())
                );
                // Always reload settings when returning from settings screen
                _loadSettings();
              },
              child: const Icon(CupertinoIcons.settings, size: 24),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          ListView(
            children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getTripStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {'totalTrips': 0, 'tripsToday': 0};
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTripsDescription(context, stats),
                        child: _buildStatCard(
                          '${stats['totalTrips']}',
                          'Total Trips',
                          CupertinoIcons.map,
                          CupertinoColors.systemBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        '${stats['tripsToday']}',
                        'Trips Today',
                        CupertinoIcons.calendar,
                        CupertinoColors.systemGreen,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildSectionHeader('Active Trip'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildActiveTripCard(context),
          ),
          _buildSectionHeader("Today's Overview"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTodaysOverviewCard(context),
          ),
          _buildSectionHeader('Quick Actions'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(
                          builder: (_) => const UserManualScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.book_fill, size: 18, color: CupertinoColors.white),
                          SizedBox(width: 8),
                          Text(
                            'How It Works',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(
                          builder: (_) => PermissionsDisclaimerScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF34C759), Color(0xFF28A745)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGreen.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.shield_fill, size: 18, color: CupertinoColors.white),
                          SizedBox(width: 8),
                          Text(
                            'Permissions',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: _isLoadingFeatures
                ? const Center(child: CupertinoActivityIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.none,
                    children: [
                      // IMPORTANT EMERGENCY & SAFETY BUTTONS (Priority)
                      _buildActionItem('Emergency Report', CupertinoIcons.exclamationmark_triangle_fill, isEmergency: true),
                      if (_isFeatureAvailable('Report'))
                        _buildActionItem('Incident Report', CupertinoIcons.flag_fill, isEmergency: true),
                      // Fake Call feature removed
                      if (_isFeatureAvailable('Woman Safety'))
                        _buildActionItem('Woman Safety', CupertinoIcons.shield_fill, isEmergency: true),
                      if (_isFeatureAvailable('Child Safety'))
                        _buildActionItem('Child Safety', CupertinoIcons.person_2, isEmergency: true),
                      if (_isFeatureAvailable('Safe Zones'))
                        _buildActionItem('Safe Zones', CupertinoIcons.location_solid),
                      if (_isFeatureAvailable('Driving Mode'))
                        _buildActionItem('Driving Mode', CupertinoIcons.car_fill),
                      
                      // TRIP & NAVIGATION BUTTONS
                      if (_isFeatureAvailable('New Trip'))
                        _buildActionItem('New Trip', CupertinoIcons.add),
                      if (_isFeatureAvailable('Navigation'))
                        _buildActionItem('Navigation', CupertinoIcons.map),
                      _buildActionItem('Arrival Alert', CupertinoIcons.bell_fill),
                      if (_isFeatureAvailable('Book Transport'))
                        _buildActionItem('Book Transport', CupertinoIcons.car_detailed),
                      
                      // AI & SMART FEATURES
                      if (_isFeatureAvailable('AI Copilot'))
                        _buildActionItem('AI Copilot', CupertinoIcons.sparkles),
                      if (_isFeatureAvailable('Analytics'))
                        _buildActionItem('Analytics', CupertinoIcons.chart_bar_alt_fill),
                      
                      // TRAVEL & SERVICES
                      if (_isFeatureAvailable('Hotels'))
                        _buildActionItem('Hotels', CupertinoIcons.building_2_fill),
                      if (_isFeatureAvailable('Tourism'))
                        _buildActionItem('Tourism', CupertinoIcons.map_fill),
                      if (_isFeatureAvailable('Explore VR'))
                        _buildActionItem('Explore VR', CupertinoIcons.cube_box_fill),
                      
                      // UTILITIES
                      if (_isFeatureAvailable('Rewards'))
                        _buildActionItem('Rewards', CupertinoIcons.gift),
                      if (_isFeatureAvailable('Carbon Footprint'))
                        _buildActionItem('Carbon Footprint', CupertinoIcons.leaf_arrow_circlepath),
                      if (_isFeatureAvailable('Scan Receipt'))
                        _buildActionItem('Scan Receipt', CupertinoIcons.doc_text),
                      if (_isFeatureAvailable('Student'))
                        _buildActionItem('Student', CupertinoIcons.person_3),
                    ],
                  ),
          ),
          _buildSectionHeader('Recent Trips'),
          FutureBuilder<List<dynamic>>(
            future: _loadRecentTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final trips = snapshot.data ?? [];
              if (trips.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No trips yet. Start tracking to see your trips here.', 
                        style: TextStyle(color: CupertinoColors.secondaryLabel)),
                  ),
                );
              }
              return CupertinoListSection.insetGrouped(
                children: trips.map((trip) => _buildRecentTripItem(context, trip)).toList(),
              );
            },
          ),
          _buildSectionHeader('Planned / Saved Trips'),
          FutureBuilder<List<dynamic>>(
            future: _loadPlannedTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final plannedTrips = snapshot.data ?? [];
              if (plannedTrips.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No planned trips.', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                  ),
                );
              }
              return CupertinoListSection.insetGrouped(
                children: plannedTrips.map((t) => _buildPlannedTripTile(context, t)).toList(),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
          const Positioned(
            bottom: 20,
            right: 20,
            child: SOSButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: CupertinoColors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveTripCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CupertinoColors.systemBlue.withOpacity(0.15),
            CupertinoColors.systemBlue.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.systemBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemBlue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.location_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGreen.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Trip',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.systemBlue,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Field Survey - Rural Transport',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Started at 06:00 AM',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              // Check if there's an active trip
              final activeTripService = ActiveTripService();
              if (activeTripService.isTracking) {
                // Get current trip data
                final currentPosition = activeTripService.currentPosition;
                final routePoints = activeTripService.routePoints;
                final distance = activeTripService.totalDistance;
                final duration = activeTripService.duration;
                
                if (currentPosition != null) {
                  final trip = Trip(
                    tripId: 'active_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Active Trip',
                    mode: 'Car',
                    distance: distance,
                    duration: _formatDuration(duration),
                    time: DateTime.now().toString().substring(11, 16),
                    destination: 'In Progress',
                    icon: CupertinoIcons.car_fill,
                    isCompleted: false,
                    companions: 'Solo',
                    purpose: 'Travel',
                    notes: 'Active trip tracking',
                    color: CupertinoColors.systemBlue,
                    routePoints: routePoints.map((p) => RoutePoint(
                      latitude: p.latitude,
                      longitude: p.longitude,
                    )).toList(),
                    startLocation: routePoints.isNotEmpty
                        ? RoutePoint(
                            latitude: routePoints.first.latitude,
                            longitude: routePoints.first.longitude,
                          )
                        : null,
                    endLocation: routePoints.isNotEmpty
                        ? RoutePoint(
                            latitude: routePoints.last.latitude,
                            longitude: routePoints.last.longitude,
                          )
                        : null,
                    startTime: DateTime.now(),
                  );
                  
                  await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => TripDetailsScreen(
                        activeTrip: trip,
                        isActive: true,
                      ),
                    ),
                  );
                } else {
                  // No active trip
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('No Active Trip'),
                      content: const Text('There is no active trip to show details for.'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                // No active trip
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('No Active Trip'),
                    content: const Text('There is no active trip to show details for.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Details',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ), minimumSize: Size(0, 0),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodaysOverviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CupertinoTheme.of(context).brightness == Brightness.light
                ? CupertinoColors.white
                : CupertinoColors.secondarySystemGroupedBackground,
            CupertinoTheme.of(context).brightness == Brightness.light
                ? CupertinoColors.white.withOpacity(0.95)
                : CupertinoColors.secondarySystemGroupedBackground.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildOverviewItem('127.5 km', 'Distance', CupertinoIcons.location, CupertinoColors.systemOrange)),
          Container(
            width: 1,
            height: 50,
            color: CupertinoColors.separator.withOpacity(0.3),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildOverviewItem('4.2 hrs', 'Time', CupertinoIcons.timer, CupertinoColors.systemPurple)),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String value, String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentTripItem(BuildContext context, Trip trip) {
    return CupertinoListTile(
      leading: CircleAvatar(
        backgroundColor: trip.color.withOpacity(0.1),
        child: Icon(trip.icon, color: trip.color, size: 20),
      ),
      title: Text(trip.title),
      subtitle: Text(trip.destination),
      trailing: const CupertinoListTileChevron(),
      onTap: () { /* Navigate to trip details */ },
    );
  }

  Widget _buildActionItem(String label, IconData icon, {bool isEmergency = false}) {
    return GestureDetector(
      onTap: () => _handleQuickAction(label),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        constraints: const BoxConstraints(
          minHeight: 100,
          maxHeight: 110,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isEmergency
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isEmergency ? CupertinoColors.systemRed : CupertinoColors.systemBlue).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: isEmergency ? CupertinoColors.systemRed : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Simple Mode Grid Layout
  Widget _buildSimpleModeGrid() {
    final importantButtons = [
      {'label': 'Emergency Report', 'icon': CupertinoIcons.exclamationmark_triangle_fill, 'isEmergency': true},
      {'label': 'Incident Report', 'icon': CupertinoIcons.flag_fill, 'isEmergency': true},
      // Fake Call removed
      {'label': 'Woman Safety', 'icon': CupertinoIcons.shield_fill, 'isEmergency': true},
      {'label': 'Child Safety', 'icon': CupertinoIcons.person_2, 'isEmergency': true},
      {'label': 'Safe Zones', 'icon': CupertinoIcons.location_solid, 'isEmergency': false},
      {'label': 'Driving Mode', 'icon': CupertinoIcons.car_fill, 'isEmergency': false},
      {'label': 'New Trip', 'icon': CupertinoIcons.add, 'isEmergency': false},
      {'label': 'Navigation', 'icon': CupertinoIcons.map, 'isEmergency': false},
      {'label': 'Arrival Alert', 'icon': CupertinoIcons.bell_fill, 'isEmergency': false},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: importantButtons.length,
      itemBuilder: (context, index) {
        final button = importantButtons[index];
        return _buildSimpleModeButton(
          button['label'] as String,
          button['icon'] as IconData,
          isEmergency: button['isEmergency'] as bool,
        );
      },
    );
  }

  Widget _buildSimpleModeButton(String label, IconData icon, {bool isEmergency = false}) {
    return GestureDetector(
      onTap: () => _handleQuickAction(label),
      child: Container(
        decoration: BoxDecoration(
          gradient: isEmergency
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isEmergency ? CupertinoColors.systemRed : CupertinoColors.systemBlue).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannedTripTile(BuildContext context, PlannedTrip trip) {
    return CupertinoListTile(
      title: Text('${trip.origin} → ${trip.destination}'),
      subtitle: Text('${trip.time} • ${trip.passengers} passengers'),
      trailing: const CupertinoListTileChevron(),
      onTap: () => _editTrip(context, trip),
    );
  }

  Future<List<Trip>> _loadRecentTrips() async {
    await _tripDataService.initialize();
    final trips = _tripDataService.getTrips();
    // Return most recent 5 trips
    return trips.take(5).toList();
  }

  Future<List<PlannedTrip>> _loadPlannedTrips() async {
    await _tripDataService.initialize();
    return _tripDataService.getPlannedTrips();
  }

  Future<void> _editTrip(BuildContext context, PlannedTrip trip) async {
    final edited = await Navigator.of(context, rootNavigator: true)
      .push(CupertinoPageRoute(builder: (_) => PlanTripScreen(editTrip: trip)));
    if (edited != null && mounted) {
      setState(() {
        // Trip updated in service, reload
      });
    }
  }

  Future<Map<String, dynamic>> _getTripStats() async {
    await _tripDataService.initialize();
    return _tripDataService.getStatistics();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _showTripsDescription(BuildContext context, Map<String, dynamic> stats) {
    final totalTrips = stats['totalTrips'] ?? 0;
    final tripsToday = stats['tripsToday'] ?? 0;
    final totalDistance = stats['totalDistance'] ?? 0.0;
    final totalHours = stats['totalHours'] ?? 0.0;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Trip Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Trips: $totalTrips'),
            const SizedBox(height: 8),
            Text('Trips Today: $tripsToday'),
            const SizedBox(height: 8),
            Text('Total Distance: ${totalDistance.toStringAsFixed(2)} km'),
            const SizedBox(height: 8),
            Text('Total Hours: ${totalHours.toStringAsFixed(1)} hrs'),
          ],
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
}