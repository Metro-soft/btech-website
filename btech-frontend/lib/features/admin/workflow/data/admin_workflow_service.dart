import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminWorkflowService {
  final String _baseUrl = 'http://172.31.235.222:5000/api/admin/workflow';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getApplications(
      {String? status, String? userId, String? staffId}) async {
    String? token = await _storage.read(key: 'token');

    // Build Query String
    List<String> queryParams = [];
    if (status != null) queryParams.add('status=$status');
    if (userId != null) queryParams.add('user=$userId');
    if (staffId != null) queryParams.add('staffId=$staffId');

    String queryString =
        queryParams.isNotEmpty ? '?${queryParams.join("&")}' : '';

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/applications$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load applications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching applications: $e');
    }
  }

  Future<void> assignTask(String appId, String staffId) async {
    String? token = await _storage.read(key: 'token');
    final response = await http.put(
      Uri.parse('$_baseUrl/applications/$appId/assign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'staffId': staffId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign task');
    }
  }
}
