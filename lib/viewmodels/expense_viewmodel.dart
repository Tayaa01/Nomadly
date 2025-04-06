import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Initialiser le ViewModel
  Future<void> init() async {
    await loadExpenses();
  }

  // Charger toutes les dépenses
  Future<void> loadExpenses() async {
    _setLoading(true);
    try {
      _expenses = await _expenseService.getAllExpenses();
      _expenses.sort((a, b) => b.date.compareTo(a.date)); // Tri par date décroissante
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des dépenses: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter une nouvelle dépense
  Future<void> addExpense(Expense expense) async {
    _setLoading(true);
    try {
      await _expenseService.addExpense(expense);
      await loadExpenses(); // Recharger la liste
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout de la dépense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour une dépense existante
  Future<void> updateExpense(Expense expense) async {
    _setLoading(true);
    try {
      await _expenseService.updateExpense(expense);
      await loadExpenses(); // Recharger la liste
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de la dépense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une dépense
  Future<void> deleteExpense(String id) async {
    _setLoading(true);
    try {
      await _expenseService.deleteExpense(id);
      await loadExpenses(); // Recharger la liste
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de la dépense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Obtenir les dépenses par catégorie pour le graphique
  Future<Map<String, double>> getExpensesByCategory() async {
    try {
      return await _expenseService.getExpensesByCategory();
    } catch (e) {
      _errorMessage = 'Erreur lors du calcul des dépenses par catégorie: ${e.toString()}';
      return {};
    }
  }

  // Obtenir les dépenses par jour pour le graphique
  Future<Map<DateTime, double>> getExpensesByDay() async {
    try {
      return await _expenseService.getExpensesByDay();
    } catch (e) {
      _errorMessage = 'Erreur lors du calcul des dépenses par jour: ${e.toString()}';
      return {};
    }
  }

  // Calculer le total des dépenses
  Future<double> getTotalExpenses() async {
    try {
      return await _expenseService.getTotalExpenses();
    } catch (e) {
      _errorMessage = 'Erreur lors du calcul du total des dépenses: ${e.toString()}';
      return 0.0;
    }
  }

  // Méthode utilitaire pour définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}