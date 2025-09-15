
/// Classe qui définit les options avancées pour la répartition des dépenses
class ExpenseSplitOptions {
  /// Indique si un membre est inclus dans la répartition
  final Map<String, bool> includedMembers;
  
  /// Montants personnalisés pour chaque membre (pour SplitType.custom)
  final Map<String, double> customAmounts;
  
  /// Pourcentages pour chaque membre (pour SplitType.percentage)
  final Map<String, double> percentages;
  
  /// Poids pour chaque membre (pour une nouvelle option de répartition pondérée)
  final Map<String, int> weights;

  ExpenseSplitOptions({
    Map<String, bool>? includedMembers,
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
    Map<String, int>? weights,
  }) : 
    includedMembers = includedMembers ?? {},
    customAmounts = customAmounts ?? {},
    percentages = percentages ?? {},
    weights = weights ?? {};

  /// Crée une copie de l'objet avec des modifications
  ExpenseSplitOptions copyWith({
    Map<String, bool>? includedMembers,
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
    Map<String, int>? weights,
  }) {
    return ExpenseSplitOptions(
      includedMembers: includedMembers ?? Map.from(this.includedMembers),
      customAmounts: customAmounts ?? Map.from(this.customAmounts),
      percentages: percentages ?? Map.from(this.percentages),
      weights: weights ?? Map.from(this.weights),
    );
  }

  /// Initialise les options pour tous les membres du groupe
  static ExpenseSplitOptions initializeForMembers(List<String> memberIds) {
    final includedMembers = <String, bool>{};
    final customAmounts = <String, double>{};
    final percentages = <String, double>{};
    final weights = <String, int>{};
    
    // Par défaut, tous les membres sont inclus avec des valeurs égales
    final equalPercentage = memberIds.isNotEmpty ? 100.0 / memberIds.length : 0.0;
    
    for (var memberId in memberIds) {
      includedMembers[memberId] = true;
      customAmounts[memberId] = 0.0;
      percentages[memberId] = equalPercentage;
      weights[memberId] = 1;
    }
    
    return ExpenseSplitOptions(
      includedMembers: includedMembers,
      customAmounts: customAmounts,
      percentages: percentages,
      weights: weights,
    );
  }

  /// Calcule les montants de répartition selon le type choisi
  Map<String, double> calculateSplitAmounts(SplitType splitType, double totalAmount) {
    switch (splitType) {
      case SplitType.equal:
        return _calculateEqualSplit(totalAmount);
      case SplitType.custom:
        return Map.from(customAmounts);
      case SplitType.percentage:
        return _calculatePercentageSplit(totalAmount);
      case SplitType.weighted:
        return _calculateWeightedSplit(totalAmount);
      }
  }

  /// Calcule une répartition égale entre les membres inclus
  Map<String, double> _calculateEqualSplit(double totalAmount) {
    final includedMemberIds = includedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (includedMemberIds.isEmpty) return {};
    
    final perPersonAmount = totalAmount / includedMemberIds.length;
    final Map<String, double> splits = {};
    
    for (var memberId in includedMemberIds) {
      splits[memberId] = perPersonAmount;
    }
    
    return splits;
  }

  /// Calcule une répartition par pourcentage
  Map<String, double> _calculatePercentageSplit(double totalAmount) {
    final Map<String, double> splits = {};
    
    includedMembers.forEach((memberId, isIncluded) {
      if (isIncluded && percentages.containsKey(memberId)) {
        splits[memberId] = totalAmount * (percentages[memberId]! / 100);
      } else {
        splits[memberId] = 0.0;
      }
    });
    
    return splits;
  }

  /// Calcule une répartition pondérée (nouvelle option)
  Map<String, double> _calculateWeightedSplit(double totalAmount) {
    final Map<String, double> splits = {};
    int totalWeight = 0;
    
    // Calculer le poids total
    includedMembers.forEach((memberId, isIncluded) {
      if (isIncluded && weights.containsKey(memberId)) {
        totalWeight += weights[memberId]!;
      }
    });
    
    if (totalWeight == 0) return {};
    
    // Calculer la part de chaque membre
    includedMembers.forEach((memberId, isIncluded) {
      if (isIncluded && weights.containsKey(memberId)) {
        splits[memberId] = totalAmount * (weights[memberId]! / totalWeight);
      } else {
        splits[memberId] = 0.0;
      }
    });
    
    return splits;
  }
}

/// Extension de l'énumération SplitType pour ajouter un nouveau type de répartition
extension SplitTypeExtension on SplitType {
  static const values = [SplitType.equal, SplitType.custom, SplitType.percentage, SplitType.weighted];
  
  String get displayName {
    switch (this) {
      case SplitType.equal:
        return 'Égale';
      case SplitType.custom:
        return 'Personnalisée';
      case SplitType.percentage:
        return 'Pourcentage';
      case SplitType.weighted:
        return 'Pondérée';
      }
  }
  
  String get description {
    switch (this) {
      case SplitType.equal:
        return 'Divise la dépense également entre tous les membres';
      case SplitType.custom:
        return 'Définit un montant spécifique pour chaque membre';
      case SplitType.percentage:
        return 'Attribue un pourcentage de la dépense à chaque membre';
      case SplitType.weighted:
        return 'Répartit la dépense selon un poids attribué à chaque membre';
      }
  }
}

/// Ajouter un nouveau type de répartition à l'énumération existante
enum SplitType {
  equal, // Répartition égale entre tous les membres
  custom, // Montants personnalisés pour chaque membre
  percentage, // Pourcentage du total pour chaque membre
  weighted, // Répartition pondérée (nouvelle option)
}