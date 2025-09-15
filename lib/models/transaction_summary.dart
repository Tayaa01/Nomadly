class TransactionSummary {
  final double totalOriginal;
  final double totalConverted;
  final double totalTaxRefund;
  final int count;
  final DateTime date;

  TransactionSummary({
    required this.totalOriginal,
    required this.totalConverted,
    required this.totalTaxRefund,
    required this.count,
    required this.date,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalOriginal: json['totalOriginal']?.toDouble() ?? 0.0,
      totalConverted: json['totalConverted']?.toDouble() ?? 0.0,
      totalTaxRefund: json['totalTaxRefund']?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }

  @override
  String toString() {
    return 'TransactionSummary{totalOriginal: $totalOriginal, totalConverted: $totalConverted, totalTaxRefund: $totalTaxRefund, count: $count, date: $date}';
  }
}
