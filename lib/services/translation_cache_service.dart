import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TranslationCacheService {
  static const String CACHE_KEY = 'translation_cache';
  static const Duration CACHE_DURATION = Duration(days: 7);

  static Future<void> cacheTranslation(
    String text,
    String translation,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final cacheData = {
      'translation': translation,
      'timestamp': now.toIso8601String(),
    };
    
    final cache = await _getCache();
    final key = _generateKey(text, sourceLanguage, targetLanguage);
    cache[key] = cacheData;
    
    await prefs.setString(CACHE_KEY, jsonEncode(cache));
  }

  static Future<String?> getCachedTranslation(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final cache = await _getCache();
    final key = _generateKey(text, sourceLanguage, targetLanguage);
    final cacheData = cache[key];
    
    if (cacheData == null) return null;
    
    final timestamp = DateTime.parse(cacheData['timestamp']);
    if (DateTime.now().difference(timestamp) > CACHE_DURATION) {
      return null;
    }
    
    return cacheData['translation'];
  }

  static String _generateKey(String text, String sourceLanguage, String targetLanguage) {
    return '$text-$sourceLanguage-$targetLanguage';
  }

  static Future<Map<String, dynamic>> _getCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(CACHE_KEY);
    if (cacheString == null) return {};
    return jsonDecode(cacheString);
  }

  static Future<void> clearExpiredCache() async {
    final cache = await _getCache();
    final now = DateTime.now();
    
    cache.removeWhere((key, value) {
      final timestamp = DateTime.parse(value['timestamp']);
      return now.difference(timestamp) > CACHE_DURATION;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CACHE_KEY, jsonEncode(cache));
  }
}
