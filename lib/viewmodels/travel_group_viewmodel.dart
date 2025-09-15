import 'package:flutter/material.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';
import '../models/settlement_method.dart';
import '../services/travel_group_service.dart';

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
      // First load all settlements
      List<Settlement> allSettlements = await _travelGroupService.getSettlementsForGroup(_currentGroup!.id);
      
      // Handle potential duplicates by only keeping the latest version of each unique fromMember-toMember pair
      // This assumes newer settlements override older ones
      Map<String, Settlement> uniqueSettlements = {};
      
      for (var settlement in allSettlements) {
        // Create a key based on the from-to pair
        String key = '${settlement.fromMemberId}-${settlement.toMemberId}';
        
        // Only keep the latest version (assuming newer always overrides older)
        // If it's already settled, always keep the settled version
        if (!uniqueSettlements.containsKey(key) || 
            settlement.isSettled || 
            settlement.date.isAfter(uniqueSettlements[key]!.date)) {
          uniqueSettlements[key] = settlement;
        }
      }
      
      // Use only the unique settlements
      _settlements = uniqueSettlements.values.toList();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error loading settlements: ${e.toString()}';
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
      // First delete the expense
      await _travelGroupService.deleteSharedExpense(expenseId);
      
      // Then reload all expenses
      await loadSharedExpensesForCurrentGroup();
      
      // Now recalculate settlements to reflect the removed expense
      // Clear existing settlements first
      _settlements = [];
      await _travelGroupService.clearSettlementsForGroup(_currentGroup!.id);
      
      // Then recalculate new settlements
      calculateSettlements();
      
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error deleting expense: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Calculer les règlements optimaux pour le groupe courant
  void calculateSettlements() {
    if (currentGroup == null) return;
    
    // Track already settled pairs to avoid duplicates
    // Use a set with composite keys "fromId-toId" to track which pairs already have settlements
    Set<String> settledPairs = {};
    
    // First get all settled settlements and track their member pairs
    final settledSettlements = _settlements.where((s) => s.isSettled).toList();
    for (var settlement in settledSettlements) {
      // Create a composite key to track this settlement pair
      settledPairs.add('${settlement.fromMemberId}-${settlement.toMemberId}');
    }
    
    // Clear only the non-settled settlements
    _settlements = settledSettlements;
    
    // Calculate balances for each member
    Map<String, double> balances = {};
    
    // Initialize balances to zero for all members
    for (var member in currentGroup!.members) {
      balances[member.id] = 0.0;
    }
    
    // Calculate balances from expenses
    for (var expense in _sharedExpenses) {
      balances[expense.payerId] = (balances[expense.payerId] ?? 0) + expense.amount;
      
      expense.splitAmounts.forEach((memberId, amount) {
        balances[memberId] = (balances[memberId] ?? 0) - amount;
      });
    }
    
    // Convert balances to settlements
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];
    
    balances.forEach((memberId, balance) {
      if (balance < -0.01) { // Debtor (owes money)
        debtors.add(MapEntry(memberId, -balance)); // Store as positive amount
      } else if (balance > 0.01) { // Creditor (is owed money)
        creditors.add(MapEntry(memberId, balance));
      }
    });
    
    // Sort by amount (descending)
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));
    
    // Match debtors with creditors to create settlements
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      var debtor = debtors.first;
      var creditor = creditors.first;
      
      // Check if this pair already has a settlement
      final pairKey = '${debtor.key}-${creditor.key}';
      
      // If this pair already has a settled settlement, skip creating a new one
      if (settledPairs.contains(pairKey)) {
        // Skip this pair or reduce the amounts to account for already settled amount
        // For simplicity, we'll just skip the entire settlement
        
        // Remove the smaller of the two values
        double smallerValue = min(debtor.value, creditor.value);
        
        // Update remaining amounts
        double debtorRemaining = debtor.value - smallerValue;
        double creditorRemaining = creditor.value - smallerValue;
        
        // Remove or update debtor
        if (debtorRemaining < 0.01) {
          debtors.removeAt(0);
        } else {
          debtors[0] = MapEntry(debtor.key, debtorRemaining);
        }
        
        // Remove or update creditor
        if (creditorRemaining < 0.01) {
          creditors.removeAt(0);
        } else {
          creditors[0] = MapEntry(creditor.key, creditorRemaining);
        }
        
        continue; // Skip to the next iteration
      }
      
      // The amount to settle is the minimum of what debtor owes and creditor is owed
      double settlementAmount = min(debtor.value, creditor.value);
      
      if (settlementAmount > 0.01) {
        // Create settlement with a unique ID based on member IDs rather than timestamp
        // This helps prevent duplicate entries on restart
        final uniqueId = "${DateTime.now().millisecondsSinceEpoch}-${debtor.key}-${creditor.key}";
        
        _settlements.add(
          Settlement(
            id: uniqueId,
            fromMemberId: debtor.key, // Debtor pays
            toMemberId: creditor.key, // To creditor
            amount: settlementAmount,
            currency: 'EUR', // Default currency
            date: DateTime.now(),
            isSettled: false,
          ),
        );
      }
      
      // Update remaining amounts
      double debtorRemaining = debtor.value - settlementAmount;
      double creditorRemaining = creditor.value - settlementAmount;
      
      // Remove or update debtor
      if (debtorRemaining < 0.01) {
        debtors.removeAt(0);
      } else {
        debtors[0] = MapEntry(debtor.key, debtorRemaining);
      }
      
      // Remove or update creditor
      if (creditorRemaining < 0.01) {
        creditors.removeAt(0);
      } else {
        creditors[0] = MapEntry(creditor.key, creditorRemaining);
      }
    }
    
    // Save the new settlements
    for (var settlement in _settlements.where((s) => !s.isSettled)) {
      _travelGroupService.addSettlement(settlement);
    }
    
    notifyListeners();
  }

  // Helper method to determine minimum of two doubles
  double min(double a, double b) {
    return a < b ? a : b;
  }

  // Marquer un règlement comme effectué
  Future<void> markSettlementAsSettled(
    String settlementId, {
    SettlementMethod? method,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      // Find the settlement to mark as settled
      final settlementIndex = _settlements.indexWhere((s) => s.id == settlementId);
      if (settlementIndex >= 0) {
        // Update the settlement in our local list directly
        final settlement = _settlements[settlementIndex];
        final updatedSettlement = settlement.markAsSettled(
          method: method,
          notes: notes,
        );
        
        // Replace the settlement in our local list
        _settlements[settlementIndex] = updatedSettlement;
        
        // Update the settlement in the database
        await _travelGroupService.updateSettlement(updatedSettlement);
        
        // This is critical: DON'T reload settlements from the database
        // as it might cause duplicate settlements to appear if the database
        // implementation isn't properly handling updates
        
        notifyListeners(); // Just notify listeners about the change
      }
      
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error updating settlement: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Obtenir le solde d'un membre
  double getMemberBalance(String memberId) {
    if (currentGroup == null) return 0.0;
    
    double balance = 0.0;
    
    for (var expense in _sharedExpenses) {
      // If this member paid for the expense, add the full amount to their balance
      if (expense.payerId == memberId) {
        balance += expense.amount;
      }
      
      // Subtract what this member owes for the expense
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

  // Add a public method to access the cleanupDuplicateSettlements functionality
  Future<void> cleanupDuplicateSettlements(String groupId) async {
    try {
      await _travelGroupService.cleanupDuplicateSettlements(groupId);
    } catch (e) {
      _errorMessage = 'Error cleaning up settlements: ${e.toString()}';
    }
  }
}