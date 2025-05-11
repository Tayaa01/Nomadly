import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../services/auth_service.dart';
import '../network/api_config.dart'; // Import the API config

class CurrencyService {
  final Dio _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.BASE_URL, // Use the base URL from config
        connectTimeout: Duration(milliseconds: ApiConfig.CONNECT_TIMEOUT),
        receiveTimeout: Duration(milliseconds: ApiConfig.RECEIVE_TIMEOUT),
        sendTimeout: Duration(milliseconds: ApiConfig.SEND_TIMEOUT),
      ),
    )
    ..interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: MemCacheStore(),
          policy: CachePolicy.refreshForceCache,
          priority: CachePriority.high,
          maxStale: const Duration(days: 1),
          hitCacheOnErrorExcept: [401, 403],
        ),
      ),
    );

  final AuthService _authService = AuthService();

  // Helper method to get the auth token and add it to headers
  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<List<String>> fetchCurrencies() async {
    final headers = await _getAuthHeaders();
    final response = await _dio.get(
      ApiConfig.CURRENCIES_LIST_ENDPOINT, // Use endpoint from config
      options: Options(headers: headers),
    );
    return List<String>.from(response.data);
  }

  // Add a new method for scan-only functionality
  Future<Map<String, dynamic>> analyzeAndConvertImage(
    XFile image, {
    String? sourceCurrency,
    String? targetCurrency,
  }) async {
    // Create form data
    final formData = FormData();

    formData.files.add(
      MapEntry(
        'image', // Note: parameter name is 'image' for this endpoint
        await MultipartFile.fromFile(
          image.path,
          filename: 'receipt.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );

    // Add source and target currencies
    if (sourceCurrency != null) {
      formData.fields.add(MapEntry('sourceCurrency', sourceCurrency));
    }

    if (targetCurrency != null) {
      formData.fields.add(MapEntry('targetCurrency', targetCurrency));
    }

    print(
      'Sending image analysis request: ${image.path}, source: $sourceCurrency, target: $targetCurrency',
    );

    try {
      // Make the request to the new endpoint
      final response = await _dio.post(
        ApiConfig.IMAGE_ANALYZE_CONVERT_ENDPOINT,
        data: formData,
        options: Options(
          headers: {'accept': '*/*', 'Content-Type': 'multipart/form-data'},
        ),
      );

      print('Image analysis response status: ${response.statusCode}');

      // Log the full raw response for diagnosis
      print('FULL RESPONSE DATA: ${response.data.toString()}');

      // Do additional checks
      if (response.data == null) {
        print('ERROR: Response data is null');
        return {'error': 'No response data received'};
      }

      if (response.data is! Map<String, dynamic>) {
        print(
          'ERROR: Response data is not a Map: ${response.data.runtimeType}',
        );
        // Try to convert to map if possible, otherwise return error
        if (response.data is String) {
          try {
            return json.decode(response.data as String);
          } catch (e) {
            print('ERROR: Failed to decode response string: $e');
            return {
              'error': 'Invalid response format',
              'rawData': response.data,
            };
          }
        }
        return {
          'error': 'Invalid response format',
          'rawData': response.data.toString(),
        };
      }

      // Return the data
      return response.data;
    } catch (e) {
      print('ERROR in analyzeAndConvertImage: $e');
      return {'error': e.toString()};
    }
  }

  // Update the addTransactionFromImage method to use the correct endpoint and parameters
  Future<Map<String, dynamic>> addTransactionFromImage(
    XFile image, {
    String? countryCode,
  }) async {
    // Get auth token for the request
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not available');
    }

    // Create form data
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'receipt', // Server expects 'receipt' as the parameter name
        await MultipartFile.fromFile(
          image.path,
          filename: 'receipt.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );

    // Add country code if available
    if (countryCode != null) {
      formData.fields.add(MapEntry('country', countryCode));
    }

    print(
      'Adding transaction with image: ${image.path}, country: $countryCode',
    );

    try {
      // Make the authorized request to add a transaction
      final response = await _dio.post(
        ApiConfig
            .CURRENCY_ANALYZE_ENDPOINT, // Make sure this points to "/tax-free/analyze"
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Add transaction response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error calling API: $e');
      rethrow; // Re-throw to be handled by the ViewModel
    }
  }

  Future<Map<String, dynamic>> convertCurrency(String amount) async {
    final headers = await _getAuthHeaders();
    final response = await _dio.post(
      ApiConfig.CURRENCY_CONVERT_ENDPOINT, // Use endpoint from config
      data: {'amount': amount},
      options: Options(headers: headers),
    );

    return response.data;
  }
}
