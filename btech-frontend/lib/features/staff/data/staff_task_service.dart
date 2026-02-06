import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StaffTaskService {
  static const String baseUrl = 'http://172.31.235.222:5000/api/client/orders';
  static const String staffUrl = 'http://172.31.235.222:5000/api/staff';

  Future<Map<String, String>> _getHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> assignTask(
      {required String applicationId, required String staffId}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$applicationId/assign'),
        headers: headers,
        body: jsonEncode({'staffId': staffId}),
      );
      if (response.statusCode != 200) throw Exception('Failed to assign');
    } catch (e) {
      throw Exception('Error assigning task: $e');
    }
  }

  Future<void> completeTask({required String applicationId}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$staffUrl/tasks/$applicationId/complete'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to complete task');
      }
    } catch (e) {
      throw Exception('Error completing task: $e');
    }
  }

  Future<void> requestInput(
      {required String applicationId,
      required String message,
      String? type}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$staffUrl/tasks/$applicationId/request-input'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          if (type != null) 'type': type,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to request input: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error requesting input: $e');
    }
  }

  Future<void> updateProcessingStep(
      {required String applicationId,
      required String step,
      required bool completed}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$staffUrl/tasks/$applicationId/step'),
        headers: headers,
        body: jsonEncode({'step': step, 'completed': completed}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update step');
      }
    } catch (e) {
      throw Exception('Error updating step: $e');
    }
  }

  Future<void> rejectTask(
      {required String applicationId, required String reason}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$staffUrl/tasks/$applicationId/reject'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reject task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error rejecting task: $e');
    }
  }

  Future<Map<String, dynamic>> getStaffDashboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$staffUrl/dashboard'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStaffTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$staffUrl/tasks'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load staff tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching staff tasks: $e');
    }
  }

  Future<Map<String, dynamic>> getApplicationById(String applicationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$applicationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load application details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading application: $e');
    }
  }
}
