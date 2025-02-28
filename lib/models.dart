class TravelPlan {
  final String tripName;
  final double budget;
  final Coordinates origin;
  final String destination;
  final String theme;
  final String duration;
  final List<DayItinerary> days;

  TravelPlan({
    required this.tripName,
    required this.budget,
    required this.origin,
    required this.destination,
    required this.theme,
    required this.duration,
    required this.days,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      tripName: json['trip_name'],
      budget: json['budget'].toDouble(),
      origin: Coordinates.fromJson(json['origin_coordinates']),
      destination: json['destination'],
      theme: json['theme'],
      duration: json['duration'],
      days: (json['day_itinerary'] as List)
          .map((d) => DayItinerary.fromJson(d))
          .toList(),
    );
  }
}

class DayItinerary {
  final int day;
  final String title;
  final String description;
  final List<String> activities;
  final double estimatedCost;

  DayItinerary({
    required this.day,
    required this.title,
    required this.description,
    required this.activities,
    required this.estimatedCost,
  });

  factory DayItinerary.fromJson(Map<String, dynamic> json) {
    return DayItinerary(
      day: json['day'],
      title: json['title'],
      description: json['description'],
      activities: List<String>.from(json['activities']),
      estimatedCost: json['estimated_cost'].toDouble(),
    );
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}