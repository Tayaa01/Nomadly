// Complete code for the Transaction model
class Transaction {
  final String? id;
  final double originalAmount;
  final String originalCurrency;
  final String description;
  final DateTime createdAt;
  final double? convertedAmount;
  final String? convertedCurrency;

  Transaction({
    this.id,
    required this.originalAmount,
    required this.originalCurrency,
    required this.description,
    required this.createdAt, 
    this.convertedAmount,
    this.convertedCurrency,
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
      convertedAmount: (json['convertedAmount'] is int)
          ? (json['convertedAmount'] as int).toDouble()
          : json['convertedAmount'].toDouble(),
      convertedCurrency: json['convertedCurrency'],
      

    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'convertedAmount': convertedAmount,
      'convertedCurrency': convertedCurrency,
    };
  }
}