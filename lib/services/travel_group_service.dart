import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/travel_group.dart';
import '../models/shared_expense.dart';

class TravelGroupService {
  static const String _groupsStorageKey = 'travel_groups';
  static const String _sharedExpensesStorageKey = 'shared_expenses';
  static const String _settlementsStorageKey = 'settlements';

  // Récupérer tous les groupes de voyage
  Future<List<TravelGroup>> getAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_groupsStorageKey) ?? [];
    
    return groupsJson
        .map((json) => TravelGroup.fromMap(jsonDecode(json)))
        .toList();
  }

  // Récupérer un groupe par son ID
  Future<TravelGroup?> getGroupById(String groupId) async {
    final groups = await getAllGroups();
    try {
      return groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  // Ajouter un nouveau groupe
  Future<void> addGroup(TravelGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_groupsStorageKey) ?? [];
    
    groupsJson.add(jsonEncode(group.toMap()));
    await prefs.setStringList(_groupsStorageKey, groupsJson);
  }

  // Mettre à jour un groupe existant
  Future<void> updateGroup(TravelGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_groupsStorageKey) ?? [];
    
    final index = groupsJson.indexWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == group.id;
    });
    
    if (index != -1) {
      groupsJson[index] = jsonEncode(group.toMap());
      await prefs.setStringList(_groupsStorageKey, groupsJson);
    }
  }

  // Supprimer un groupe
  Future<void> deleteGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_groupsStorageKey) ?? [];
    
    final filteredGroups = groupsJson.where((json) {
      final map = jsonDecode(json);
      return map['id'] != groupId;
    }).toList();
    
    await prefs.setStringList(_groupsStorageKey, filteredGroups);
    
    // Supprimer également toutes les dépenses associées à ce groupe
    await _deleteExpensesForGroup(groupId);
  }

  // Récupérer toutes les dépenses partagées
  Future<List<SharedExpense>> getAllSharedExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_sharedExpensesStorageKey) ?? [];
    
    return expensesJson
        .map((json) => SharedExpense.fromMap(jsonDecode(json)))
        .toList();
  }

  // Récupérer les dépenses partagées pour un groupe spécifique
  Future<List<SharedExpense>> getSharedExpensesForGroup(String groupId) async {
    final allExpenses = await getAllSharedExpenses();
    return allExpenses.where((expense) => expense.groupId == groupId).toList();
  }

  // Ajouter une nouvelle dépense partagée
  Future<void> addSharedExpense(SharedExpense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_sharedExpensesStorageKey) ?? [];
    
    expensesJson.add(jsonEncode(expense.toMap()));
    await prefs.setStringList(_sharedExpensesStorageKey, expensesJson);
  }

  // Mettre à jour une dépense partagée existante
  Future<void> updateSharedExpense(SharedExpense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_sharedExpensesStorageKey) ?? [];
    
    final index = expensesJson.indexWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == expense.id;
    });
    
    if (index != -1) {
      expensesJson[index] = jsonEncode(expense.toMap());
      await prefs.setStringList(_sharedExpensesStorageKey, expensesJson);
    }
  }

  // Supprimer une dépense partagée
  Future<void> deleteSharedExpense(String expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_sharedExpensesStorageKey) ?? [];
    
    final filteredExpenses = expensesJson.where((json) {
      final map = jsonDecode(json);
      return map['id'] != expenseId;
    }).toList();
    
    await prefs.setStringList(_sharedExpensesStorageKey, filteredExpenses);
  }

  // Supprimer toutes les dépenses d'un groupe
  Future<void> _deleteExpensesForGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_sharedExpensesStorageKey) ?? [];
    
    final filteredExpenses = expensesJson.where((json) {
      final map = jsonDecode(json);
      return map['groupId'] != groupId;
    }).toList();
    
    await prefs.setStringList(_sharedExpensesStorageKey, filteredExpenses);
  }

  // Récupérer tous les règlements
  Future<List<Settlement>> getAllSettlements() async {
    final prefs = await SharedPreferences.getInstance();
    final settlementsJson = prefs.getStringList(_settlementsStorageKey) ?? [];
    
    return settlementsJson
        .map((json) => Settlement.fromMap(jsonDecode(json)))
        .toList();
  }

  // Récupérer les règlements pour un groupe spécifique
  Future<List<Settlement>> getSettlementsForGroup(String groupId) async {
    final allSettlements = await getAllSettlements();
    final groupMemberIds = (await getGroupById(groupId))?.members.map((m) => m.id).toList() ?? [];
    
    return allSettlements.where((settlement) => 
      groupMemberIds.contains(settlement.fromMemberId) && 
      groupMemberIds.contains(settlement.toMemberId)
    ).toList();
  }

  // Ajouter un nouveau règlement
  Future<void> addSettlement(Settlement settlement) async {
    final prefs = await SharedPreferences.getInstance();
    final settlementsJson = prefs.getStringList(_settlementsStorageKey) ?? [];
    
    settlementsJson.add(jsonEncode(settlement.toMap()));
    await prefs.setStringList(_settlementsStorageKey, settlementsJson);
  }

  // Mettre à jour un règlement existant
  Future<void> updateSettlement(Settlement settlement) async {
    final prefs = await SharedPreferences.getInstance();
    final settlementsJson = prefs.getStringList(_settlementsStorageKey) ?? [];
    
    final index = settlementsJson.indexWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == settlement.id;
    });
    
    if (index != -1) {
      settlementsJson[index] = jsonEncode(settlement.toMap());
      await prefs.setStringList(_settlementsStorageKey, settlementsJson);
    }
  }

  // Calculer qui doit combien à qui dans un groupe avec un algorithme optimisé
  Future<List<Settlement>> calculateSettlements(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return [];
    
    final expenses = await getSharedExpensesForGroup(groupId);
    final Map<String, double> balances = {};
    
    // Initialiser les soldes à zéro pour tous les membres
    for (var member in group.members) {
      balances[member.id] = 0.0;
    }
    
    // Calculer les soldes en fonction des dépenses
    for (var expense in expenses) {
      // Ajouter le montant total au payeur
      balances[expense.payerId] = (balances[expense.payerId] ?? 0) + expense.amount;
      
      // Soustraire les parts de chaque membre
      expense.splitAmounts.forEach((memberId, amount) {
        balances[memberId] = (balances[memberId] ?? 0) - amount;
      });
    }
    
    // Filtrer les soldes proches de zéro (pour éviter les erreurs d'arrondi)
    balances.removeWhere((key, value) => value.abs() < 0.01);
    
    // Créer les règlements pour équilibrer les soldes
    List<Settlement> settlements = [];
    
    // Optimisation: utiliser l'algorithme de minimisation des transactions
    // Étape 1: Séparer les débiteurs et créditeurs
    List<MapEntry<String, double>> debtors = balances.entries
        .where((entry) => entry.value < 0)
        .map((entry) => MapEntry(entry.key, -entry.value)) // Convertir en valeur positive
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Trier par dette décroissante
    
    List<MapEntry<String, double>> creditors = balances.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Trier par crédit décroissant
    
    // Étape 2: Appliquer l'algorithme glouton pour minimiser les transactions
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      // Prendre les personnes avec les plus grandes dettes et crédits
      final largestDebtor = debtors.first;
      final largestCreditor = creditors.first;
      
      // Déterminer le montant à régler
      final amountToSettle = min(largestDebtor.value, largestCreditor.value);
      
      if (amountToSettle > 0.01) { // Ignorer les très petits montants
        // Créer un règlement
        settlements.add(Settlement(
          fromMemberId: largestDebtor.key,
          toMemberId: largestCreditor.key,
          amount: amountToSettle,
          currency: 'EUR', // Utiliser la devise par défaut
        ));
        
        // Mettre à jour les soldes
        debtors[0] = MapEntry(largestDebtor.key, largestDebtor.value - amountToSettle);
        creditors[0] = MapEntry(largestCreditor.key, largestCreditor.value - amountToSettle);
        
        // Retirer les personnes dont le solde est réglé
        if (debtors[0].value < 0.01) {
          debtors.removeAt(0);
        }
        
        if (creditors[0].value < 0.01) {
          creditors.removeAt(0);
        }
        
        // Retrier les listes si nécessaire
        if (debtors.isNotEmpty) {
          debtors.sort((a, b) => b.value.compareTo(a.value));
        }
        
        if (creditors.isNotEmpty) {
          creditors.sort((a, b) => b.value.compareTo(a.value));
        }
      } else {
        // Éviter les boucles infinies avec des montants très petits
        break;
      }
    }
    
    return settlements;
  }

  // Update the clearSettlementsForGroup method to be more careful
  Future<void> clearSettlementsForGroup(String groupId) async {
    try {
      // First get all settlements for the group
      final allSettlements = await getSettlementsForGroup(groupId);
      
      // Only delete unsettled settlements
      final unsettledSettlements = allSettlements.where((s) => !s.isSettled).toList();
      
      // Delete only unsettled settlements
      for (var settlement in unsettledSettlements) {
        await deleteSettlement(settlement.id);
      }
    } catch (e) {
      print('Error clearing settlements: $e');
      rethrow;
    }
  }

  // Add a new method to cleanupDuplicateSettlements
  Future<void> cleanupDuplicateSettlements(String groupId) async {
    try {
      // First get all settlements for the group
      final allSettlements = await getSettlementsForGroup(groupId);
      
      // Track unique fromMember-toMember pairs
      Map<String, List<Settlement>> settlementsByPair = {};
      
      // Group settlements by fromMember-toMember pairs
      for (var settlement in allSettlements) {
        String key = '${settlement.fromMemberId}-${settlement.toMemberId}';
        if (!settlementsByPair.containsKey(key)) {
          settlementsByPair[key] = [];
        }
        settlementsByPair[key]!.add(settlement);
      }
      
      // For each pair, keep only the most recent settlement (or the settled one)
      for (var pairSettlements in settlementsByPair.values) {
        if (pairSettlements.length > 1) {
          // Sort by date (most recent first)
          pairSettlements.sort((a, b) => b.date.compareTo(a.date));
          
          // Find settled settlements
          bool hasSettled = pairSettlements.any((s) => s.isSettled);
          
          if (hasSettled) {
            // Keep the most recent settled settlement
            var settledSettlements = pairSettlements.where((s) => s.isSettled).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            
            Settlement keepSettlement = settledSettlements.first;
            
            // Delete all others
            for (var settlement in pairSettlements) {
              if (settlement.id != keepSettlement.id) {
                await deleteSettlement(settlement.id);
              }
            }
          } else {
            // Keep only the most recent one (already sorted)
            Settlement keepSettlement = pairSettlements.first;
            
            // Delete all others
            for (var settlement in pairSettlements.skip(1)) {
              await deleteSettlement(settlement.id);
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up duplicate settlements: $e');
      rethrow;
    }
  }

  // Add this method if it doesn't exist
  Future<void> deleteSettlement(String settlementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settlementsJson = prefs.getStringList(_settlementsStorageKey) ?? [];
      
      // Filter out the settlement to delete
      final updatedSettlements = settlementsJson.where((json) {
        final map = jsonDecode(json);
        return map['id'] != settlementId;
      }).toList();
      
      // Save the updated list back to SharedPreferences
      await prefs.setStringList(_settlementsStorageKey, updatedSettlements);
    } catch (e) {
      print('Error deleting settlement: $e');
      rethrow;
    }
  }
}

// Fonction utilitaire pour prendre le minimum de deux nombres
double min(double a, double b) {
  return a < b ? a : b;
}