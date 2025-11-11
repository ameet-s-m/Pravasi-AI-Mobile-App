// lib/screens/profile_screen.dart
import 'package:flutter/cupertino.dart';
import '../main.dart';
import '../models/models.dart';
// Dummy data removed - calculating real achievements
import 'login_screen.dart';
import 'emergency_contact_screen.dart';
import 'safe_zones_screen.dart';
import 'analytics_screen.dart';
import 'incident_report_screen.dart';
import 'user_manual_screen.dart';
import 'permissions_disclaimer_screen.dart';
import 'elderly_care_mode_screen.dart';
import 'receipt_scanning_screen.dart';
import 'student_features_screen.dart';
import 'profile_switcher_screen.dart';
import 'carbon_footprint_screen.dart';
import 'data_export_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Profile'),
            backgroundColor: CupertinoColors.systemGroupedBackground.withOpacity(0.8),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF007AFF).withOpacity(0.1),
                    const Color(0xFF0051D5).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemBlue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'DR',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007AFF),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dr. Rajesh Kumar',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CupertinoColors.systemBlue.withOpacity(0.15),
                          CupertinoColors.systemBlue.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Senior Researcher',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            )
          ),

          // Statistics Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
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
                  const Text(
                    'YOUR STATISTICS',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildStatsGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ACHIEVEMENTS',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Calculate real achievements from user data
                final achievements = _calculateRealAchievements();
                if (index >= achievements.length) return null;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildAchievementItem(context, achievements[index]),
                );
              },
              childCount: _calculateRealAchievements().length,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              CupertinoListSection.insetGrouped(
                header: const Text('SETTINGS'),
                children: [
                  CupertinoListTile(
                    title: const Text('Dark Mode'),
                    trailing: CupertinoSwitch(
                      value: isDarkMode,
                      onChanged: (value) {
                        final brightness = value ? Brightness.dark : Brightness.light;
                        PravasiAIApp.of(context)?.changeTheme(brightness);
                      },
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('How It Works'),
                    leading: const Icon(CupertinoIcons.book_fill, color: CupertinoColors.systemBlue),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const UserManualScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Permissions'),
                    leading: const Icon(CupertinoIcons.shield_fill, color: CupertinoColors.systemGreen),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => PermissionsDisclaimerScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Switch Profile'),
                    leading: const Icon(CupertinoIcons.person_2_fill, color: CupertinoColors.systemPurple),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ProfileSwitcherScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Elderly Care Mode'),
                    leading: const Icon(CupertinoIcons.person_fill, color: CupertinoColors.systemOrange),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ElderlyCareModeScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Carbon Footprint'),
                    leading: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: CupertinoColors.systemGreen),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const CarbonFootprintScreen(),
                        ),
                      );
                    },
                  ),
                  const CupertinoListTile(
                    title: Text('Push Notifications'),
                    trailing: CupertinoListTileChevron(),
                  ),
                   const CupertinoListTile(
                    title: Text('Location Sharing'),
                    trailing: CupertinoListTileChevron(),
                  ),
                   const CupertinoListTile(
                    title: Text('Data Contribution'),
                    trailing: CupertinoListTileChevron(),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('FEATURES'),
                children: [
                  CupertinoListTile(
                    title: const Text('Scan Receipt'),
                    leading: const Icon(CupertinoIcons.doc_text_fill, color: CupertinoColors.systemBlue),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ReceiptScanningScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Student Features'),
                    leading: const Icon(CupertinoIcons.person_3_fill, color: CupertinoColors.systemPurple),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const StudentFeaturesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('SAFETY'),
                children: [
                  CupertinoListTile(
                    title: const Text('Emergency Contact'),
                    leading: const Icon(CupertinoIcons.phone_circle_fill, color: CupertinoColors.systemRed),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const EmergencyContactScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Safe Zones'),
                    leading: const Icon(CupertinoIcons.location_solid, color: CupertinoColors.systemBlue),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const SafeZonesScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Safety Analytics'),
                    leading: const Icon(CupertinoIcons.chart_bar_alt_fill, color: CupertinoColors.systemGreen),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Report Incident'),
                    leading: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemOrange),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const IncidentReportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                children: [
                  CupertinoListTile(
                    title: const Text('Export Trip Data'),
                    leading: const Icon(CupertinoIcons.square_arrow_down),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const DataExportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Sign Out button in separate section with padding
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: CupertinoListSection.insetGrouped(
                  children: [
                    CupertinoListTile(
                      title: const Text('Sign Out', style: TextStyle(color: CupertinoColors.destructiveRed)),
                      leading: const Icon(CupertinoIcons.square_arrow_left, color: CupertinoColors.destructiveRed),
                      onTap: () => Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        CupertinoPageRoute(builder: (context) => const LoginScreen()), (route) => false),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      )
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildProfileStat('247', 'Total Trips', CupertinoColors.systemBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildProfileStat('3840', 'km Traveled', CupertinoColors.systemGreen)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildProfileStat('89.5', 'hrs Active', CupertinoColors.systemOrange)),
              const SizedBox(width: 12),
              Expanded(child: _buildProfileStat('12k', 'Data Points', CupertinoColors.systemPurple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Achievement> _calculateRealAchievements() {
    // Calculate achievements from real user data
    // For now, return empty list - achievements should be calculated from actual trip data
    // TODO: Integrate with TripDataService to calculate real achievements
    return [];
    
    /* Example of how to calculate real achievements:
    final tripService = TripDataService();
    final trips = await tripService.getTrips();
    final totalDistance = trips.fold(0.0, (sum, trip) => sum + trip.distance);
    final totalTrips = trips.length;
    
    return [
      if (totalTrips >= 10)
        Achievement(
          title: 'Traveler',
          description: 'Completed $totalTrips trips',
          icon: Icons.flight_takeoff,
          isUnlocked: true,
        ),
      if (totalDistance >= 1000)
        Achievement(
          title: 'Distance Master',
          description: 'Traveled ${totalDistance.toStringAsFixed(0)} km',
          icon: Icons.straighten,
          isUnlocked: true,
        ),
      // Add more achievements based on real data
    ];
    */
  }

  Widget _buildAchievementItem(BuildContext context, Achievement achievement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: achievement.isUnlocked
              ? [
                  CupertinoColors.systemOrange.withOpacity(0.15),
                  CupertinoColors.systemOrange.withOpacity(0.08),
                ]
              : [
                  CupertinoColors.systemGrey5.withOpacity(0.5),
                  CupertinoColors.systemGrey5.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? CupertinoColors.systemOrange.withOpacity(0.3)
              : CupertinoColors.separator.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: CupertinoListTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: achievement.isUnlocked
                ? LinearGradient(
                    colors: [
                      CupertinoColors.systemOrange,
                      CupertinoColors.systemOrange.withOpacity(0.7),
                    ],
                  )
                : null,
            color: achievement.isUnlocked ? null : CupertinoColors.systemGrey5,
            shape: BoxShape.circle,
            boxShadow: achievement.isUnlocked
                ? [
                    BoxShadow(
                      color: CupertinoColors.systemOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            achievement.icon,
            color: achievement.isUnlocked
                ? CupertinoColors.white
                : CupertinoColors.secondaryLabel,
            size: 24,
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: achievement.isUnlocked
                ? CupertinoColors.label
                : CupertinoColors.secondaryLabel,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        trailing: achievement.isUnlocked
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.systemGreen,
                  size: 20,
                ),
              )
            : const Icon(
                CupertinoIcons.lock_fill,
                color: CupertinoColors.secondaryLabel,
                size: 18,
              ),
      ),
    );
  }
}