class TravelRequest {
  final String country;
  final String city; // Add city field
  final double? budget;
  final int days;
  final DateTime startDate;

  TravelRequest({
    required this.country,
    required this.city, // Add city parameter
    this.budget,
    required this.days,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
    'country': country,
    'city': city, // Add city to json
    'budget': budget,
    'days': days,
    'startDate': startDate.toIso8601String(),
  };

  @override
  String toString() {
    return 'TravelRequest(country: $country, city: $city, budget: $budget, days: $days, startDate: $startDate)';
  }
}