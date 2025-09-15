import 'dart:convert';
import 'package:flutter/services.dart';

class CountryImagesService {
  static Map<String, dynamic>? _cachedImages;
  
  /// Loads country images from the JSON asset file
  static Future<Map<String, dynamic>> loadCountryImages() async {
    if (_cachedImages != null) {
      return _cachedImages!;
    }
    
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/country_images.json');
      _cachedImages = json.decode(jsonString) as Map<String, dynamic>;
      return _cachedImages!;
    } catch (e) {
      print('Error loading country images: $e');
      return {};
    }
  }
  
  /// Gets tourism images for a specific country
  static Future<List<String>> getTourismImages(String country) async {
    final images = await loadCountryImages();
    if (!images.containsKey(country)) {
      // Return empty list if country not found
      return [];
    }
    
    try {
      final countryData = images[country] as Map<String, dynamic>;
      if (countryData.containsKey('tourism')) {
        final tourismImages = countryData['tourism'];
        if (tourismImages is List) {
          return tourismImages.cast<String>();
        }
      }
      return [];
    } catch (e) {
      print('Error getting tourism images for $country: $e');
      return [];
    }
  }
  
  /// Gets airline image for a specific country
  static Future<String?> getAirlineImage(String country) async {
    final images = await loadCountryImages();
    if (!images.containsKey(country)) {
      return null;
    }
    
    try {
      final countryData = images[country] as Map<String, dynamic>;
      return countryData['airline'] as String?;
    } catch (e) {
      print('Error getting airline image for $country: $e');
      return null;
    }
  }
  
  /// Gets hotel images for a specific country
  static Future<List<String>> getHotelImages(String country) async {
    final images = await loadCountryImages();
    if (!images.containsKey(country)) {
      return [];
    }
    
    try {
      final countryData = images[country] as Map<String, dynamic>;
      if (countryData.containsKey('hotels')) {
        final hotelImages = countryData['hotels'];
        if (hotelImages is List) {
          return hotelImages.cast<String>();
        }
      }
      return [];
    } catch (e) {
      print('Error getting hotel images for $country: $e');
      return [];
    }
  }
  
  /// Gets a random tourism image for a country or a default one if none found
  static Future<String> getRandomTourismImage(String country) async {
    final images = await getTourismImages(country);
    if (images.isEmpty) {
      // Return a default image if no tourism images found
      return 'https://images.unsplash.com/photo-1530841377377-3ff06c0ca713?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MXx8Y2l0eXxlbnwwfHwwfHw%3D&w=1000&q=80';
    }
    
    // Return a random image from the list
    images.shuffle();
    return images.first;
  }
}
