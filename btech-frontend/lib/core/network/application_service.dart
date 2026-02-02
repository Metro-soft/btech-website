import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApplicationService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/iOS Simulator
  static const String baseUrl = 'http://localhost:5000/api/applications';

  Future<Map<String, String>> _getHeaders() async {
    // Use Secure Storage for token
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> submitApplication({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({
          'type': type,
          'payload': payload,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting application: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getApplications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load applications');
      }
    } catch (e) {
      throw Exception('Error fetching applications: $e');
    }
  }

  Future<void> processPayment({
    required String applicationId,
    required double amount,
    required String method,
    required String transactionId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$applicationId/pay'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'transactionId': transactionId,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Payment failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing payment: $e');
    }
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

  static const String staffUrl = 'http://localhost:5000/api/staff';

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

  Future<void> submitInput(
      {required String applicationId, required String response}) async {
    // This remains a client action, likely on /api/applications or /api/orders
    // Keeping it on base applications route as it is client facing
    try {
      final headers = await _getHeaders();
      final res = await http.put(
        Uri.parse('$baseUrl/$applicationId/submit-input'),
        headers: headers,
        body: jsonEncode({'response': response}),
      );
      if (res.statusCode != 200) {
        throw Exception('Failed to submit input: ${res.body}');
      }
    } catch (e) {
      throw Exception('Error submitting input: $e');
    }
  }

  Future<void> requestInput(
      {required String applicationId, required String message}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$staffUrl/tasks/$applicationId/request-input'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to request input: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error requesting input: $e');
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

  Future<List<Map<String, dynamic>>> getServices({String? category}) async {
    try {
      final headers = await _getHeaders();
      String queryString = '';
      if (category != null) {
        queryString = '?category=$category';
      }
      // Note: Endpoint is /api/services not /api/applications/services
      // We need to construct the URL relative to the API root.
      // Current baseUrl is .../api/applications.
      // Let's assume we can replace 'applications' with 'services' or define a new baseUrl.
      // Ideally defining a root baseUrl is better, but for now I'll hack the string replacement.
      final rootUrl = baseUrl.replaceAll('/applications', '');
      final response = await http
          .get(Uri.parse('$rootUrl/services$queryString'), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCourses({String? search}) async {
    try {
      final headers = await _getHeaders();
      String queryString = '';
      if (search != null && search.isNotEmpty) {
        queryString = '?search=$search';
      }
      final rootUrl = baseUrl.replaceAll('/applications', '');
      final response = await http.get(Uri.parse('$rootUrl/courses$queryString'),
          headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }
}
