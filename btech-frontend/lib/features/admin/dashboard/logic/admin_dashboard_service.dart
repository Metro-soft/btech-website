import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/auth_service.dart'; // Corrected depth (4 levels up)

class AdminDashboardService {
  final String baseUrl = 'http://localhost:5000/api'; // Or env variable
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> fetchQuickStats() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/quick-stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stats: ${response.body}');
    }
  }
}
