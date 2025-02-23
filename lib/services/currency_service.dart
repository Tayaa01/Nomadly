import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class CurrencyService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.3:3000',
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

  Future<List<String>> fetchCurrencies() async {
    final response = await _dio.get('/currency-converter/currencies');
    return List<String>.from(response.data);
  }

  Future<Map<String, dynamic>> analyzeAndConvertImage(XFile image, String sourceCountry, String targetCountry) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'receipt',
      await MultipartFile.fromFile(
        image.path,
        filename: 'receipt.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    ));
    formData.fields.add(MapEntry('country', sourceCountry));
    formData.fields.add(MapEntry('targetCountry', targetCountry));

    print('Sending API request with image: ${image.path}, sourceCountry: $sourceCountry, targetCountry: $targetCountry');

    final response = await _dio.post(
      '/tax-free/analyze',
      data: formData,
      options: Options(
        headers: {
          'accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    print('API response status: ${response.statusCode}');
    return response.data;
  }

  Future<Map<String, dynamic>> convertCurrency(String sourceCurrency, String targetCurrency, String amount) async {
    final response = await _dio.get(
      '/currency-converter/convert',
      queryParameters: {
        'from': sourceCurrency,
        'to': targetCurrency,
        'amount': amount,
      },
    );

    return response.data;
  }
}
