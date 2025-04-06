import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tip.dart';

class TipsService {
  // Cache for countries and tips to avoid repeated loading
  static List<String>? _cachedCountries;
  static final Map<String, List<String>> _cachedCategories = {};
  static final Map<String, Map<String, List<Tip>>> _cachedTips = {};

  // Instance methods that call static methods
  Future<List<String>> getAvailableCountries() async {
    return TipsService.getAvailableCountriesStatic();
  }

  Future<List<String>> getCategoriesForCountry(String country) async {
    return TipsService.getCategoriesForCountryStatic(country);
  }

  Future<List<Tip>> getTipsByCountryAndCategory(
    String country,
    String category,
  ) async {
    return TipsService.getTipsByCountryAndCategoryStatic(country, category);
  }

  Future<List<Tip>> searchTips(String query) async {
    return TipsService.searchTipsStatic(query);
  }

  // Static methods (renamed to avoid naming conflicts)
  static Future<List<String>> getAvailableCountriesStatic() async {
    if (_cachedCountries != null) {
      return _cachedCountries!;
    }

    try {
      final jsonData = await _loadTipsData();
      final countries = jsonData.keys.toList();
      _cachedCountries = countries;
      return countries;
    } catch (e) {
      print('Error loading available countries: $e');
      // Fallback to a default list of countries if loading fails
      return [
        'France',
        'Japan',
        'Italy',
        'United States',
        'Spain',
        'Thailand',
        'Morocco',
        'Egypt',
        'Tunisia',
        'Germany',
        'United Kingdom',
        'China',
      ];
    }
  }

  static Future<List<String>> getCategoriesForCountryStatic(String country) async {
    if (_cachedCategories.containsKey(country)) {
      return _cachedCategories[country]!;
    }

    try {
      final jsonData = await _loadTipsData();
      
      if (!jsonData.containsKey(country)) {
        return [];
      }
      
      final countryData = jsonData[country] as Map<String, dynamic>;
      final categories = countryData.keys.toList();
      
      _cachedCategories[country] = categories;
      return categories;
    } catch (e) {
      print('Error loading categories for $country: $e');
      return [];
    }
  }

  static Future<List<Tip>> getTipsByCountryAndCategoryStatic(
    String country,
    String category,
  ) async {
    if (_cachedTips.containsKey(country) && 
        _cachedTips[country]!.containsKey(category)) {
      return _cachedTips[country]![category]!;
    }

    try {
      final jsonData = await _loadTipsData();
      
      if (!jsonData.containsKey(country)) {
        return [];
      }
      
      final countryData = jsonData[country] as Map<String, dynamic>;
      
      if (!countryData.containsKey(category)) {
        return [];
      }
      
      final categoryTips = countryData[category] as List<dynamic>;
      final tips = categoryTips
          .map((tip) => Tip(
                country: country,
                category: category,
                content: tip.toString(),
              ))
          .toList();

      // Update cache
      if (!_cachedTips.containsKey(country)) {
        _cachedTips[country] = {};
      }
      _cachedTips[country]![category] = tips;
      
      return tips;
    } catch (e) {
      print('Error loading tips for $country/$category: $e');
      return [];
    }
  }

  static Future<List<Tip>> searchTipsStatic(String query) async {
    if (query.isEmpty) {
      return [];
    }

    query = query.toLowerCase();
    List<Tip> results = [];

    try {
      final countries = await getAvailableCountriesStatic();
      
      for (final country in countries) {
        final categories = await getCategoriesForCountryStatic(country);
        
        for (final category in categories) {
          final tips = await getTipsByCountryAndCategoryStatic(country, category);
          
          final matchingTips = tips.where((tip) => 
            tip.content.toLowerCase().contains(query) ||
            tip.category.toLowerCase().contains(query) ||
            tip.country.toLowerCase().contains(query)
          ).toList();
          
          results.addAll(matchingTips);
        }
      }
      
      return results;
    } catch (e) {
      print('Error searching tips: $e');
      return [];
    }
  }

  // Load tips data from json file
  static Future<Map<String, dynamic>> _loadTipsData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/tips.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading tips.json: $e');
      // Try the alternative location
      try {
        final jsonString = await rootBundle.loadString('tips.json');
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('Error loading from alternative location: $e');
        return {};
      }
    }
  }
}
