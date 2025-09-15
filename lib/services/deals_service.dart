import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Added for rootBundle
import '../network/api_config.dart';

class Deal {
  final String title;
  final String description;
  final String url;
  final Price? price;
  final PromoCode? promoCode;
  final Location? location;
  final Retailer retailer;
  final String category;
  final DateTime lastVerified;
  final String source;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  Deal({
    required this.title,
    required this.description,
    required this.url,
    this.price,
    this.promoCode,
    this.location,
    required this.retailer,
    required this.category,
    required this.lastVerified,
    required this.source,
    this.imageUrl,
    this.metadata,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      promoCode: json['promoCode'] != null ? PromoCode.fromJson(json['promoCode']) : null,
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      retailer: Retailer.fromJson(json['retailer'] ?? {}),
      category: json['category']?.toString() ?? '',
      lastVerified: json['lastVerified'] != null ? DateTime.parse(json['lastVerified']) : DateTime.now(),
      source: json['source']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class Price {
  final double? current;
  final double? original;
  final String currency;
  final double? discountPercentage;

  Price({
    this.current,
    this.original,
    required this.currency,
    this.discountPercentage,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      current: json['current']?.toDouble(),
      original: json['original']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      discountPercentage: json['discountPercentage']?.toDouble(),
    );
  }
}

class PromoCode {
  final String code;
  final String description;
  final List<String>? terms;
  final DateTime? validUntil;

  PromoCode({
    required this.code,
    required this.description,
    this.terms,
    this.validUntil,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      terms: json['terms'] != null ? List<String>.from(json['terms']) : null,
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil']) : null,
    );
  }
}

class Location {
  final String name;
  final String? address;
  final String city;
  final String country;

  Location({
    required this.name,
    this.address,
    required this.city,
    required this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }
}

class Retailer {
  final String name;
  final String? logo;
  final String? website;
  final double? rating;
  final int? reviewCount;

  Retailer({
    required this.name,
    this.logo,
    this.website,
    this.rating,
    this.reviewCount,
  });

  factory Retailer.fromJson(Map<String, dynamic> json) {
    return Retailer(
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      website: json['website']?.toString(),
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }
}

class DealAnalysis {
  final List<Deal> recommendations;
  final List<String> savingsTips;
  final List<String> discounts;
  final List<String> reasons;
  final Map<String, dynamic> metadata;

  DealAnalysis({
    required this.recommendations,
    required this.savingsTips,
    required this.discounts,
    required this.reasons,
    required this.metadata,
  });

  factory DealAnalysis.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return DealAnalysis(
      recommendations: (data['recommendations'] as List<dynamic>?)
              ?.map((x) => Deal.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
      savingsTips: (data['savingsTips'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
      discounts: (data['discounts'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
      reasons: (data['reasons'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class DealsService {
  static const String serperApiKey = "b6e7935b4ea8abba16d7330df0d54c487abf24f0";

  static Map<String, List<String>>? _countryImages;
  static int _currentImageIndex = 0;

  static Future<void> _loadCountryImages() async {
    if (_countryImages != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/country_images.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _countryImages = Map.fromEntries(
        jsonData.entries.map((entry) => 
          MapEntry(
            entry.key.toLowerCase(),
            (entry.value['tourism'] as List<dynamic>).cast<String>()
          )
        )
      );
    } catch (e) {
      print('Error loading country images: $e');
      _countryImages = {};
    }
  }

  static String? _getNextImageForCountry(String country) {
    if (_countryImages == null) return null;
    
    final images = _countryImages![country.toLowerCase()];
    if (images == null || images.isEmpty) return null;
    
    // Get next image and increment index
    final imageUrl = images[_currentImageIndex % images.length];
    _currentImageIndex = (_currentImageIndex + 1) % images.length;
    
    return imageUrl;
  }

  // Fetch deals for a specific destination
  static Future<List<Map<String, dynamic>>> fetchDeals(String destination) async {
    await _loadCountryImages();
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}/deals/travel/cheapest?destination=$destination'),
        headers: ApiConfig.commonHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final recommendations = jsonResponse['data']['recommendations'] as List;
          
          return recommendations.map((deal) {
            final price = deal['price'] as Map<String, dynamic>?;
            final retailer = deal['retailer'] as Map<String, dynamic>;
            
            // More engaging price message
            String priceString = '💫 Check special offer';
            if (price != null && price['current'] != null) {
              priceString = '\$${price['current']}';
            }
            
            return {
              "title": deal['title'] ?? 'No title available',
              "snippet": deal['description'] ?? 'No description available',
              "price": priceString,
              "link": deal['url'] ?? '#',
              "imageUrl": _getNextImageForCountry(destination),
              "retailer": retailer['name'] ?? 'Unknown retailer',
              "lastVerified": deal['lastVerified'] ?? DateTime.now().toIso8601String(),
              "metadata": deal['metadata'] ?? {},
            };
          }).toList();
        }
        return [];
      } else {
        print('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching deals: $e');
      return [];
    }
  }
  
  // Search for specific deals
  static Future<List<Map<String, dynamic>>> searchDeals(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}${ApiConfig.DEALS_SEARCH_ENDPOINT}?query=$query'),
        headers: ApiConfig.commonHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching deals: $e');
      return [];
    }
  }

  // Update the fetchDealsHunt method to use the correct URL format
  static Future<Map<String, dynamic>> fetchDealsHunt(String country, String category) async {
    try {
      // Fix: Change the URL structure to match the correct API endpoint
      final url = Uri.parse('${ApiConfig.BASE_URL}/deals/hunt?country=$country&category=$category');
      
      print('Fetching deals from: $url');
      
      final response = await http.get(
        url, 
        headers: ApiConfig.commonHeaders,
      ).timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Check if we have a valid data structure
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          // Handle null recommendations
          if (jsonData['data'] == null || jsonData['data']['recommendations'] == null) {
            print('API returned null data or recommendations');
            return {
              'recommendations': [], 
              'savingsTips': [],
              'discounts': [],
              'reasons': [],
              'metadata': {'timestamp': DateTime.now().toIso8601String()}
            };
          }
          
          return jsonData['data'] as Map<String, dynamic>;
        } else {
          print('Invalid API response structure: $jsonData');
          throw Exception('Invalid API response structure');
        }
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to fetch deals: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching deals: $e');
      // Return empty data structure instead of throwing
      return {
        'recommendations': [], 
        'savingsTips': [],
        'discounts': [],
        'reasons': [],
        'metadata': {'timestamp': DateTime.now().toIso8601String(), 'error': e.toString()}
      };
    }
  }
}
