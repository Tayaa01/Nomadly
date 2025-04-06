import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/travel_request.dart';

class ApiService {
  final String baseUrl = 'http://192.168.1.123:3000';

  Future<String> generateItinerary(TravelRequest request) async {
    try {
      print('Sending request at: ${DateTime.now().toUtc().toIso8601String()}');
      print('Request body: ${json.encode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/travel/itinerary'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Updated to accept both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['itinerary'] != null) {
          return data['itinerary'];
        } else {
          throw Exception('Invalid response format: itinerary field is missing');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Server error ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }
}