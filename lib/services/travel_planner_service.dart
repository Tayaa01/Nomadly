import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/travel_request.dart';
import '../models/travel_plan.dart'; // Make sure this path is correct
import '../network/api_config.dart';
import '../services/auth_service.dart';

/// Travel planning service for managing itineraries.
/// Handles API interactions with the travel planner endpoints.
class TravelPlannerService {
  final AuthService _authService = AuthService();

  /// Get the user's last created travel plan from the server
  Future<TravelPlan?> getExistingPlan() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}${ApiConfig.TRAVEL_PLAN_ENDPOINT}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TravelPlan.fromJson(data);
      } else if (response.statusCode == 404) {
        // No existing plan on server
        return null;
      } else {
        throw Exception('Failed to fetch plan: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting existing plan: $e');
      return null;
    }
  }

  /// Generate a custom travel plan with budget
  Future<TravelPlan> generateCustomPlan(TravelRequest request) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      print(
        'Generating plan for country: ${request.country}, city: ${request.city}, budget: ${request.budget}, days: ${request.days}',
      );

      // Ensure budget is always passed as a positive number or explicitly null
      final budgetValue =
          (request.budget != null && request.budget! > 0)
              ? request.budget
              : null;

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.BASE_URL}${ApiConfig.TRAVEL_GENERATE_PLAN_ENDPOINT}',
        ),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode({
          'country': request.country,
          'city': request.city, // Add city parameter
          'budget': budgetValue,
          'days': request.days,
          'startDate': request.startDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return TravelPlan.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error generating plan: $e');
      rethrow;
    }
  }

  /// Generate a budget-optimized travel plan
  Future<TravelPlan> generateBudgetPlan(TravelRequest request) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      print(
        'Generating budget plan for country: ${request.country}, city: ${request.city}, days: ${request.days}',
      );

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.BASE_URL}${ApiConfig.TRAVEL_GENERATE_BUDGET_PLAN_ENDPOINT}',
        ),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode({
          'country': request.country,
          'city': request.city, // Add city parameter
          'days': request.days,
          'startDate': request.startDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return TravelPlan.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error generating budget plan: $e');
      rethrow;
    }
  }

  /// Compatibility method for legacy code
  Future<String> generateItinerary(TravelRequest request) async {
    try {
      // Use the new method and extract content
      final plan = await generateCustomPlan(request);

      // Combine all day content into one string
      final combinedContent = plan.daysContent
          .map((day) => day.content)
          .join('\n\n');
      return combinedContent;
    } catch (e) {
      print('Error in generateItinerary: $e');
      rethrow;
    }
  }
}
