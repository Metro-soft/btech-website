import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ClientWalletService {
  // Base API URLs
  static const String apiRoot = 'http://localhost:5000/api';
  static const String baseUrl = 'http://localhost:5000/api/client/finance';

  Future<Map<String, String>> _getHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token required');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Payment Methods ---
  // Note: These need verification against backend. Assuming shared or yet-to-be-implemented.
  Future<List<dynamic>> getPaymentMethods() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$apiRoot/finance/payment-methods'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Payment methods might not be implemented yet backend side
      return [];
      // throw Exception('Failed to load payment methods: ${response.body}');
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$apiRoot/finance/payment-methods'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add payment method: ${response.body}');
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$apiRoot/finance/payment-methods/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete payment method: ${response.body}');
    }
  }

  /// Fetches wallet balance and transaction history
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/wallet'), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load wallet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      rethrow;
    }
  }

  /// Initiates a deposit (IntaSend Checkout)
  Future<Map<String, dynamic>> deposit(double amount, String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/deposit'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Deposit initiation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error depositing: $e');
      rethrow;
    }
  }

  Future<void> buyAirtime(double amount, String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/airtime'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'phone': phone,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Airtime purchase failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error buying airtime: $e');
      rethrow;
    }
  }

  Future<void> requestStatement() async {
    try {
      final headers = await _getHeaders();
      // Assuming statement is also under client/finance, though not in route file yet
      final response = await http.post(
        Uri.parse('$baseUrl/statement'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Statement request failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error requesting statement: $e');
      rethrow;
    }
  }
}
