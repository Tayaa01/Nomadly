class SavingSummary {
  final double totalSavings;
  final int count;
  final DateTime date;

  SavingSummary({
    required this.totalSavings,
    required this.count,
    required this.date,
  });

  factory SavingSummary.fromJson(Map<String, dynamic> json) {
    return SavingSummary(
      totalSavings: json['totalSavings']?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }

  @override
  String toString() {
    return 'SavingSummary{totalSavings: $totalSavings, count: $count, date: $date}';
  }
}
