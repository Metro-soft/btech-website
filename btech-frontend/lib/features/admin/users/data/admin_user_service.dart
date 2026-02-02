import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/auth_service.dart';

class AdminUserService {
  final _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getAllUsers({String? role}) async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('No auth token found');
    }

    final queryParams = role != null && role != 'All' ? '?role=$role' : '';
    final url = Uri.parse('${AuthService.baseUrl}/users$queryParams');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(userData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> userData) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> deleteUser(String id) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }
}
