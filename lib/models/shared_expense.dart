import 'package:uuid/uuid.dart';
import 'expense.dart';
import 'settlement_method.dart';

class SharedExpense extends Expense {
  final String groupId; // ID du groupe de voyage
  final String payerId; // ID du membre qui a payé
  final Map<String, double> splitAmounts; // Map des ID des membres et leurs parts
  final SplitType splitType; // Type de répartition

  SharedExpense({
    String? id,
    required double amount,
    required String category,
    required DateTime date,
    required String description,
    required String currency,
    required this.groupId,
    required this.payerId,
    required this.splitAmounts,
    required this.splitType,
  }) : super(
          id: id,
          amount: amount,
          category: category,
          date: date,
          description: description,
          currency: currency,
        );

  // Méthode pour créer une copie d'une dépense partagée avec des modifications
  @override
  SharedExpense copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    String? currency,
    String? groupId,
    String? payerId,
    Map<String, double>? splitAmounts,
    SplitType? splitType,
  }) {
    return SharedExpense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      groupId: groupId ?? this.groupId,
      payerId: payerId ?? this.payerId,
      splitAmounts: splitAmounts ?? this.splitAmounts,
      splitType: splitType ?? this.splitType,
    );
  }

  // Méthode pour convertir l'objet en Map pour le stockage
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'groupId': groupId,
      'payerId': payerId,
      'splitAmounts': splitAmounts,
      'splitType': splitType.toString(),
    };
  }

  // Méthode pour créer un objet à partir d'un Map
  factory SharedExpense.fromMap(Map<String, dynamic> map) {
    return SharedExpense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
      currency: map['currency'],
      groupId: map['groupId'],
      payerId: map['payerId'],
      splitAmounts: Map<String, double>.from(map['splitAmounts']),
      splitType: SplitType.values.firstWhere(
        (e) => e.toString() == map['splitType'],
        orElse: () => SplitType.equal,
      ),
    );
  }

  // Calculer le montant que chaque membre doit au payeur
  Map<String, double> calculateDebts() {
    final Map<String, double> debts = {};
    
    splitAmounts.forEach((memberId, amount) {
      if (memberId != payerId && amount > 0) {
        debts[memberId] = amount;
      }
    });
    
    return debts;
  }

  // Créer une répartition égale entre tous les membres
  static Map<String, double> createEqualSplit(List<String> memberIds, double amount) {
    final perPersonAmount = amount / memberIds.length;
    final Map<String, double> splits = {};
    
    for (var memberId in memberIds) {
      splits[memberId] = perPersonAmount;
    }
    
    return splits;
  }

  // Créer une répartition personnalisée
  static Map<String, double> createCustomSplit(Map<String, double> customAmounts) {
    return customAmounts;
  }

  // Créer une répartition par pourcentage
  static Map<String, double> createPercentageSplit(
      List<String> memberIds, Map<String, double> percentages, double totalAmount) {
    final Map<String, double> splits = {};
    
    percentages.forEach((memberId, percentage) {
      if (memberIds.contains(memberId)) {
        splits[memberId] = totalAmount * (percentage / 100);
      }
    });
    
    return splits;
  }
}

// Types de répartition des dépenses
enum SplitType {
  equal, // Répartition égale entre tous les membres
  custom, // Montants personnalisés pour chaque membre
  percentage, // Pourcentage du total pour chaque membre
  weighted, // Répartition pondérée selon des poids attribués
}

// Classe pour représenter un règlement entre deux membres
class Settlement {
  final String id;
  final String fromMemberId; // Membre qui doit de l'argent
  final String toMemberId; // Membre qui reçoit de l'argent
  final double amount;
  final String currency;
  final DateTime date;
  final bool isSettled;
  final String? notes; // Notes supplémentaires sur le règlement
  final SettlementMethod method; // Méthode de règlement

  Settlement({
    String? id,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.currency,
    DateTime? date,
    this.isSettled = false,
    this.notes,
    this.method = SettlementMethod.other,
  }) : 
    id = id ?? const Uuid().v4(),
    date = date ?? DateTime.now();

  // Méthode pour marquer un règlement comme effectué
  Settlement markAsSettled({
    SettlementMethod? method,
    String? notes,
  }) {
    return Settlement(
      id: id,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      currency: currency,
      date: date,
      isSettled: true,
      notes: notes ?? this.notes,
      method: method ?? this.method,
    );
  }

  // Méthode pour convertir l'objet en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromMemberId': fromMemberId,
      'toMemberId': toMemberId,
      'amount': amount,
      'currency': currency,
      'date': date.millisecondsSinceEpoch,
      'isSettled': isSettled,
      'notes': notes,
      'method': method.toString(),
    };
  }

  // Méthode pour créer un objet à partir d'un Map
  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'],
      fromMemberId: map['fromMemberId'],
      toMemberId: map['toMemberId'],
      amount: map['amount'],
      currency: map['currency'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isSettled: map['isSettled'] ?? false,
      notes: map['notes'],
      method: map['method'] != null
          ? SettlementMethod.values.firstWhere(
              (e) => e.toString() == map['method'],
              orElse: () => SettlementMethod.other,
            )
          : SettlementMethod.other,
    );
  }
}