// lib/services/expense_tracking_service.dart
import 'database_service.dart';

class ExpenseTrackingService {
  static final ExpenseTrackingService _instance = ExpenseTrackingService._internal();
  factory ExpenseTrackingService() => _instance;
  ExpenseTrackingService._internal();

  final DatabaseService _dbService = DatabaseService();

  Future<void> addExpense({
    required String tripId,
    required String category,
    required double amount,
    required String description,
    String currency = 'INR',
  }) async {
    await _dbService.saveExpense({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'trip_id': tripId,
      'category': category,
      'amount': amount,
      'currency': currency,
      'description': description,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Expense>> getTripExpenses(String tripId) async {
    final expenses = await _dbService.getTripExpenses(tripId);
    return expenses.map((e) => Expense(
      id: e['id'] as String,
      tripId: e['trip_id'] as String,
      category: e['category'] as String,
      amount: (e['amount'] as num).toDouble(),
      currency: e['currency'] as String,
      description: e['description'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
    )).toList();
  }

  Future<BudgetSummary> getBudgetSummary(String tripId) async {
    final expenses = await getTripExpenses(tripId);
    final total = expenses.fold<double>(0, (sum, exp) => sum + exp.amount);
    
    final byCategory = <String, double>{};
    for (var expense in expenses) {
      byCategory[expense.category] = 
          (byCategory[expense.category] ?? 0) + expense.amount;
    }

    return BudgetSummary(
      totalExpenses: total,
      expenseCount: expenses.length,
      expensesByCategory: byCategory,
      averageExpense: expenses.isNotEmpty ? total / expenses.length : 0,
    );
  }

  Future<void> setBudget(String tripId, double budget) async {
    // Save budget limit
  }

  Future<bool> isOverBudget(String tripId, double budget) async {
    final summary = await getBudgetSummary(tripId);
    return summary.totalExpenses > budget;
  }
}

class Expense {
  final String id;
  final String tripId;
  final String category;
  final double amount;
  final String currency;
  final String? description;
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.tripId,
    required this.category,
    required this.amount,
    required this.currency,
    this.description,
    required this.timestamp,
  });

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
}

class BudgetSummary {
  final double totalExpenses;
  final int expenseCount;
  final Map<String, double> expensesByCategory;
  final double averageExpense;

  BudgetSummary({
    required this.totalExpenses,
    required this.expenseCount,
    required this.expensesByCategory,
    required this.averageExpense,
  });

  String get formattedTotal => '₹${totalExpenses.toStringAsFixed(2)}';
}

