import 'dart:convert';
import 'package:http/http.dart' as http;

class ETAService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/applications';

  Future<void> submitApplication({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'ETA',
          'payload': payload,
          // 'userId': ... // Add user ID if auth is implemented
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting application: $e');
    }
  }
}
