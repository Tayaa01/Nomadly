import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../network/api_config.dart'; // Import the API config

class AuthService {
  final Dio _dio = Dio();
  
  // Token storage keys
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_KEY = 'user_data';
  static const String REMEMBER_ME_KEY = 'remember_me';
  static const String STORED_EMAIL_KEY = 'stored_email';
  static const String STORED_PASSWORD_KEY = 'stored_password';
  static const String FIRST_LAUNCH_KEY = 'first_launch';
  
  // Register a new user
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String countryCode,
  }) async {
    try {
      // Use the API config for URL
      final registerUrl = "${ApiConfig.BASE_URL}${ApiConfig.REGISTER_ENDPOINT}";
      print('Sending registration request to: $registerUrl');
      
      final response = await _dio.post(
        registerUrl,
        data: {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
          "countryCode": countryCode,
        },
        options: Options(
          headers: ApiConfig.commonHeaders,
        ),
      );
      
      // Check if the response is successful
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'Registration failed: ${response.statusMessage}'};
      }
    } on DioException catch (e) {
      print('Registration error: $e');
      return {'success': false, 'message': 'Registration failed. Please try again.'};
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Use the API config for URL
      final loginUrl = "${ApiConfig.BASE_URL}${ApiConfig.LOGIN_ENDPOINT}";
      print('Sending login request to: $loginUrl');
      
      final response = await _dio.post(
        loginUrl,
        data: {
          "email": email,
          "password": password,
        },
        options: Options(
          headers: ApiConfig.commonHeaders,
        ),
      );
      
      if (response.statusCode == 200) {
        // Add null safety checks here
        final responseData = response.data;
        if (responseData != null && 
            responseData['access_token'] != null && 
            responseData['user'] != null) {
          await _saveAuthData(
            responseData['access_token'].toString(),
            responseData['user'] as Map<String, dynamic>
          );
          
          // If remember me is checked, save credentials
          if (rememberMe) {
            await _saveRememberMeData(email, password);
          } else {
            await _clearRememberMeData();
          }
          
          // Mark that the app has been launched before
          await _safeMarkAppLaunched();
          
          return {'success': true, 'data': responseData};
        } else {
          print('Invalid response format: ${response.data}');
          return {'success': false, 'message': 'Invalid server response format'};
        }
      } else {
        return {'success': false, 'message': 'Login failed: ${response.statusMessage}'};
      }
    } on DioException catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Login failed. Please check your credentials.'};
    }
  }
  
  // Save authentication data
  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TOKEN_KEY, token);
      await prefs.setString(USER_KEY, jsonEncode(userData));
      print('Auth data saved successfully');
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }
  
  // Save remember me data
  Future<void> _saveRememberMeData(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(REMEMBER_ME_KEY, true);
      await prefs.setString(STORED_EMAIL_KEY, email);
      await prefs.setString(STORED_PASSWORD_KEY, password);
      print('Saved remember me data');
    } catch (e) {
      print('Error saving remember me data: $e');
    }
  }
  
  // Clear remember me data
  Future<void> _clearRememberMeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(REMEMBER_ME_KEY, false);
      await prefs.remove(STORED_EMAIL_KEY);
      await prefs.remove(STORED_PASSWORD_KEY);
      print('Cleared remember me data');
    } catch (e) {
      print('Error clearing remember me data: $e');
    }
  }
  
  // Get remembered credentials
  Future<Map<String, dynamic>?> getRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(REMEMBER_ME_KEY) ?? false;
      
      if (rememberMe) {
        final email = prefs.getString(STORED_EMAIL_KEY);
        final password = prefs.getString(STORED_PASSWORD_KEY);
        
        if (email != null && password != null) {
          return {
            'email': email,
            'password': password,
          };
        }
      }
    } catch (e) {
      print('Error getting remembered credentials: $e');
    }
    return null;
  }
  
  // Get the stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(TOKEN_KEY);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
  
  // Get the stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(USER_KEY);
      if (userData != null) {
        return jsonDecode(userData) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }
  
  // Check if this is the first launch - with even more defensive null checking
  Future<bool> isFirstLaunch() async {
    try {
      print('Checking if this is first launch...');
      SharedPreferences? prefs;
      
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        print('Error getting SharedPreferences instance: $e');
        return true; // Default to first launch if we can't get SharedPreferences
      }
      
      if (prefs == null) {
        print('SharedPreferences instance is null');
        return true; // Default to first launch
      }
      
      // Check if the key exists
      bool keyExists = false;
      try {
        keyExists = prefs.containsKey(FIRST_LAUNCH_KEY);
        print('FIRST_LAUNCH_KEY exists in preferences? $keyExists');
      } catch (e) {
        print('Error checking if key exists: $e');
        return true; // Default to first launch
      }
      
      if (!keyExists) {
        print('FIRST_LAUNCH_KEY does not exist in preferences');
        await _safeMarkAppLaunched(); // Make sure this is already using _safeMarkAppLaunched
        return true;
      }
      
      // Try to get the value
      bool? hasLaunchedValue;
      try {
        hasLaunchedValue = prefs.getBool(FIRST_LAUNCH_KEY);
        print('FIRST_LAUNCH_KEY value: $hasLaunchedValue');
      } catch (e) {
        print('Error reading FIRST_LAUNCH_KEY value: $e');
        await _safeMarkAppLaunched(); // Try to reset if reading fails
        return true; // Default to first launch
      }
      
      // If key exists but value is null or false, consider as first launch
      if (hasLaunchedValue == null || !hasLaunchedValue) {
        print('FIRST_LAUNCH_KEY exists but value is null or false');
        await _safeMarkAppLaunched();
        return true;
      }
      
      // Not the first launch
      print('Not the first launch - FIRST_LAUNCH_KEY is true');
      return false;
    } catch (e) {
      print('Unexpected error in isFirstLaunch: $e');
      return true; // Default to first launch on any error
    }
  }
  
  // Extra safe version of _markAppLaunched
  Future<void> _safeMarkAppLaunched() async {
    try {
      print('Safely marking app as launched...');
      SharedPreferences? prefs;
      
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        print('Error getting SharedPreferences instance: $e');
        return;
      }
      
      if (prefs == null) {
        print('SharedPreferences instance is null');
        return;
      }
      
      bool result = false;
      try {
        // Try to save the value
        result = await prefs.setBool(FIRST_LAUNCH_KEY, true);
        print('setValue result: $result');
      } catch (e) {
        print('Error setting FIRST_LAUNCH_KEY: $e');
      }
      
      // Verify the key was set
      try {
        final hasKey = prefs.containsKey(FIRST_LAUNCH_KEY);
        final getValue = prefs.getBool(FIRST_LAUNCH_KEY);
        print('Verification - key exists: $hasKey, value: $getValue');
      } catch (e) {
        print('Error verifying FIRST_LAUNCH_KEY: $e');
      }
    } catch (e) {
      print('Unexpected error in _safeMarkAppLaunched: $e');
    }
  }
  
  // Debug method to reset first launch state
  Future<void> resetFirstLaunchState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(FIRST_LAUNCH_KEY);
      print('First launch state reset. Result: $result');
      
      // Verify the key is removed
      final hasKey = prefs.containsKey(FIRST_LAUNCH_KEY);
      print('Key exists after reset? $hasKey');
    } catch (e) {
      print('Error resetting first launch state: $e');
    }
  }
  
  // Log out - clear stored credentials
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TOKEN_KEY);
      await prefs.remove(USER_KEY);
      await _clearRememberMeData();
      print('Logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final isLoggedIn = token != null;
      print('Is user logged in? $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
  
  // FOR DEBUGGING: Print all stored preferences
  Future<void> debugPrintAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('--- STORED PREFERENCES ---');
      print('TOKEN_KEY exists: ${prefs.containsKey(TOKEN_KEY)}');
      print('USER_KEY exists: ${prefs.containsKey(USER_KEY)}');
      print('FIRST_LAUNCH_KEY exists: ${prefs.containsKey(FIRST_LAUNCH_KEY)}');
      print('FIRST_LAUNCH_KEY value: ${prefs.getBool(FIRST_LAUNCH_KEY)}');
      print('REMEMBER_ME_KEY exists: ${prefs.containsKey(REMEMBER_ME_KEY)}');
      print('------------------------');
    } catch (e) {
      print('Error printing preferences: $e');
    }
  }
}