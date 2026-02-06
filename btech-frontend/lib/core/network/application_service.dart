import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fpdart/fpdart.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/error/failures.dart';
import 'dart:io';

class ApplicationService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/iOS Simulator
  static const String baseUrl =
      'http://172.31.235.222:5000/api/applications'; // For physical device
  // static const String baseUrl = 'http://10.0.2.2:5000/api/applications'; // For Emulator

  Future<Map<String, String>> _getHeaders() async {
    // Use Secure Storage for token
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Either<Failure, Map<String, dynamic>>> submitApplication({
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
        return Right(jsonDecode(response.body));
      } else {
        developer.log('Server Error: ${response.statusCode}',
            error: response.body, name: 'ApplicationService');
        String userMsg = 'Failed to submit application.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            userMsg = decoded['message'];
          }
        } catch (_) {}
        return Left(ServerFailure(userMsg,
            internalDetails:
                'Status: ${response.statusCode}, Body: ${response.body}'));
      }
    } on SocketException catch (e) {
      developer.log('Network Error', error: e, name: 'ApplicationService');
      return Left(NetworkFailure(internalDetails: e.message));
    } catch (e, stackTrace) {
      developer.log('Submit Error',
          error: e, stackTrace: stackTrace, name: 'ApplicationService');
      return Left(ServerFailure('An unexpected error occurred.',
          internalDetails: e.toString()));
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

  Future<Map<String, dynamic>> getApplicationById(String id) async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/$id'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load application details');
      }
    } catch (e) {
      throw Exception('Error fetching application details: $e');
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required String applicationId,
    required double amount,
    required String method,
    required String transactionId,
    String? phone, // Add phone param
  }) async {
    try {
      final headers = await _getHeaders();
      // Call the new Finance Endpoint
      // Note: We are stepping out of /api/applications to /api/finance
      // We'll construct the URL manually relative to the root base if possible,
      // or just hardcode/replace for now as we did for services.
      final rootUrl = baseUrl.replaceAll('/api/applications', '/api/finance');

      final response = await http.post(
        // Changed to POST
        Uri.parse('$rootUrl/checkout'),
        headers: headers,
        body: jsonEncode({
          'applicationId': applicationId,
          'amount': amount,
          'method': method,
          'phone': phone, // Pass phone
          // 'transactionId': transactionId // Backend generates its own or uses this as idempotent key
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
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

  static const String staffUrl = 'http://172.31.235.222:5000/api/staff';

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

  // Support for both Web (Uint8List) and Mobile (File)
  Future<void> uploadFile({
    required String applicationId,
    List<int>? fileBytes, // For Web
    String? filePath, // For Mobile
    required String fileName,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$applicationId/upload');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.headers.remove('Content-Type'); // Let multipart set boundary

      if (fileBytes != null) {
        // Web
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType(
              'image', 'jpeg'), // Naive type, improved later if needed
        ));
      } else if (filePath != null) {
        // Mobile
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
        ));
      } else {
        throw Exception('No file data provided');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
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

  Future<List<Map<String, dynamic>>> getServices({String? category}) async {
    try {
      final headers = await _getHeaders();
      String queryString = '';
      if (category != null) {
        queryString = '?category=$category';
      }
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

  Future<Map<String, dynamic>> getServiceById(String id) async {
    try {
      final headers = await _getHeaders();
      final rootUrl = baseUrl.replaceAll('/applications', '');
      final response =
          await http.get(Uri.parse('$rootUrl/services/$id'), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load service details');
      }
    } catch (e) {
      throw Exception('Error fetching service details: $e');
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

  Future<String> getDownloadUrl(String applicationId) async {
    // Return the direct URL to the backend endpoint that serves the file
    // Ideally this should be a temporary signed URL or a direct API link protected by cookie/header
    // For this implementation, we will assume a direct endpoint that might handle redirection or stream
    return '$baseUrl/$applicationId/download';
  }
}
