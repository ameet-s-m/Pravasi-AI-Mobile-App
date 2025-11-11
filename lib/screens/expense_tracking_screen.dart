// lib/screens/expense_tracking_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/expense_tracking_service.dart';
import '../services/trip_data_service.dart';
import '../models/models.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  final String? tripId;
  const ExpenseTrackingScreen({super.key, this.tripId});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  final ExpenseTrackingService _expenseService = ExpenseTrackingService();
  final TripDataService _tripService = TripDataService();
  final MapController _mapController = MapController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Transport';
  List<Expense> _expenses = [];
  BudgetSummary? _summary;
  Trip? _trip;
  bool _isLoading = true;

  final List<String> _categories = [
    'Transport',
    'Food',
    'Accommodation',
    'Shopping',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tripId != null) {
      _loadExpenses();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    if (widget.tripId == null) return;
    
    await _tripService.initialize();
    final trip = _tripService.getTripById(widget.tripId!);
    final expenses = await _expenseService.getTripExpenses(widget.tripId!);
    final summary = await _expenseService.getBudgetSummary(widget.tripId!);
    
    setState(() {
      _expenses = expenses;
      _summary = summary;
      _trip = trip;
      _isLoading = false;
    });
    
    // Update map view if trip has route data
    if (trip != null && mounted) {
      _updateMapView(trip);
    }
  }

  void _updateMapView(Trip trip) {
    if (trip.startLocation != null && trip.endLocation != null) {
      final center = LatLng(
        (trip.startLocation!.latitude + trip.endLocation!.latitude) / 2,
        (trip.startLocation!.longitude + trip.endLocation!.longitude) / 2,
      );
      _mapController.move(center, 12.0);
    }
  }

  Future<void> _addExpense() async {
    if (widget.tripId == null || _amountController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please enter amount'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid Amount'),
          content: const Text('Please enter a valid amount'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    await _expenseService.addExpense(
      tripId: widget.tripId!,
      category: _selectedCategory,
      amount: amount,
      description: _descriptionController.text,
    );

    _amountController.clear();
    _descriptionController.clear();
    await _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Expenses')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Expense Tracking'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_summary != null) _buildSummaryCard(_summary!),
            const SizedBox(height: 16),
            if (_trip != null) _buildRouteMap(_trip!),
            if (_trip != null) const SizedBox(height: 16),
            _buildAddExpenseSection(),
            const SizedBox(height: 16),
            if (_expenses.isNotEmpty) _buildExpensesList(),
            if (_summary != null) _buildCategoryChart(_summary!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BudgetSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemGreen,
            CupertinoColors.systemBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Expenses',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.formattedTotal,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.expenseCount} expenses',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExpenseSection() {
    if (widget.tripId == null) {
      return const Center(
        child: Text('No trip selected'),
      );
    }

    return CupertinoFormSection.insetGrouped(
      header: const Text('ADD EXPENSE'),
      children: [
        CupertinoTextFormFieldRow(
          prefix: const Text('Amount'),
          placeholder: '₹0.00',
          controller: _amountController,
          keyboardType: TextInputType.number,
        ),
        CupertinoFormSection(
          children: [
            CupertinoListTile(
              title: const Text('Category'),
              trailing: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedCategory = _categories[index];
                  });
                },
                children: _categories.map((cat) => Text(cat)).toList(),
              ),
            ),
          ],
        ),
        CupertinoTextFormFieldRow(
          prefix: const Text('Description'),
          placeholder: 'Optional',
          controller: _descriptionController,
        ),
        CupertinoButton.filled(
          onPressed: _addExpense,
          child: const Text('Add Expense'),
        ),
      ],
    );
  }

  Widget _buildExpensesList() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('EXPENSES'),
      children: _expenses.map((expense) {
        return CupertinoListTile(
          title: Text(expense.category),
          subtitle: expense.description != null ? Text(expense.description!) : null,
          trailing: Text(
            expense.formattedAmount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemGreen,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChart(BudgetSummary summary) {
    if (summary.expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Expenses by Category',
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
                sections: summary.expensesByCategory.entries.map((entry) {
                  final colors = [
                    CupertinoColors.systemBlue,
                    CupertinoColors.systemGreen,
                    CupertinoColors.systemOrange,
                    CupertinoColors.systemPurple,
                    CupertinoColors.systemRed,
                    CupertinoColors.systemYellow,
                  ];
                  final index = summary.expensesByCategory.keys.toList().indexOf(entry.key);
                  return PieChartSectionData(
                    value: entry.value,
                    title: entry.key,
                    color: colors[index % colors.length],
                    radius: 60,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMap(Trip trip) {
    List<LatLng> routePoints = [];
    if (trip.routePoints != null && trip.routePoints!.isNotEmpty) {
      routePoints = trip.routePoints!.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } else if (trip.startLocation != null && trip.endLocation != null) {
      routePoints = [
        LatLng(trip.startLocation!.latitude, trip.startLocation!.longitude),
        LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
      ];
    }

    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: routePoints.length > 1
              ? LatLng(
                  (routePoints.first.latitude + routePoints.last.latitude) / 2,
                  (routePoints.first.longitude + routePoints.last.longitude) / 2,
                )
              : routePoints.first,
          initialZoom: 12.0,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.prototype',
            maxZoom: 19,
          ),
          if (routePoints.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 4,
                  color: trip.color,
                ),
              ],
            ),
          if (trip.startLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(trip.startLocation!.latitude, trip.startLocation!.longitude),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: CupertinoColors.white, width: 2),
                    ),
                    child: const Icon(
                      CupertinoIcons.location_solid,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          if (trip.endLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: CupertinoColors.white, width: 2),
                    ),
                    child: const Icon(
                      CupertinoIcons.location_fill,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

