import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/travel_request.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _lastGeneratedItinerary;
  bool _isLoading = false;
  final String _username;
  final DateTime _sessionStartTime;

  ChatProvider(this._username) 
      : _sessionStartTime = DateTime.utc(2025, 02, 21, 13, 47, 28);  // Updated timestamp

  bool get isLoading => _isLoading;
  String? get lastGeneratedItinerary => _lastGeneratedItinerary;

  Future<void> generateItinerary(TravelRequest request) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Generating itinerary with request: ${request.toString()}');
      final itinerary = await _apiService.generateItinerary(request);
      _lastGeneratedItinerary = itinerary;
      print('Itinerary generated successfully');

    } catch (e) {
      print('Error in ChatProvider: $e');
      _lastGeneratedItinerary = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _lastGeneratedItinerary = null;
    notifyListeners();
  }

  String get sessionInfo => '''
Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): ${_sessionStartTime.toIso8601String()}
Current User's Login: $_username
''';
}