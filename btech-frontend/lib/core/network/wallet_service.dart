import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  // Gateway URL (Main Backend)
  static const String baseUrl = 'http://localhost:5000/api/wallet';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches wallet balance and transaction history
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load wallet: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      throw Exception('Failed to load wallet data');
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
        return jsonDecode(response.body); // Should contain 'url'
      } else {
        throw Exception('Deposit initiation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error depositing: $e');
      throw Exception('Deposit failed');
    }
  }
}
