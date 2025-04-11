class TravelRequest {
  final String country;
  final double budget;
  final int days;
  final DateTime startDate;  // Added field

  TravelRequest({
    required this.country,
    required this.budget,
    required this.days,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
    'country': country,
    'budget': budget,
    'days': days,
    'startDate': startDate.toIso8601String(),  // Include start date
  };

  @override
  String toString() {
    return 'TravelRequest(country: $country, budget: $budget, days: $days, startDate: $startDate)';
  }
}