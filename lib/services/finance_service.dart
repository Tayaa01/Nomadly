import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_summary.dart';
import '../models/saving_summary.dart';
import '../services/auth_service.dart';
import '../network/api_config.dart';

class FinanceService {
  final Dio _dio;
  final AuthService _authService;

  FinanceService({Dio? customDio, AuthService? authService})
      : _dio = customDio ?? 
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.BASE_URL,
                connectTimeout: Duration(milliseconds: ApiConfig.CONNECT_TIMEOUT),
                receiveTimeout: Duration(milliseconds: ApiConfig.RECEIVE_TIMEOUT),
              ),
            ),
        _authService = authService ?? AuthService();

  // Get daily transactions
  Future<List<TransactionSummary>> getTransactionsByDay() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await _dio.get(
        '/transactions/by-day',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'accept': '*/*',
          },
        ),
      );

      if (kDebugMode) {
        print('Transactions API Response: ${response.data}');
      }

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => TransactionSummary.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching transactions: $e');
      }
      throw Exception('Failed to load transactions: $e');
    }
  }

  // Get daily savings
  Future<List<SavingSummary>> getSavingsByDay() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await _dio.get(
        '/savings/by-day',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'accept': '*/*',
          },
        ),
      );

      if (kDebugMode) {
        print('Savings API Response: ${response.data}');
      }

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => SavingSummary.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load savings: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching savings: $e');
      }
      throw Exception('Failed to load savings: $e');
    }
  }
}
