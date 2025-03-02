import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../services/auth_service.dart'; // Add this import

class CurrencyService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://6b4b-2c0f-f698-40c3-f1b9-98f2-7e4f-bdbd-36d3.ngrok-free.app',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
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
      '/currency-converter/currencies',
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
      '/tax-free/analyze',
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
      '/currency-converter/convert',
      data: {
        'amount': amount,
      },
      options: Options(headers: headers),
    );

    return response.data;
  }
}
