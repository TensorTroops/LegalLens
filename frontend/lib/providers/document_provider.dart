import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../config/app_config.dart';

class DocumentProvider extends ChangeNotifier {
  // Using configured API base URL
  static final String baseUrl = AppConfig.apiBaseUrl;
  
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _documents = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get documents => _documents;

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<Map<String, dynamic>?> uploadDocument(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/documents/upload'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseData);
        notifyListeners();
        return result;
      } else {
        throw Exception('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDocuments() async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/documents/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _documents = List<Map<String, dynamic>>.from(data['documents'] ?? []);
        notifyListeners();
      } else {
        throw Exception('Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getDocumentById(String documentId) async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/documents/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result;
      } else {
        throw Exception('Failed to fetch document: ${response.statusCode}');
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/documents/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _documents.removeWhere((doc) => doc['id'] == documentId);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete document: ${response.statusCode}');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearDocuments() {
    _documents.clear();
    notifyListeners();
  }
}