import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class ExpenseViewModel extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Initialize the ViewModel
  Future<void> init() async {
    await fetchTransactions();
  }

  // Fetch all transactions from backend
  Future<void> fetchTransactions() async {
    _setLoading(true);
    try {
      _transactions = await _transactionService.getTransactions();
      // Sort by date (newest first)
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error loading transactions: ${e.toString()}';
      print('Error fetching transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new transaction to backend
  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      final newTransaction = await _transactionService.addTransaction(transaction);

      // Add to local list and sort
      _transactions.add(newTransaction);
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error adding transaction: ${e.toString()}';
      print('Error adding transaction: $e');
      rethrow; // Rethrow to let the UI handle the error
    } finally {
      _setLoading(false);
    }
  }

  // Calculate total expenses in EUR (simplified)
  Future<double> getTotalExpenses() async {
    if (_transactions.isEmpty) return 0.0;

    // Use a local variable to accumulate the sum
    double total = 0.0;

    // Sum up all transaction amounts
    for (var transaction in _transactions) {
      total += transaction.originalAmount;
    }

    return total;
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add these methods to support the expense chart screen
  Future<Map<String, double>> getExpensesByCategory() async {
    // Since we're using currency-based charts now, redirect to currency method
    return getExpensesByCurrency();
  }

  Future<Map<String, double>> getExpensesByCurrency() async {
    if (_transactions.isEmpty) return {};

    final Map<String, double> result = {};

    for (var transaction in _transactions) {
      final currency = transaction.originalCurrency;
      final amount = transaction.originalAmount;

      result[currency] = (result[currency] ?? 0) + amount;
    }

    return result;
  }

  Future<Map<DateTime, double>> getExpensesByDay() async {
    if (_transactions.isEmpty) return {};

    final Map<DateTime, double> result = {};

    for (var transaction in _transactions) {
      // Create date without time part
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );

      result[date] = (result[date] ?? 0) + transaction.originalAmount;
    }

    return result;
  }
}