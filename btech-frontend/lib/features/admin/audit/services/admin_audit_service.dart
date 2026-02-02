import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';

class AdminAuditService {
  final String _baseUrl = ApiConstants.adminAudit;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    String? topic,
    String? buffer,
  }) async {
    String? token = await _storage.read(key: 'token');

    // Build Query String
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (topic != null && topic.isNotEmpty) queryParams['topic'] = topic;
    if (buffer != null && buffer.isNotEmpty) queryParams['buffer'] = buffer;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load audit logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching audit logs: $e');
    }
  }
}
