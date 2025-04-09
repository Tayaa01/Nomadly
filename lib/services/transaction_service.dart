// Complete code for the TransactionService
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../network/api_config.dart';

class TransactionService {
  final AuthService _authService = AuthService();

  // Get all transactions from backend
  Future<List<Transaction>> getTransactions() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Add a new transaction to backend
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not available');
      }

      // Get user's currency for converted currency

      final response = await http.post(
        Uri.parse('${ApiConfig.BASE_URL}/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: json.encode({
          'amount': transaction.originalAmount,
          'currency': transaction.originalCurrency,
          'date': transaction.createdAt.toIso8601String().split('T')[0],
          'description': transaction.description,

        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Transaction.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding transaction: $e');
    }
  }
}