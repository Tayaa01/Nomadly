import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../network/api_config.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<User> getUserProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}${ApiConfig.USER_PROFILE_ENDPOINT}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return User.fromJson(userData);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<User> updateUserProfile(User user) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.BASE_URL}${ApiConfig.USER_UPDATE_ENDPOINT}'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedData = jsonDecode(response.body);
        return User.fromJson(updatedData);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}
