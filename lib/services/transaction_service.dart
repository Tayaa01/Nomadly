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

      print('Fetching transactions from API...');
      final response = await http.get(
        Uri.parse('${ApiConfig.BASE_URL}/transactions'),
        headers: {'Authorization': 'Bearer $token', 'Accept': '*/*'},
      );

      print('Transaction list API response status: ${response.statusCode}');
      print('Transaction list API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Parsed ${data.length} transactions from response');

        final transactions =
            data
                .map((json) {
                  try {
                    return Transaction.fromJson(json);
                  } catch (e) {
                    print('Error parsing transaction: $e');
                    print('Transaction data: $json');
                    // Return null for failed transactions
                    return null;
                  }
                })
                .where((t) => t != null)
                .toList()
                .cast<Transaction>();

        print('Successfully parsed ${transactions.length} transactions');
        return transactions;
      } else {
        print(
          'Failed to load transactions: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getTransactions: $e');
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
        throw Exception(
          'Failed to add transaction: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error adding transaction: $e');
    }
  }

  // Add a transaction from currency scan results
  Future<Transaction> addTransactionFromScan(
    Map<String, dynamic> scanResults,
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not available');
      }

      print('Creating transaction from scan results: $scanResults');

      // Extract data from scan results
      final imageAnalysis = scanResults['imageAnalysis'];
      final conversionResult = scanResults['conversionResult'];
      final conversionInput = scanResults['conversionInput'];

      if (imageAnalysis == null || conversionResult == null) {
        throw Exception('Invalid scan results format');
      }

      // Get amount from the scan results
      final double amount =
          conversionResult['amount']?.toDouble() ??
          imageAnalysis['detectedAmount']?.toDouble() ??
          0.0;

      // Get the original currency
      final String currency =
          conversionResult['from'] ??
          conversionInput?['sourceCurrencyUsed'] ??
          imageAnalysis['detectedCurrency'] ??
          'EUR';

      // Create a meaningful description
      String description = 'Scanned Receipt';

      // Create transaction payload matching the expected format from the backend
      // IMPORTANT: DO NOT include convertedAmount and convertedCurrency as separate fields
      final payload = {
        'amount': amount,
        'currency': currency,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'description': description,
      };

      print('Sending transaction payload: $payload');

      final response = await http.post(
        Uri.parse('${ApiConfig.BASE_URL}/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: json.encode(payload),
      );

      print('Transaction API response status: ${response.statusCode}');
      print('Transaction API response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('Transaction creation success: $responseBody');

        // Create transaction from response or fallback to our own data if response is invalid
        try {
          return Transaction.fromJson(responseBody);
        } catch (e) {
          print('Error parsing response, using fallback: $e');
          // Create a fallback transaction if the response can't be parsed
          return Transaction(
            originalAmount: amount,
            originalCurrency: currency,
            description: description,
            createdAt: DateTime.now(),
          );
        }
      } else {
        print(
          'Transaction API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to add transaction: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in addTransactionFromScan: $e');
      throw Exception('Error adding transaction: $e');
    }
  }
}
