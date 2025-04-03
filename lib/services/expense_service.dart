import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _storageKey = 'expenses';

  // Récupérer toutes les dépenses
  Future<List<Expense>> getAllExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_storageKey) ?? [];
    
    return expensesJson
        .map((json) => Expense.fromMap(jsonDecode(json)))
        .toList();
  }

  // Ajouter une nouvelle dépense
  Future<void> addExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_storageKey) ?? [];
    
    expensesJson.add(jsonEncode(expense.toMap()));
    await prefs.setStringList(_storageKey, expensesJson);
  }

  // Mettre à jour une dépense existante
  Future<void> updateExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_storageKey) ?? [];
    
    final index = expensesJson.indexWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == expense.id;
    });
    
    if (index != -1) {
      expensesJson[index] = jsonEncode(expense.toMap());
      await prefs.setStringList(_storageKey, expensesJson);
    }
  }

  // Supprimer une dépense
  Future<void> deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_storageKey) ?? [];
    
    final filteredExpenses = expensesJson.where((json) {
      final map = jsonDecode(json);
      return map['id'] != id;
    }).toList();
    
    await prefs.setStringList(_storageKey, filteredExpenses);
  }

  // Obtenir les dépenses par catégorie
  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getAllExpenses();
    final Map<String, double> categoryTotals = {};
    
    for (var expense in expenses) {
      if (categoryTotals.containsKey(expense.category)) {
        categoryTotals[expense.category] = categoryTotals[expense.category]! + expense.amount;
      } else {
        categoryTotals[expense.category] = expense.amount;
      }
    }
    
    return categoryTotals;
  }

  // Obtenir les dépenses par jour
  Future<Map<DateTime, double>> getExpensesByDay() async {
    final expenses = await getAllExpenses();
    final Map<DateTime, double> dailyTotals = {};
    
    for (var expense in expenses) {
      // Normaliser la date pour ignorer l'heure
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      
      if (dailyTotals.containsKey(date)) {
        dailyTotals[date] = dailyTotals[date]! + expense.amount;
      } else {
        dailyTotals[date] = expense.amount;
      }
    }
    
    return dailyTotals;
  }

  // Calculer le total des dépenses
  Future<double> getTotalExpenses() async {
    final expenses = await getAllExpenses();
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }
}