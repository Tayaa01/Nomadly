import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  final String url;
  final String? price;
  final String? discount;
  final double? rating;
  final Location location;
  final Venue venue;
  final DealDetails dealDetails;
  final Metadata metadata;

  Deal({
    required this.title,
    required this.description,
    required this.url,
    this.price,
    this.discount,
    this.rating,
    required this.location,
    required this.venue,
    required this.dealDetails,
    required this.metadata,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      price: json['price'],
      discount: json['discount'],
      rating: json['rating']?.toDouble(),
      location: Location.fromJson(json['location'] ?? {}),
      venue: Venue.fromJson(json['venue'] ?? {}),
      dealDetails: DealDetails.fromJson(json['dealDetails'] ?? {}),
      metadata: Metadata.fromJson(json['metadata'] ?? {}),
    );
  }

  bool get hasValidCoordinates => location.coordinates?.isValid ?? false;
}

class DealAnalysis {
  final List<Deal> recommendations;
  final List<String> discounts;
  final List<String> reasons;
  final List<String> savingsTips;
  final Map<String, List<String>> trending;
  final Map<String, dynamic> statistics;

  DealAnalysis({
    required this.recommendations,
    required this.discounts,
    required this.reasons,
    required this.savingsTips,
    required this.trending,
    required this.statistics,
  });

  factory DealAnalysis.fromJson(Map<String, dynamic> json) {
    return DealAnalysis(
      recommendations:
          (json['recommendations'] as List?)
              ?.map((deal) => Deal.fromJson(deal as Map<String, dynamic>))
              .toList() ??
          [],
      discounts: (json['discounts'] as List?)?.cast<String>() ?? [],
      reasons: (json['reasons'] as List?)?.cast<String>() ?? [],
      savingsTips: (json['savingsTips'] as List?)?.cast<String>() ?? [],
      trending: {
        'categories':
            (json['trending']?['categories'] as List?)?.cast<String>() ?? [],
        'venues': (json['trending']?['venues'] as List?)?.cast<String>() ?? [],
        'locations':
            (json['trending']?['locations'] as List?)?.cast<String>() ?? [],
      },
      statistics: json['statistics'] ?? {},
    );
  }
}

class DealsService {
  final Dio _dio;
  final String baseUrl;

  DealsService({String? customBaseUrl, Dio? customDio})
    : baseUrl = customBaseUrl ?? 'http://localhost:3000/deals',
      _dio =
          customDio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              validateStatus: (status) => status! < 500,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

  Future<DealAnalysis> searchDeals({
    required String country,
    required String category,
    String? specific,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'Searching deals for $category in $country${specific != null ? ' (specific: $specific)' : ''}',
        );
      }

      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: {
          'country': country,
          'category': category,
          if (specific != null && specific.isNotEmpty) 'specific': specific,
        },
      );

      if (kDebugMode) {
        print('API Response: ${response.data}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return DealAnalysis.fromJson(data['data']);
        } else {
          final error = data['error'] ?? 'Unknown error occurred';
          throw DealException('API returned error: $error');
        }
      } else {
        throw DealException('API returned status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioError: ${e.message}');
        print('DioError type: ${e.type}');
        if (e.response != null) {
          print('DioError response: ${e.response?.data}');
        }
      }

      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Connection error. Please check your internet connection.';
          break;
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;
          errorMessage =
              'Server error (${statusCode ?? 'unknown'}): ${responseData?['error'] ?? 'Unknown error'}';
          break;
        default:
          errorMessage = 'An unexpected error occurred: ${e.message}';
      }
      throw DealException(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching deals: $e');
      }
      throw DealException('An unexpected error occurred: $e');
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
