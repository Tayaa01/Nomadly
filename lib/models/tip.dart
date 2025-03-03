import 'dart:convert';
import 'package:flutter/services.dart';

class Tip {
  final String content;
  final String category;
  final String country;

  Tip({required this.content, required this.category, required this.country});

  factory Tip.fromJson(String content, String country, String category) {
    return Tip(content: content, category: category, country: country);
  }
}

class TipsService {
  static Future<Map<String, dynamic>> loadTipsData() async {
    final String response = await rootBundle.loadString('tips.json');
    return json.decode(response);
  }

  static Future<List<Tip>> getTipsByCountry(String country) async {
    final data = await loadTipsData();
    final countryData = data[country] as Map<String, dynamic>;

    List<Tip> tips = [];

    countryData.forEach((category, tipsList) {
      final List<dynamic> categoryTips = tipsList as List<dynamic>;
      tips.addAll(
        categoryTips
            .map(
              (tip) => Tip(content: tip, category: category, country: country),
            )
            .toList(),
      );
    });

    return tips;
  }

  static Future<List<Tip>> getTipsByCountryAndCategory(
    String country,
    String category,
  ) async {
    final data = await loadTipsData();
    final countryData = data[country] as Map<String, dynamic>;

    if (!countryData.containsKey(category)) {
      return [];
    }

    final List<dynamic> categoryTips = countryData[category] as List<dynamic>;

    return categoryTips
        .map((tip) => Tip(content: tip, category: category, country: country))
        .toList();
  }

  static Future<List<String>> getAvailableCountries() async {
    final data = await loadTipsData();
    return data.keys.toList().cast<String>();
  }

  static Future<List<String>> getCategoriesForCountry(String country) async {
    final data = await loadTipsData();
    final countryData = data[country] as Map<String, dynamic>;
    return countryData.keys.toList().cast<String>();
  }
}
