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
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
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
      estimatedBudget: (json['estimatedBudget'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  String get formattedStartDate {
    return DateFormat('yyyy-MM-dd').format(startDate);
  }

  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd').format(createdAt);
  }
}