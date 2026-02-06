import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Dynamic Base URL
  // Dynamic Base URL
  static String get _rootUrl {
    if (kIsWeb) return 'http://172.31.235.222:5000/api';
    try {
      if (Platform.isAndroid) return 'http://172.31.235.222:5000/api';
    } catch (e) {
      // Platform check might fail in some edge cases
    }
    return 'http://172.31.235.222:5000/api';
  }

  static String get rootUrl => _rootUrl;
  static String get baseUrl => '$_rootUrl/auth';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(data);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'name': name, 'email': email, 'password': password, 'role': role}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveSession(data);
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    // Secure Storage for sensitive data
    await _storage.write(key: 'token', value: data['token']);
    await _storage.write(key: 'userId', value: data['_id']);

    // SharedPreferences for UI convenience (e.g. role-based hiding)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', data['role']);
    await prefs.setString('userName', data['name']);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'userId');

    return {
      'id': userId,
      'name': prefs.getString('userName'),
      'role': prefs.getString('role'),
      'token': token,
    };
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? password,
    String? profilePicture,
    Map<String, dynamic>? staffDetails,
  }) async {
    final token = await _storage.read(key: 'token');

    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (profilePicture != null) body['profilePicture'] = profilePicture;
    if (staffDetails != null) body['staffDetails'] = staffDetails;

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Update session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', data['name']);
      return data;
    } else {
      throw Exception('Update failed: ${response.body}');
    }
  }

  // Generic Authenticated Request Helper
  Future<dynamic> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    // Ensure endpoint starts with slash relative to API root, or handle full URL
    // Here we assume endpoint is like '/notifications'
    final uri = Uri.parse('$_rootUrl$endpoint');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;

    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response =
            await http.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response =
            await http.put(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      // We return the raw response object to let the caller handle status codes
      // or we could wrap it. For now, let's return a simple wrapper or the http.Response
      // The calling code expects 'response.statusCode' and 'response.data' (if using Dio style)
      // Since we are using http package, let's return a custom object or just the http.Response
      // and update the caller to access .body instead of .data

      return _HttpResponseWrapper(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Simple wrapper to match the calling code expectation (response.data)
class _HttpResponseWrapper {
  final http.Response _response;

  _HttpResponseWrapper(this._response);

  int get statusCode => _response.statusCode;

  dynamic get data {
    try {
      return jsonDecode(_response.body);
    } catch (_) {
      return _response.body;
    }
  }
}
