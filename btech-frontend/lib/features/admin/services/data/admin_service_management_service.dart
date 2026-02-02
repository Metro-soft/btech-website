import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/auth_service.dart';

class AdminServiceManagementService {
  final _storage = const FlutterSecureStorage();

  // GET all services
  Future<List<dynamic>> getAllServices() async {
    final url = Uri.parse('${AuthService.baseUrl}/services');
    // Services might be public, but let's send auth just in case or if logic changes
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load services: ${response.statusCode}');
    }
  }

  // CREATE a service
  Future<void> createService(Map<String, dynamic> serviceData) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${AuthService.baseUrl}/services');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(serviceData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create service: ${response.body}');
    }
  }

  // UPDATE a service
  Future<void> updateService(
      String id, Map<String, dynamic> serviceData) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${AuthService.baseUrl}/services/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(serviceData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update service: ${response.body}');
    }
  }

  // DELETE a service
  Future<void> deleteService(String id) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${AuthService.baseUrl}/services/$id');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete service: ${response.body}');
    }
  }
}
