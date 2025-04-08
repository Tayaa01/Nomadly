// Complete code for the Transaction model
class Transaction {
  final String? id;
  final double originalAmount;
  final String originalCurrency;
  final String description;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.originalAmount,
    required this.originalCurrency,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'],
      originalAmount: (json['originalAmount'] is int)
          ? (json['originalAmount'] as int).toDouble()
          : json['originalAmount'].toDouble(),
      originalCurrency: json['originalCurrency'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}