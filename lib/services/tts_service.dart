import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text, String language) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error in TTS service: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
} 