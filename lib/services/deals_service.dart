import 'package:dio/dio.dart';
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
      promoCode:
          json['promoCode'] != null
              ? PromoCode.fromJson(json['promoCode'])
              : null,
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      retailer: Retailer.fromJson(json['retailer'] ?? {}),
      category: json['category']?.toString() ?? '',
      lastVerified:
          json['lastVerified'] != null
              ? DateTime.parse(json['lastVerified'])
              : DateTime.now(),
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
      validUntil:
          json['validUntil'] != null
              ? DateTime.parse(json['validUntil'])
              : null,
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
      recommendations:
          (data['recommendations'] as List<dynamic>?)
              ?.map((x) => Deal.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
      savingsTips:
          (data['savingsTips'] as List<dynamic>?)
              ?.map((x) => x.toString())
              .toList() ??
          [],
      discounts:
          (data['discounts'] as List<dynamic>?)
              ?.map((x) => x.toString())
              .toList() ??
          [],
      reasons:
          (data['reasons'] as List<dynamic>?)
              ?.map((x) => x.toString())
              .toList() ??
          [],
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class DealsService {
  final dio = Dio();
  final String baseUrl;

  DealsService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.BASE_URL {
    dio.options.baseUrl = this.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<DealAnalysis> searchDeals({
    required String country,
    required String category,
    String? specific,
    double? minDiscount,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      final queryParams = {
        'country': country,
        'category': category,
        if (specific != null) 'specific': specific,
        if (minDiscount != null) 'minDiscount': minDiscount.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (sortBy != null) 'sortBy': sortBy,
      };

      final response = await dio.get(
        '/deals/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return DealAnalysis.fromJson(responseData);
        } else {
          throw DealException(responseData['error'] ?? 'Failed to fetch deals');
        }
      } else {
        throw DealException(
          'Failed to fetch deals: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw DealException('Failed to fetch deals: ${e.toString()}');
    }
  }
}

class DealException implements Exception {
  final String message;
  DealException(this.message);

  @override
  String toString() => message;
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
