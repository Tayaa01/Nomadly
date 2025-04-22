import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../network/api_config.dart'; // Import the API config
import '../utils/country_currency_util.dart'; // Import the country currency utility

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
      // Initialize the country-currency util if needed
      await CountryCurrencyUtil.initialize();

      // Get the currency based on country code
      final currency =
          CountryCurrencyUtil.getCurrencyForCountry(countryCode) ??
          'USD'; // Default to USD if not found

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
          "currency": currency, // Add the currency
        },
        options: Options(headers: ApiConfig.commonHeaders),
      );

      // Check if the response is successful
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'message': 'Registration failed: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      print('Registration error: $e');
      String errorMessage = 'Registration failed. Please try again.';

      if (e.response != null && e.response!.data != null) {
        // Try to get more specific error message from API
        try {
          if (e.response!.data is Map && e.response!.data['message'] != null) {
            errorMessage = e.response!.data['message'];
          }
        } catch (_) {}
      }

      return {'success': false, 'message': errorMessage};
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
        data: {"email": email, "password": password},
        options: Options(
          headers:
              ApiConfig.commonHeaders, // Should use commonHeaders consistently
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
            responseData['user'] as Map<String, dynamic>,
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
          return {
            'success': false,
            'message': 'Invalid server response format',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Login failed. Please check your credentials.',
      };
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> userData,
  ) async {
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
          return {'email': email, 'password': password};
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

  // Verify if stored token is valid
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await getToken();

      if (token == null) {
        print('No token found for verification');
        return {'valid': false, 'message': 'No authentication token found'};
      }

      // Use the API config for URL
      final verifyUrl = "${ApiConfig.BASE_URL}${ApiConfig.VERIFY_JWT_ENDPOINT}";
      print('Verifying token at: $verifyUrl');

      final response = await _dio.post(
        verifyUrl,
        data: {"jwt": token},
        options: Options(headers: ApiConfig.commonHeaders),
      );

      if (response.statusCode == 201) {
        // Changed from 200 to 201
        final responseData = response.data;
        final bool isValid = responseData['valid'] ?? false;

        if (isValid) {
          print('Token is valid');
          // Update stored user data if payload contains new information
          if (responseData['payload'] != null) {
            await _updateUserDataFromPayload(responseData['payload']);
          }
          return {'valid': true, 'payload': responseData['payload']};
        } else {
          print('Token is invalid');
          return {'valid': false, 'message': 'Invalid token'};
        }
      } else {
        print('Verification request failed: ${response.statusCode}');
        return {
          'valid': false,
          'message': 'Verification failed: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      print('Token verification error: $e');
      return {'valid': false, 'message': 'Failed to verify token'};
    }
  }

  // Update user data from token payload
  Future<void> _updateUserDataFromPayload(Map<String, dynamic> payload) async {
    try {
      final currentUserData = await getUserData();
      if (currentUserData != null) {
        // Update only the fields that are in the payload
        final updatedUserData = {
          ...currentUserData,
          'email': payload['email'] ?? currentUserData['email'],
          'id': payload['sub'] ?? currentUserData['id'],
          'role': payload['role'] ?? currentUserData['role'],
          'countryCode':
              payload['countryCode'] ?? currentUserData['countryCode'],
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(USER_KEY, jsonEncode(updatedUserData));
        print('User data updated from token payload');
      }
    } catch (e) {
      print('Error updating user data from payload: $e');
    }
  }

  // Check if user is logged in with valid token
  Future<bool> isLoggedInWithValidToken() async {
    try {
      final hasToken = await isLoggedIn();
      if (!hasToken) {
        return false;
      }

      // Verify token validity
      final verification = await verifyToken();
      return verification['valid'] == true;
    } catch (e) {
      print('Error verifying login status: $e');
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

  // Get current user info
  Future<AuthUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      // For demo purposes, we'll decode the JWT to get user info
      // In production, you'd typically make an API call to get full user details
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);

      return AuthUser(
        id: data['sub'],
        email: data['email'],
        countryCode: data['countryCode'],
      );
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Use the API config for URL
      final changePasswordUrl = "${ApiConfig.BASE_URL}/auth/change-password";
      print('Sending change password request to: $changePasswordUrl');

      final response = await _dio.patch(
        changePasswordUrl,
        data: {"oldPassword": oldPassword, "newPassword": newPassword},
        options: Options(headers: ApiConfig.getAuthHeaders(token)),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password changed successfully.'};
      } else {
        return {
          'success': false,
          'message': 'Failed to change password: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      print('Change password error: $e');
      String errorMessage = 'Failed to change password';

      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          errorMessage = 'Current password is incorrect';
        } else if (e.response!.data != null &&
            e.response!.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Request password reset code
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final url = "${ApiConfig.BASE_URL}/auth/request-password-reset";
      print('Sending password reset request to: $url');

      final response = await _dio.post(
        url,
        data: {"email": email},
        options: Options(headers: ApiConfig.commonHeaders),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'If this email exists, a reset code has been sent.',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to request password reset: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      print('Password reset request error: $e');
      String errorMessage = 'Failed to request password reset';

      if (e.response != null && e.response!.data != null) {
        try {
          if (e.response!.data is Map && e.response!.data['message'] != null) {
            errorMessage = e.response!.data['message'];
          }
        } catch (_) {}
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Reset password with code
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final url = "${ApiConfig.BASE_URL}/auth/reset-password";
      print('Sending reset password request to: $url');

      final response = await _dio.patch(
        url,
        data: {"email": email, "code": code, "newPassword": newPassword},
        options: Options(headers: ApiConfig.commonHeaders),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successful.'};
      } else {
        return {
          'success': false,
          'message': 'Failed to reset password: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      print('Reset password error: $e');
      String errorMessage = 'Failed to reset password';

      if (e.response != null) {
        if (e.response!.statusCode == 400) {
          errorMessage = 'Invalid reset code or email';
        } else if (e.response!.data != null &&
            e.response!.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
      }

      return {'success': false, 'message': errorMessage};
    }
  }
}

// Rename the User class to AuthUser to avoid conflicts
class AuthUser {
  final String id;
  final String email;
  final String? countryCode;

  AuthUser({required this.id, required this.email, this.countryCode});
}
