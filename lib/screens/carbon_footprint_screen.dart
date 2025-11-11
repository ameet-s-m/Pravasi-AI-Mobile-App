// lib/screens/carbon_footprint_screen.dart
import 'package:flutter/cupertino.dart';
import '../services/carbon_footprint_service.dart';
import 'package:fl_chart/fl_chart.dart';

class CarbonFootprintScreen extends StatefulWidget {
  const CarbonFootprintScreen({super.key});

  @override
  State<CarbonFootprintScreen> createState() => _CarbonFootprintScreenState();
}

class _CarbonFootprintScreenState extends State<CarbonFootprintScreen> {
  final CarbonFootprintService _carbonService = CarbonFootprintService();
  double _totalCarbon = 0.0;
  Map<String, double> _carbonByMode = {};
  String _suggestion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarbonData();
  }

  Future<void> _loadCarbonData() async {
    final total = await _carbonService.getTotalCarbonFootprint();
    final byMode = await _carbonService.getCarbonByMode();
    final suggestion = await _carbonService.getCarbonSavingsSuggestion();

    setState(() {
      _totalCarbon = total;
      _carbonByMode = byMode;
      _suggestion = suggestion;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Carbon Footprint')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Carbon Footprint'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total Carbon Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemGreen,
                    CupertinoColors.systemTeal,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.leaf_arrow_circlepath,
                    size: 60,
                    color: CupertinoColors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Total Carbon Footprint',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _carbonService.formatCarbon(_totalCarbon),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEquivalentText(_totalCarbon),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chart
            if (_carbonByMode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CupertinoColors.separator),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carbon by Transport Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _buildChartSections(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Breakdown
            if (_carbonByMode.isNotEmpty) ...[
              CupertinoFormSection.insetGrouped(
                header: const Text('BREAKDOWN BY MODE'),
                children: _carbonByMode.entries.map((entry) {
                  final percentage = _totalCarbon > 0
                      ? (entry.value / _totalCarbon * 100)
                      : 0.0;
                  return CupertinoListTile(
                    leading: Icon(_getModeIcon(entry.key)),
                    title: Text(entry.key),
                    subtitle: Text('${percentage.toStringAsFixed(1)}% of total'),
                    trailing: Text(
                      _carbonService.formatCarbon(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Suggestion
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.systemBlue,
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
                        color: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Eco-Friendly Tip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _suggestion,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Carbon Footprint',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your carbon footprint is calculated based on the distance traveled and the transport mode used. '
                    'Walking and cycling have zero emissions, while public transport has lower emissions than private vehicles.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemRed,
      CupertinoColors.systemTeal,
    ];

    int colorIndex = 0;
    return _carbonByMode.entries.map((entry) {
      final percentage = _totalCarbon > 0
          ? (entry.value / _totalCarbon * 100)
          : 0.0;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[colorIndex % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.white,
        ),
      );
    }).toList();
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'Bus':
        return CupertinoIcons.bus;
      case 'Train':
        return CupertinoIcons.tram_fill;
      case 'Taxi':
        return CupertinoIcons.car;
      case 'Auto':
        return CupertinoIcons.car_detailed;
      case 'Flight':
        return CupertinoIcons.airplane;
      case 'Car':
        return CupertinoIcons.car_fill;
      default:
        return CupertinoIcons.location;
    }
  }

  String _getEquivalentText(double kgCO2) {
    // 1 kg CO2 ≈ 0.27 kg of coal burned
    // 1 kg CO2 ≈ 0.4 liters of gasoline
    if (kgCO2 < 1) {
      return 'Keep it up!';
    } else if (kgCO2 < 10) {
      return 'Equivalent to ${(kgCO2 * 0.4).toStringAsFixed(1)} liters of gasoline';
    } else {
      return 'Equivalent to ${(kgCO2 * 0.27).toStringAsFixed(1)} kg of coal';
    }
  }
}

