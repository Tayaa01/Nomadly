import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<String> translateText({
    required String text,
    required String targetLanguage,
    required String sourceLanguage,
  }) async {
    try {
      print('Sending translation request:');
      print('Text: $text');
      print('Source: $sourceLanguage');
      print('Target: $targetLanguage');

      final response = await http.post(
        Uri.parse('$baseUrl/translation/translate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'targetLanguage': targetLanguage,
          'sourceLanguage': sourceLanguage,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['translatedText'] ?? 'Translation failed';
      } else {
        throw Exception('Failed to translate: ${response.statusCode}');
      }
    } catch (e) {
      print('Translation error: $e');
      throw Exception('Translation failed: $e');
    }
  }
}
