import '../../../../core/network/auth_service.dart';

class TemplateService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getTemplates() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      '/notifications/templates',
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load templates');
    }
  }

  Future<dynamic> createTemplate(Map<String, dynamic> data) async {
    final response = await _authService.authenticatedRequest(
      'POST',
      '/notifications/templates',
      body: data,
    );

    if (response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Failed to create template: ${response.data}');
    }
  }

  Future<dynamic> updateTemplate(String id, Map<String, dynamic> data) async {
    final response = await _authService.authenticatedRequest(
      'PUT',
      '/notifications/templates/$id',
      body: data,
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to update template');
    }
  }

  Future<void> deleteTemplate(String id) async {
    final response = await _authService.authenticatedRequest(
      'DELETE',
      '/notifications/templates/$id',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete template');
    }
  }

  Future<void> sendBroadcast(Map<String, dynamic> payload) async {
    final response = await _authService.authenticatedRequest(
      'POST',
      '/notifications/broadcast',
      body: payload,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send broadcast: ${response.data}');
    }
  }

  Future<Map<String, dynamic>> generateAiContent({
    required String goal,
    required String tone,
  }) async {
    final response = await _authService.authenticatedRequest(
      'POST',
      '/ai/generate-template',
      body: {
        'goal': goal,
        'tone': tone,
      },
    );

    if (response.statusCode == 200) {
      return response.data[
          'data']; // Expecting { success: true, data: { title: ..., body: ... } }
    } else {
      throw Exception('Failed to generate AI content: ${response.data}');
    }
  }
}
