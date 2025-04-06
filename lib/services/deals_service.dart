import 'dart:convert';
import 'package:http/http.dart' as http;
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
  
  // Fetch deals for a specific destination
  static Future<List<Map<String, dynamic>>> fetchDeals(String destination) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}${ApiConfig.DEALS_ENDPOINT}?destination=$destination'),
        headers: ApiConfig.commonHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        // If API call fails, use fallback method
        return await _fetchDealsWithSerper(destination);
      }
    } catch (e) {
      print('Error fetching deals from API: $e');
      // Fallback to Serper search
      return await _fetchDealsWithSerper(destination);
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
        // If API call fails, use fallback method
        return await _fetchDealsWithSerper(query);
      }
    } catch (e) {
      print('Error searching deals: $e');
      // Fallback to Serper search
      return await _fetchDealsWithSerper(query);
    }
  }
  
  // Fallback method using Serper.dev for when the API is unavailable
  static Future<List<Map<String, dynamic>>> _fetchDealsWithSerper(String destination) async {
    try {
      final response = await http.post(
        Uri.parse("https://google.serper.dev/search"),
        headers: {
          "X-API-KEY": serperApiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "q": "best travel deals to $destination",
          "gl": "us",
          "num": 10
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> deals = [];

        // Parse organic results
        if (data["organic"] != null) {
          for (var result in data["organic"]) {
            // Extract price from title or snippet if available
            String? price;
            String title = result["title"] ?? "Travel Deal";
            String description = result["snippet"] ?? "";
            
            // Updated regex to handle prices with commas and decimal points
            RegExp priceRegex = RegExp(r'\$\d{1,3}(,\d{3})*(\.\d{2})?|\d{1,3}(,\d{3})*(\.\d{2})?\s*USD|\d{1,3}(,\d{3})*(\.\d{2})?\s*\$');
            var priceMatch = priceRegex.firstMatch(title) ?? priceRegex.firstMatch(description);
            if (priceMatch != null) {
              price = priceMatch.group(0);
            }
            
            // Look for discount patterns
            String? discount;
            RegExp discountRegex = RegExp(r'(\d+%\s*off|\d+%\s*discount|save\s*\d+%)', caseSensitive: false);
            var discountMatch = discountRegex.firstMatch(title) ?? discountRegex.firstMatch(description);
            if (discountMatch != null) {
              discount = discountMatch.group(0);
            }
            
            deals.add({
              "title": title,
              "description": description,
              "price": price,
              "discount": discount,
              "link": result["link"],
              "imageUrl": _generateImageUrl(destination, title),
            });
          }
        }

        return deals.isEmpty ? _generateFallbackDeals(destination) : deals;
      }
      return _generateFallbackDeals(destination);
    } catch (e) {
      print('Error fetching deals with Serper: $e');
      return _generateFallbackDeals(destination);
    }
  }
  
  // Generate fake deals as a last resort fallback
  static List<Map<String, dynamic>> _generateFallbackDeals(String destination) {
    return [
      {
        "title": "Exclusive $destination Vacation Package",
        "description": "Experience the best of $destination with our exclusive travel package including flights, accommodations, and guided tours.",
        "price": "\$1,899.99",  // Updated to include comma and decimal
        "discount": "35% off",
        "link": "https://example.com/deals",
        "imageUrl": _generateImageUrl(destination, "vacation package"),
      },
      {
        "title": "Luxury Hotel Stay in $destination",
        "description": "Book a 5-star hotel stay in $destination at special rates. Includes breakfast and airport transfers.",
        "price": "\$199.00/night", // Added decimal
        "discount": "25% off",
        "link": "https://example.com/hotel-deals",
        "imageUrl": _generateImageUrl(destination, "luxury hotel"),
      },
      {
        "title": "Adventure Tour in $destination",
        "description": "Explore the natural wonders of $destination with our adventure tour package. Perfect for thrill-seekers!",
        "price": "\$349.50", // Added decimal
        "discount": "20% off",
        "link": "https://example.com/adventure-tours",
        "imageUrl": _generateImageUrl(destination, "adventure"),
      }
    ];
  }
  
  // Generate an image URL based on destination and title
  static String _generateImageUrl(String destination, String title) {
    // Simplify the query to increase chances of finding an image
    // Remove special characters and keep only the destination name
    final query = Uri.encodeComponent(destination.trim());
    
    // Use a more reliable format with random photos from the travel collection
    return 'https://source.unsplash.com/random/600x400/?travel,$query';
  }
}
