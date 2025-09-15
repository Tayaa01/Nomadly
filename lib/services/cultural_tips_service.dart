import 'dart:convert';
import 'package:flutter/services.dart';

class CulturalTip {
  final String country;
  final String category;
  final String tip;

  CulturalTip({
    required this.country,
    required this.category,
    required this.tip,
  });
}

class CulturalTipsService {
  static Map<String, dynamic>? _tipsData;

  static Future<void> _loadTipsData() async {
    if (_tipsData != null) return;

    try {
      final jsonString = await rootBundle.loadString('tips.json');
      _tipsData = json.decode(jsonString);
    } catch (e) {
      print('Error loading tips data: $e');
      _tipsData = {};
    }
  }

  static Future<List<String>> getAvailableCountries() async {
    await _loadTipsData();
    return _tipsData?.keys.toList() ?? [];
  }

  static Future<List<String>> getCategoriesForCountry(String country) async {
    await _loadTipsData();
    if (_tipsData == null || !_tipsData!.containsKey(country)) {
      return [];
    }

    return _tipsData![country].keys.toList();
  }

  static Future<List<CulturalTip>> getTipsByCountryAndCategory(
    String country,
    String category,
  ) async {
    await _loadTipsData();

    if (_tipsData == null ||
        !_tipsData!.containsKey(country) ||
        !_tipsData![country].containsKey(category)) {
      return [];
    }

    final tipsList = _tipsData![country][category] as List;
    return tipsList
        .map(
          (tip) => CulturalTip(
            country: country,
            category: category,
            tip: tip.toString(),
          ),
        )
        .toList();
  }

  static Future<List<CulturalTip>> getAllTipsForCountry(String country) async {
    await _loadTipsData();

    if (_tipsData == null || !_tipsData!.containsKey(country)) {
      return [];
    }

    List<CulturalTip> allTips = [];

    _tipsData![country].forEach((category, tips) {
      final tipsList = tips as List;
      allTips.addAll(
        tipsList.map(
          (tip) => CulturalTip(
            country: country,
            category: category,
            tip: tip.toString(),
          ),
        ),
      );
    });

    return allTips;
  }
}
