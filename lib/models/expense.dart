import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String currency;

  Expense({
    String? id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.currency,
  }) : id = id ?? const Uuid().v4();

  // Méthode pour créer une copie d'une dépense avec des modifications
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      currency: currency ?? this.currency,
    );
  }

  // Méthode pour convertir l'objet en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'currency': currency,
    };
  }

  // Méthode pour créer un objet à partir d'un Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
      currency: map['currency'],
    );
  }
}

// List of predefined expense categories
class ExpenseCategories {
  static const String hotel = 'Accommodation';
  static const String transport = 'Transport';
  static const String food = 'Food';
  static const String activities = 'Activities';
  static const String shopping = 'Shopping';
  static const String other = 'Other';

  static List<String> getAllCategories() {
    return [hotel, transport, food, activities, shopping, other];
  }

  // Méthode pour obtenir l'icône correspondant à une catégorie
  static String getIconForCategory(String category) {
    switch (category) {
      case hotel:
        return 'hotel';
      case transport:
        return 'directions_car';
      case food:
        return 'restaurant';
      case activities:
        return 'local_activity';
      case shopping:
        return 'shopping_bag';
      case other:
        return 'more_horiz';
      default:
        return 'help_outline';
    }
  }
}