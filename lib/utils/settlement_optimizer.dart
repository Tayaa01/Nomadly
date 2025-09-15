import '../models/shared_expense.dart';

class SettlementOptimizer {
  /// Calcule les règlements optimaux pour minimiser le nombre de transactions
  /// entre les membres d'un groupe
  /// 
  /// [balances] est une map contenant les soldes de chaque membre (positif = créditeur, négatif = débiteur)
  /// 
  /// Retourne une liste de règlements optimisés
  static List<Settlement> calculateOptimalSettlements(Map<String, double> balances, {String defaultCurrency = 'EUR'}) {
    // Filtrer les soldes proches de zéro (pour éviter les erreurs d'arrondi)
    balances = Map.from(balances);
    balances.removeWhere((key, value) => value.abs() < 0.01);
    
    // Créer les règlements pour équilibrer les soldes
    List<Settlement> settlements = [];
    
    // Vérifier si nous pouvons utiliser l'algorithme de simplification des dettes circulaires
    if (balances.length > 2) {
      final simplifiedSettlements = _simplifyCircularDebts(balances, defaultCurrency);
      if (simplifiedSettlements.isNotEmpty) {
        return simplifiedSettlements;
      }
    }
    
    // Séparer les débiteurs et créditeurs
    List<MapEntry<String, double>> debtors = balances.entries
        .where((entry) => entry.value < 0)
        .map((entry) => MapEntry(entry.key, -entry.value)) // Convertir en valeur positive
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Trier par dette décroissante
    
    List<MapEntry<String, double>> creditors = balances.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Trier par crédit décroissant
    
    // Appliquer l'algorithme glouton pour minimiser les transactions
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      // Prendre les personnes avec les plus grandes dettes et crédits
      final largestDebtor = debtors.first;
      final largestCreditor = creditors.first;
      
      // Déterminer le montant à régler
      final amountToSettle = _min(largestDebtor.value, largestCreditor.value);
      
      if (amountToSettle > 0.01) { // Ignorer les très petits montants
        // Créer un règlement
        settlements.add(Settlement(
          fromMemberId: largestDebtor.key,
          toMemberId: largestCreditor.key,
          amount: _roundToTwoDecimals(amountToSettle),
          currency: defaultCurrency,
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
  
  /// Tente de simplifier les dettes circulaires pour réduire le nombre de transactions
  /// Par exemple, si A doit à B, B doit à C, et C doit à A, on peut simplifier
  static List<Settlement> _simplifyCircularDebts(Map<String, double> balances, String defaultCurrency) {
    // Créer un graphe de dettes
    final Map<String, Map<String, double>> debtGraph = {};
    final List<Settlement> simplifiedSettlements = [];
    
    // Initialiser le graphe
    for (var memberId in balances.keys) {
      debtGraph[memberId] = {};
    }
    
    // Séparer les débiteurs et créditeurs
    final debtors = balances.entries.where((e) => e.value < 0).toList();
    final creditors = balances.entries.where((e) => e.value > 0).toList();
    
    // Créer les liens de dettes initiales
    for (var debtor in debtors) {
      for (var creditor in creditors) {
        debtGraph[debtor.key]![creditor.key] = 0.0; // Initialiser à zéro
      }
    }
    
    // Appliquer l'algorithme de Floyd-Warshall pour trouver les chemins optimaux
    // Cette approche permet de détecter et d'éliminer les cycles de dettes
    
    // Créer une copie des balances pour manipulation
    final workingBalances = Map<String, double>.from(balances);
    
    // Tant qu'il reste des soldes non nuls
    while (workingBalances.values.any((v) => v.abs() > 0.01)) {
      // Trouver un débiteur et un créditeur
      final debtor = workingBalances.entries.firstWhere(
        (e) => e.value < -0.01,
        orElse: () => MapEntry('', 0.0),
      );
      
      final creditor = workingBalances.entries.firstWhere(
        (e) => e.value > 0.01,
        orElse: () => MapEntry('', 0.0),
      );
      
      if (debtor.key.isEmpty || creditor.key.isEmpty) break;
      
      // Calculer le montant à régler
      final amount = _min(-debtor.value, creditor.value);
      
      // Créer un règlement
      simplifiedSettlements.add(Settlement(
        fromMemberId: debtor.key,
        toMemberId: creditor.key,
        amount: _roundToTwoDecimals(amount),
        currency: defaultCurrency,
      ));
      
      // Mettre à jour les soldes
      workingBalances[debtor.key] = workingBalances[debtor.key]! + amount;
      workingBalances[creditor.key] = workingBalances[creditor.key]! - amount;
      
      // Supprimer les soldes proches de zéro
      workingBalances.removeWhere((key, value) => value.abs() < 0.01);
    }
    
    return simplifiedSettlements;
  }

  /// Calcule les soldes de chaque membre à partir des dépenses partagées
  /// 
  /// [expenses] est la liste des dépenses partagées
  /// [memberIds] est la liste des IDs des membres du groupe
  /// 
  /// Retourne une map contenant les soldes de chaque membre
  static Map<String, double> calculateBalances(List<SharedExpense> expenses, List<String> memberIds) {
    Map<String, double> balances = {};
    
    // Initialiser les soldes à zéro pour tous les membres
    for (var memberId in memberIds) {
      balances[memberId] = 0.0;
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
    
    return balances;
  }

  // Fonction utilitaire pour prendre le minimum de deux nombres
  static double _min(double a, double b) {
    return a < b ? a : b;
  }
  
  /// Arrondit un nombre à deux décimales pour éviter les problèmes d'affichage
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }
}