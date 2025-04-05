import 'package:flutter/material.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../models/settlement_method.dart';
import '../services/travel_group_service.dart';
import '../utils/settlement_optimizer.dart';

class TravelGroupViewModel extends ChangeNotifier {
  final TravelGroupService _travelGroupService = TravelGroupService();
  
  List<TravelGroup> _groups = [];
  TravelGroup? _currentGroup;
  List<SharedExpense> _sharedExpenses = [];
  List<Settlement> _settlements = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<TravelGroup> get groups => _groups;
  TravelGroup? get currentGroup => _currentGroup;
  List<SharedExpense> get sharedExpenses => _sharedExpenses;
  List<Settlement> get settlements => _settlements;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Initialiser le ViewModel
  Future<void> init() async {
    await loadGroups();
  }

  // Charger tous les groupes
  Future<void> loadGroups() async {
    _setLoading(true);
    try {
      _groups = await _travelGroupService.getAllGroups();
      _groups.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Tri par date de création décroissante
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des groupes: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Définir le groupe courant et charger ses dépenses
  Future<void> setCurrentGroup(String groupId) async {
    _setLoading(true);
    try {
      _currentGroup = await _travelGroupService.getGroupById(groupId);
      if (_currentGroup != null) {
        await loadSharedExpensesForCurrentGroup();
        await loadSettlementsForCurrentGroup();
      }
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du groupe: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Charger les dépenses partagées pour le groupe courant
  Future<void> loadSharedExpensesForCurrentGroup() async {
    if (_currentGroup == null) return;
    
    _setLoading(true);
    try {
      _sharedExpenses = await _travelGroupService.getSharedExpensesForGroup(_currentGroup!.id);
      _sharedExpenses.sort((a, b) => b.date.compareTo(a.date)); // Tri par date décroissante
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des dépenses: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Charger les règlements pour le groupe courant
  Future<void> loadSettlementsForCurrentGroup() async {
    if (_currentGroup == null) return;
    
    _setLoading(true);
    try {
      _settlements = await _travelGroupService.getSettlementsForGroup(_currentGroup!.id);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des règlements: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter un nouveau groupe
  Future<void> addGroup(TravelGroup group) async {
    _setLoading(true);
    try {
      await _travelGroupService.addGroup(group);
      await loadGroups();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout du groupe: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour un groupe existant
  Future<void> updateGroup(TravelGroup group) async {
    _setLoading(true);
    try {
      await _travelGroupService.updateGroup(group);
      await loadGroups();
      if (_currentGroup != null && _currentGroup!.id == group.id) {
        _currentGroup = group;
      }
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du groupe: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un groupe
  Future<void> deleteGroup(String groupId) async {
    _setLoading(true);
    try {
      await _travelGroupService.deleteGroup(groupId);
      await loadGroups();
      if (_currentGroup != null && _currentGroup!.id == groupId) {
        _currentGroup = null;
        _sharedExpenses = [];
        _settlements = [];
      }
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression du groupe: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter un membre au groupe courant
  Future<void> addMemberToCurrentGroup(GroupMember member) async {
    if (_currentGroup == null) return;
    
    _setLoading(true);
    try {
      final updatedMembers = List<GroupMember>.from(_currentGroup!.members);
      updatedMembers.add(member);
      
      final updatedGroup = _currentGroup!.copyWith(members: updatedMembers);
      await _travelGroupService.updateGroup(updatedGroup);
      
      _currentGroup = updatedGroup;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout du membre: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un membre du groupe courant
  Future<void> removeMemberFromCurrentGroup(String memberId) async {
    if (_currentGroup == null) return;
    
    _setLoading(true);
    try {
      final updatedMembers = _currentGroup!.members.where((m) => m.id != memberId).toList();
      
      final updatedGroup = _currentGroup!.copyWith(members: updatedMembers);
      await _travelGroupService.updateGroup(updatedGroup);
      
      _currentGroup = updatedGroup;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression du membre: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter une nouvelle dépense partagée
  Future<void> addSharedExpense(SharedExpense expense) async {
    _setLoading(true);
    try {
      await _travelGroupService.addSharedExpense(expense);
      await loadSharedExpensesForCurrentGroup();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout de la dépense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour une dépense partagée existante
  Future<void> updateSharedExpense(SharedExpense expense) async {
    _setLoading(true);
    try {
      await _travelGroupService.updateSharedExpense(expense);
      await loadSharedExpensesForCurrentGroup();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de la dépense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une dépense partagée
  Future<void> deleteSharedExpense(String expenseId) async {
    _setLoading(true);
    try {
      await _travelGroupService.deleteSharedExpense(expenseId);
      await loadSharedExpensesForCurrentGroup();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de la dépense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Calculer les règlements optimaux pour le groupe courant
  Future<void> calculateSettlements() async {
    if (_currentGroup == null) return;
    
    _setLoading(true);
    try {
      // Récupérer les règlements existants qui sont déjà marqués comme réglés
      final existingSettlements = await _travelGroupService.getSettlementsForGroup(_currentGroup!.id);
      final settledSettlements = existingSettlements.where((s) => s.isSettled).toList();
      
      // Calculer les balances actuelles
      final memberIds = _currentGroup!.members.map((m) => m.id).toList();
      final balances = SettlementOptimizer.calculateBalances(_sharedExpenses, memberIds);
      
      // Calculer les règlements optimaux
      final optimalSettlements = SettlementOptimizer.calculateOptimalSettlements(balances);
      
      // Combiner les règlements réglés avec les nouveaux règlements optimaux
      _settlements = [...settledSettlements, ...optimalSettlements];
      
      // Sauvegarder les nouveaux règlements
      for (var settlement in optimalSettlements) {
        await _travelGroupService.addSettlement(settlement);
      }
      
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors du calcul des règlements: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Marquer un règlement comme effectué
  Future<void> markSettlementAsSettled(
    String settlementId, {
    SettlementMethod? method,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final settlement = _settlements.firstWhere((s) => s.id == settlementId);
      final updatedSettlement = settlement.markAsSettled(
        method: method,
        notes: notes,
      );
      await _travelGroupService.updateSettlement(updatedSettlement);
      await loadSettlementsForCurrentGroup();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du règlement: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Obtenir le solde d'un membre
  double getMemberBalance(String memberId) {
    if (_currentGroup == null) return 0.0;
    
    double balance = 0.0;
    
    // Calculer le solde en fonction des dépenses
    for (var expense in _sharedExpenses) {
      // Si le membre est le payeur, ajouter le montant total
      if (expense.payerId == memberId) {
        balance += expense.amount;
      }
      
      // Soustraire la part du membre
      if (expense.splitAmounts.containsKey(memberId)) {
        balance -= expense.splitAmounts[memberId]!;
      }
    }
    
    return balance;
  }

  // Méthode utilitaire pour définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}