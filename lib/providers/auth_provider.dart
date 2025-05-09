import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart'; // Assuming AuthService handles SharedPreferences

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  User? _user;
  bool _isLoading = true; // Start as loading until init completes

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initialize();
  }

  // Load initial state from storage
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that loading has started

    try {
      // Check if the stored token is still valid
      final bool stillLoggedIn = await _authService.isLoggedInWithValidToken();

      if (stillLoggedIn) {
        _token = await _authService.getToken(); // Token is confirmed valid
        final userDataMap = await _authService.getUserData();
        if (userDataMap != null) {
          _user = User.fromJson(userDataMap);
        } else {
          // This case implies an inconsistency: token valid but no user data.
          // Log out to be safe.
          print(
            "AuthProvider: Token valid but no user data found. Logging out.",
          );
          await _authService.logout();
          _token = null;
          _user = null;
        }
      } else {
        // Token is invalid, expired, or not present. Ensure logout.
        print(
          "AuthProvider: Token invalid, expired, or not found. Logging out.",
        );
        await _authService.logout(); // Clear any stored credentials
        _token = null;
        _user = null;
      }
    } catch (e) {
      print("Error initializing AuthProvider: $e");
      // Ensure logout state on any error during initialization
      try {
        await _authService.logout();
      } catch (logoutError) {
        print(
          "Error during logout in AuthProvider initialize catch: $logoutError",
        );
      }
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading is complete
    }
  }

  // Call this after a successful login (email/pass or social)
  Future<void> loginSuccess(String token, User user) async {
    _token = token;
    _user = user;

    // Persist using AuthService
    try {
      // Assuming AuthService has saveTokenAndUser method (add if needed)
      await _authService.saveTokenAndUser(token, user);
    } catch (e) {
      print("Error saving auth data via AuthProvider: $e");
      // Handle error appropriately
    }

    notifyListeners();
  }

  // Call this to log the user out
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _authService
        .logout(); // AuthService handles clearing SharedPreferences
    notifyListeners();
  }

  // Call this if user profile data is updated elsewhere
  Future<void> updateUser(User updatedUser) async {
    _user = updatedUser;
    // Optionally update SharedPreferences if user data is stored there separately
    try {
      // Assuming AuthService has updateStoredUserData method (add if needed)
      await _authService.updateStoredUserData(updatedUser);
    } catch (e) {
      print("Error updating stored user data via AuthProvider: $e");
    }
    notifyListeners();
  }
}
