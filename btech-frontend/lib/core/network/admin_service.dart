import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web
  static const String baseUrl = 'http://localhost:5000/api/admin';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- User Management ---

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // debugPrint('Users fetched: ${response.body}');
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/dashboard/users/$userId'),
        headers: headers,
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update role: ${response.body}');
      }
      debugPrint('Updated user $userId to role $newRole');
    } catch (e) {
      debugPrint('Error updating role: $e');
      rethrow;
    }
  }

  // --- System Stats ---

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/quick-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totalRevenue': (data['revenue'] as num).toDouble(),
          'pendingApplications': data['pendingTasks'] as int,
          'activeStaff': data['activeStaff'] as int,
          'totalUsers': data['totalUsers'] as int? ?? 0,
        };
      } else {
        throw Exception('Failed to load stats: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      // Return default/zero values on error
       return {
        'totalRevenue': 0.0,
        'pendingApplications': 0,
        'activeStaff': 0,
        'totalUsers': 0,
      };
    }
  }
}
