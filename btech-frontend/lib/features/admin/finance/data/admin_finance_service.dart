import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminFinanceService {
  final String _baseUrl = 'http://172.31.235.222:5000/api/admin/finance';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getTransactions({String? userId}) async {
    String? token = await _storage.read(key: 'token');

    String queryString = userId != null ? '?user=$userId' : '';

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }
}
