import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../network/api_config.dart'; // Import the API config
import 'dart:convert';

class Coordinates {
  final double? latitude;
  final double? longitude;

  Coordinates({this.latitude, this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Coordinates();
    return Coordinates(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  bool get isValid => latitude != null && longitude != null;
}

class Location {
  final String? address;
  final String? city;
  final String country;
  final Coordinates? coordinates;

  Location({this.address, this.city, required this.country, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'],
      city: json['city'],
      country: json['country'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates']),
    );
  }
}

class SocialMedia {
  final String? facebook;
  final String? instagram;
  final String? twitter;

  SocialMedia({this.facebook, this.instagram, this.twitter});

  factory SocialMedia.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SocialMedia();
    return SocialMedia(
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
    );
  }
}

class Contact {
  final String? phone;
  final String? website;
  final SocialMedia? socialMedia;

  Contact({this.phone, this.website, this.socialMedia});

  factory Contact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Contact();
    return Contact(
      phone: json['phone'],
      website: json['website'],
      socialMedia: SocialMedia.fromJson(json['socialMedia']),
    );
  }
}

class Venue {
  final String name;
  final String type;
  final double? rating;
  final String? priceRange;
  final Contact? contact;

  Venue({
    required this.name,
    required this.type,
    this.rating,
    this.priceRange,
    this.contact,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      rating: json['rating']?.toDouble(),
      priceRange: json['priceRange'],
      contact: Contact.fromJson(json['contact']),
    );
  }
}

class DealDetails {
  final String? startDate;
  final String? endDate;
  final List<String>? terms;
  final String? originalPrice;
  final String? discountedPrice;
  final double? discountPercentage;
  final String? availability;
  final String? redemptionInstructions;
  final String? promoCode;
  final String? dealType;

  DealDetails({
    this.startDate,
    this.endDate,
    this.terms,
    this.originalPrice,
    this.discountedPrice,
    this.discountPercentage,
    this.availability,
    this.redemptionInstructions,
    this.promoCode,
    this.dealType,
  });

  factory DealDetails.fromJson(Map<String, dynamic> json) {
    return DealDetails(
      startDate: json['startDate'],
      endDate: json['endDate'],
      terms: (json['terms'] as List?)?.cast<String>(),
      originalPrice: json['originalPrice'],
      discountedPrice: json['discountedPrice'],
      discountPercentage: json['discountPercentage']?.toDouble(),
      availability: json['availability'],
      redemptionInstructions: json['redemptionInstructions'],
      promoCode: json['promoCode'],
      dealType: json['dealType'],
    );
  }
}

class Metadata {
  final String lastUpdated;
  final String source;
  final bool verified;
  final double? popularity;

  Metadata({
    required this.lastUpdated,
    required this.source,
    required this.verified,
    this.popularity,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      lastUpdated: json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      source: json['source'] ?? '',
      verified: json['verified'] ?? false,
      popularity: json['popularity']?.toDouble(),
    );
  }
}

class Deal {
  final String title;
  final String description;
  final String? url;
  final String? discount;
  final String reason;
  final String? imageUrl;

  Deal({
    required this.title,
    required this.description,
    this.url,
    this.discount,
    required this.reason,
    this.imageUrl,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'],
      discount: json['discount'],
      reason: json['reason'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}

class DealAnalysis {
  final List<Deal> recommendations;
  final List<String> savingsTips;
  final Map<String, dynamic>? metadata;

  DealAnalysis({
    required this.recommendations,
    required this.savingsTips,
    this.metadata,
  });

  factory DealAnalysis.fromJson(Map<String, dynamic> json) {
    return DealAnalysis(
      recommendations:
          (json['recommendations'] as List?)
              ?.map((deal) => Deal.fromJson(deal))
              .toList() ??
          [],
      savingsTips:
          (json['savingsTips'] as List?)
              ?.map((tip) => tip.toString())
              .toList() ??
          [],
      metadata: json['metadata'],
    );
  }
}

class DealsService {
  final Dio _dio;
  final String baseUrl;

  DealsService({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.BASE_URL,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
        ),
      ) {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (
      client,
    ) {
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  Future<DealAnalysis> searchDeals({
    required String country,
    required String category,
    String? specific,
    double? radius,
    double? latitude,
    double? longitude,
    int? minDiscount,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      final queryParams = {
        'country': country,
        'category': category,
        if (specific != null) 'specific': specific,
      };

      print('Sending request to: $baseUrl${ApiConfig.DEALS_SEARCH_ENDPOINT}');
      print('Query params: $queryParams');

      final response = await _dio.get(
        '$baseUrl${ApiConfig.DEALS_SEARCH_ENDPOINT}',
        queryParameters: queryParams,
      );

      print('Response status: ${response.statusCode}');
      print('Full response data: ${json.encode(response.data)}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        return DealAnalysis.fromJson(responseData);
      } else {
        print('Error response: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          error: response.data['error'] ?? 'Failed to fetch deals',
        );
      }
    } catch (e) {
      print('Error in searchDeals: $e');
      throw Exception('Failed to fetch deals: $e');
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
