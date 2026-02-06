import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletService {
  // Base API URL
  static const String baseUrl = 'http://172.31.235.222:5000/api';

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

  Future<List<dynamic>> getPaymentMethods() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/finance/payment-methods'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payment methods: ${response.body}');
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/finance/payment-methods'),
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
      Uri.parse('$baseUrl/finance/payment-methods/$id'),
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
      rethrow; // Rethrow to let UI handle "Auth token required"
    }
  }

  /// Initiates a deposit (IntaSend Checkout)
  Future<Map<String, dynamic>> deposit(double amount, String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/finance/deposit'),
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
        Uri.parse('$baseUrl/wallet/airtime'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/statement'),
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
