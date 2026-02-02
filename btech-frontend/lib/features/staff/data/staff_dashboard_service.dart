import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/auth_service.dart';

class StaffDashboardService {
  // Derive base URL from AuthService to support Android Emulator (10.0.2.2)
  String get baseUrl => AuthService.baseUrl.replaceAll('/auth', '');

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> toggleAvailability() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/staff/availability'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to toggle availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling availability: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/staff/dashboard'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> getEarnings(String period) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/staff/earnings?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load earnings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading earnings: $e');
    }
  }

  Future<void> requestWithdrawal(double amount, String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/staff/withdraw'),
          headers: headers,
          body: jsonEncode({'amount': amount, 'phone': phone}));

      if (response.statusCode != 200) {
        throw Exception('Withdrawal failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error requesting withdrawal: $e');
    }
  }

  Future<void> buyAirtime(double amount, String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/staff/airtime'),
          headers: headers,
          body: jsonEncode({'amount': amount, 'phone': phone}));

      if (response.statusCode != 200) {
        throw Exception('Airtime purchase failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error buying airtime: $e');
    }
  }
}
