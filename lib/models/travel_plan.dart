import 'package:intl/intl.dart';

class DayContent {
  final String content;

  DayContent({required this.content});

  factory DayContent.fromJson(Map<String, dynamic> json) {
    return DayContent(
      content: json['content'] ?? '',
    );
  }
}

class TravelPlan {
  final String id;
  final String userId;
  final String country;
  final int days;
  final DateTime startDate;
  final double budget;
  final bool isBudgetOptimized;
  final List<DayContent> daysContent;
  final String additionalInfo;
  final double estimatedBudget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? weatherData; // Added for weather forecast

  TravelPlan({
    required this.id,
    required this.userId,
    required this.country,
    required this.days,
    required this.startDate,
    required this.budget,
    required this.isBudgetOptimized,
    required this.daysContent,
    required this.additionalInfo,
    required this.estimatedBudget,
    required this.createdAt,
    required this.updatedAt,
    this.weatherData, // Added
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? weatherData;
    if (json['weatherData'] != null && json['weatherData'] is Map) {
      if (json['weatherData']['forecast'] != null && json['weatherData']['forecast'] is List) {
        weatherData = Map<String, dynamic>.from(json['weatherData']);
      } else {
        weatherData = Map<String, dynamic>.from(json['weatherData']);
        weatherData['forecast'] = [];
      }
    }

    return TravelPlan(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      country: json['country'] ?? '',
      days: json['days'] ?? 0,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      budget: (json['budget'] ?? 0).toDouble(),
      isBudgetOptimized: json['isBudgetOptimized'] ?? false,
      daysContent: (json['daysContent'] as List<dynamic>?)
          ?.map((day) => DayContent.fromJson(day))
          .toList() ?? [],
      additionalInfo: json['additionalInfo'] ?? '',
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      weatherData: weatherData, // Added
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'userId': userId,
      'country': country,
      'days': days,
      'startDate': startDate.toIso8601String(),
      'budget': budget,
      'isBudgetOptimized': isBudgetOptimized,
      'daysContent': daysContent.map((day) => {'content': day.content}).toList(),
      'additionalInfo': additionalInfo,
      'estimatedBudget': estimatedBudget,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'weatherData': weatherData, // Added
    };
    return data;
  }

  String get formattedStartDate {
    return DateFormat('yyyy-MM-dd').format(startDate);
  }

  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd').format(createdAt);
  }
}