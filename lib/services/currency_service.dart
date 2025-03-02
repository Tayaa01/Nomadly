import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../services/auth_service.dart';
import '../network/api_config.dart'; // Import the API config

class CurrencyService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.BASE_URL,  // Use the base URL from config
    connectTimeout: Duration(milliseconds: ApiConfig.CONNECT_TIMEOUT),
    receiveTimeout: Duration(milliseconds: ApiConfig.RECEIVE_TIMEOUT),
    sendTimeout: Duration(milliseconds: ApiConfig.SEND_TIMEOUT),
  ))..interceptors.add(
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
      ApiConfig.CURRENCIES_LIST_ENDPOINT,  // Use endpoint from config
      options: Options(headers: headers),
    );
    return List<String>.from(response.data);
  }

  Future<Map<String, dynamic>> analyzeAndConvertImage(XFile image, {String? countryCode}) async {
    // Get auth headers
    final headers = await _getAuthHeaders();
    
    // Create form data
    final formData = FormData();
    formData.files.add(MapEntry(
      'receipt',
      await MultipartFile.fromFile(
        image.path,
        filename: 'receipt.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    ));
    
    // Add detected country code if available - use 'country' parameter as shown in the cURL example
    if (countryCode != null) {
      formData.fields.add(MapEntry('country', countryCode));
    }
    
    print('Sending API request with image: ${image.path}, country: $countryCode');

    // Make the request exactly as shown in the cURL example
    final response = await _dio.post(
      ApiConfig.CURRENCY_ANALYZE_ENDPOINT,  // Use endpoint from config
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await _authService.getToken()}',
          'accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    print('API response status: ${response.statusCode}');
    return response.data;
  }

  Future<Map<String, dynamic>> convertCurrency(String amount) async {
    final headers = await _getAuthHeaders();
    final response = await _dio.post(
      ApiConfig.CURRENCY_CONVERT_ENDPOINT,  // Use endpoint from config
      data: {
        'amount': amount,
      },
      options: Options(headers: headers),
    );

    return response.data;
  }
}
