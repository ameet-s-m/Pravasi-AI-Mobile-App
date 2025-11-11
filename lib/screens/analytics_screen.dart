// lib/screens/analytics_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  SafetyAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final analytics = await _analyticsService.getSafetyAnalytics();
    setState(() {
      _analytics = analytics;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_analytics == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Safety Analytics')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Safety Analytics'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSafetyScoreCard(_analytics!),
          const SizedBox(height: 16),
          _buildStatsGrid(_analytics!),
          const SizedBox(height: 16),
          _buildTripsChart(_analytics!),
          const SizedBox(height: 16),
          _buildSafetyTrends(_analytics!),
        ],
      ),
    );
  }

  Widget _buildSafetyScoreCard(SafetyAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.systemPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Safety Score',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            analytics.safetyScore.toStringAsFixed(1),
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${analytics.safetyPercentage.toStringAsFixed(1)}% Safe Trips',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SafetyAnalytics analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Trips',
            '${analytics.totalTrips}',
            CupertinoIcons.map,
            CupertinoColors.systemBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Safe Trips',
            '${analytics.safeTrips}',
            CupertinoIcons.check_mark_circled_solid,
            CupertinoColors.systemGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsChart(SafetyAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Safety Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: analytics.safeTrips.toDouble(),
                    color: CupertinoColors.systemGreen,
                    title: '${analytics.safeTrips}',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: (analytics.totalTrips - analytics.safeTrips).toDouble(),
                    color: CupertinoColors.systemRed,
                    title: '${analytics.totalTrips - analytics.safeTrips}',
                    radius: 60,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTrends(SafetyAnalytics analytics) {
    return Column(
      children: [
        Container(
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
              const Text(
                'Safety Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInsightRow(
                'Incidents Reported',
                '${analytics.incidentsReported}',
                CupertinoIcons.exclamationmark_triangle,
                CupertinoColors.systemOrange,
              ),
              const SizedBox(height: 12),
              _buildInsightRow(
                'Emergency Alerts',
                '${analytics.emergencyAlerts}',
                CupertinoIcons.bell,
                CupertinoColors.systemRed,
              ),
              const SizedBox(height: 12),
              _buildInsightRow(
                'Avg Trip Duration',
                '${(analytics.averageTripDuration / 60).toStringAsFixed(1)} min',
                CupertinoIcons.timer,
                CupertinoColors.systemBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (analytics.mostUsedRoutes.isNotEmpty)
          Container(
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
                const Text(
                  'Most Used Routes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...analytics.mostUsedRoutes.map((route) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_fill,
                        size: 16,
                        color: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          route,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGreen.withOpacity(0.1),
                CupertinoColors.systemBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.lightbulb_fill,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Safety Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTipItem('Keep emergency contacts updated'),
              _buildTipItem('Share your live location during trips'),
              _buildTipItem('Report incidents to help the community'),
              _buildTipItem('Use verified safe zones when needed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(width: 8),
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

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

