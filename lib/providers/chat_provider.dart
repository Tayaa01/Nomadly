import 'package:flutter/foundation.dart';
import '../models/travel_request.dart';
import '../services/travel_planner_service.dart'; // Updated import

class ChatProvider extends ChangeNotifier {
  final String username;
  bool _isLoading = false;
  String? _lastGeneratedItinerary;
  final TravelPlannerService _travelService = TravelPlannerService(); // Updated service

  ChatProvider(this.username);

  bool get isLoading => _isLoading;
  String? get lastGeneratedItinerary => _lastGeneratedItinerary;

  Future<void> generateItinerary(TravelRequest request) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use the renamed service
      final itinerary = await _travelService.generateItinerary(request);
      
      _lastGeneratedItinerary = itinerary;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearHistory() {
    _lastGeneratedItinerary = null;
    notifyListeners();
  }
}