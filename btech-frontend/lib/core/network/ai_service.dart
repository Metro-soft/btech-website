import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class AiService {
  final _storage = const FlutterSecureStorage();

  // Generate Notification Template (or generic short content)
  Future<Map<String, dynamic>?> generateTemplate({
    required String goal,
    required String tone,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${AuthService.rootUrl}/ai/generate-template');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'goal': goal,
        'tone': tone,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      }
    }
    throw Exception('Failed to generate template: ${response.body}');
  }

  // Generate Full Service Details
  Future<Map<String, dynamic>> generateFullService({
    required String title,
    required String category,
    String? userPrompt,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${AuthService.rootUrl}/ai/generate-service-full');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'category': category,
        'userPrompt': userPrompt,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      }
    }
    throw Exception('Failed to generate service details: ${response.body}');
  }
}
