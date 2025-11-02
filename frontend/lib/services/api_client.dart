import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/app_config.dart';

class ApiClient {
  static final String baseUrl = '${AppConfig.apiBaseUrl}/api/v1';
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Get headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add Firebase ID token to Authorization header
    final token = await _authService.getIdToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('GET request failed: ${e.toString()}');
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('POST request failed: ${e.toString()}');
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('PUT request failed: ${e.toString()}');
    }
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('DELETE request failed: ${e.toString()}');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    try {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (statusCode >= 200 && statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          responseData['detail'] ?? 'Request failed with status: $statusCode',
          statusCode: statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Failed to parse response: ${e.toString()}',
        statusCode: statusCode,
      );
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> verifyFirebaseToken() async {
    return await get('/auth/firebase/verify');
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    return await get('/auth/firebase/me');
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    return await put('/auth/firebase/profile', profileData);
  }

  Future<Map<String, dynamic>> logoutUser() async {
    return await post('/auth/firebase/logout', {});
  }

  // Document endpoints
  Future<Map<String, dynamic>> uploadDocument(String filePath) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Let http handle multipart content type
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/upload'),
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Document upload failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getDocuments() async {
    return await get('/documents');
  }

  Future<Map<String, dynamic>> getDocument(String documentId) async {
    return await get('/documents/$documentId');
  }

  Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    return await delete('/documents/$documentId');
  }

  // Chat endpoints
  Future<Map<String, dynamic>> sendChatMessage(String message, {String? context}) async {
    return await post('/chat/message', {
      'message': message,
      'context': context,
    });
  }

  Future<Map<String, dynamic>> getChatHistory() async {
    return await get('/chat/history');
  }

  // Dictionary endpoints
  Future<Map<String, dynamic>> searchLegalTerms(String query) async {
    return await get('/dictionary/search?term=${Uri.encodeComponent(query)}');
  }

  Future<Map<String, dynamic>> getLegalTerm(String termId) async {
    return await get('/dictionary/terms/$termId');
  }

  Future<Map<String, dynamic>> getPopularTerms() async {
    return await get('/dictionary/popular');
  }

  Future<Map<String, dynamic>> autocompleteLegalTerms(String query) async {
    return await get('/dictionary/autocomplete?q=${Uri.encodeComponent(query)}');
  }

  // Voice endpoints
  Future<Map<String, dynamic>> processVoiceRecording(String audioFilePath) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/voice/process'),
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Voice processing failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> textToSpeech(String text) async {
    return await post('/voice/tts', {'text': text});
  }

  /// Save summary to Firestore
  Future<Map<String, dynamic>> saveSummary({
    required String userEmail,
    required String documentTitle,
    required Map<String, dynamic> summaryData,
  }) async {
    final data = {
      'user_email': userEmail,
      'document_title': documentTitle,
      'summary_data': summaryData,
    };
    return await post('/legal-chat/save-summary', data);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}