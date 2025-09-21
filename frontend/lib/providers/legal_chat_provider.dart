import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_message.dart';
import '../config/app_config.dart';

class LegalChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  LegalDocumentResult? _lastProcessedDocument;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Backend URL - using configuration
  static final String _baseUrl = AppConfig.legalChatBaseUrl;
  
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  LegalDocumentResult? get lastProcessedDocument => _lastProcessedDocument;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _lastProcessedDocument = null;
    notifyListeners();
  }

  Future<void> processLegalDocument(String extractedText, String documentTitle) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Debug: Check Firebase Auth initialization
      print('🔍 DEBUG: Checking Firebase Auth state...');
      print('Firebase App initialized: ${Firebase.apps.isNotEmpty}');
      
      // Get current user from Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      
      // Detailed debugging
      print('🔍 DEBUG: Current user: $user');
      print('🔍 DEBUG: User is null: ${user == null}');
      
      if (user != null) {
        print('🔍 DEBUG: User UID: ${user.uid}');
        print('🔍 DEBUG: User email: ${user.email}');
        print('🔍 DEBUG: User email verified: ${user.emailVerified}');
        print('🔍 DEBUG: User is anonymous: ${user.isAnonymous}');
      }
      
      if (user == null) {
        throw Exception('❌ No user is currently signed in. Please sign in first.');
      }
      
      if (user.email == null || user.email!.isEmpty) {
        throw Exception('❌ User email is not available. Please check your account.');
      }

      print('✅ Processing document for user: ${user.email}');

      final response = await http.post(
        Uri.parse('$_baseUrl/simplify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': extractedText,
          'user_email': user.email!,
        }),
      ).timeout(Duration(seconds: AppConfig.connectionTimeout));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('🔍 DEBUG: Response data received: $responseData');
        
        // Convert the simplified response to our model format
        _lastProcessedDocument = LegalDocumentResult(
          originalText: extractedText,
          simplifiedText: responseData['simplified_text'] ?? extractedText,
          extractedTerms: [], // Simplified endpoint doesn't return terms
          processingStatus: 'completed',
          termsCount: responseData['terms_processed'] ?? 0,
          spannerMatches: 0,
          geminiMatches: 0,
        );
        
        // Add AI response message
        addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: _formatSimplifiedResponse(_lastProcessedDocument!),
          timestamp: DateTime.now(),
          isUser: false,
          messageType: 'document_result',
          metadata: {
            'originalText': _lastProcessedDocument!.originalText,
            'simplifiedText': _lastProcessedDocument!.simplifiedText,
            'processingStatus': _lastProcessedDocument!.processingStatus,
            'documentTitle': documentTitle,
          },
        ));
      } else {
        print('🔍 DEBUG: Response status: ${response.statusCode}');
        print('🔍 DEBUG: Response body: ${response.body}');
        throw Exception('Failed to process document: ${response.statusCode}');
      }
    } catch (e) {
      print('Error processing document: $e');
      
      // Add error message
      addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: 'Sorry, I encountered an error while processing your document:\n${e.toString()}',
        timestamp: DateTime.now(),
        isUser: false,
        messageType: 'error',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    // Add user message
    addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      timestamp: DateTime.now(),
      isUser: true,
    ));

    _isLoading = true;
    notifyListeners();

    try {
      // Debug: Check Firebase Auth state
      print('🔍 DEBUG: Checking auth for sendMessage...');
      
      // Get current user from Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('❌ No user is currently signed in. Please sign in first.');
      }
      
      if (user.email == null || user.email!.isEmpty) {
        throw Exception('❌ User email is not available. Please check your account.');
      }

      print('✅ Sending message for user: ${user.email}');

      // For now, this is a simple echo. You can extend this for actual AI chat
      await Future.delayed(const Duration(seconds: 1));
      
      addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: 'Thank you for your question. I\'m here to help with legal document analysis. Please upload a document to get started.',
        timestamp: DateTime.now(),
        isUser: false,
        messageType: 'legal_answer',
      ));
    } catch (e) {
      print('❌ Error in sendMessage: $e');
      addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: 'Sorry, I encountered an error: ${e.toString()}',
        timestamp: DateTime.now(),
        isUser: false,
        messageType: 'error',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatSimplifiedResponse(LegalDocumentResult result) {
    return '''Document Analysis Complete! 📋

I've processed your legal document and simplified the complex terms.

 **Simplified Text:**
${result.simplifiedText}

 Processing completed successfully!''';
  }

  Future<void> saveSummary() async {
    if (_lastProcessedDocument == null) {
      throw Exception('No processed document to save');
    }

    try {
      // Get current user from Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated or email not available. Please sign in again.');
      }

      print('🔍 DEBUG: Saving summary for user: ${user.email}');

      // Create a unique summary ID using timestamp and random component
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomComponent = (timestamp * 1000 + (DateTime.now().microsecond % 1000)).toString();
      final summaryId = 'summary_$randomComponent';
      
      // Create a readable title based on timestamp
      final now = DateTime.now();
      final title = 'Document Summary ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      
      // Prepare summary data
      final summaryData = {
        'id': summaryId,
        'title': title,
        'original_text': _lastProcessedDocument!.originalText,
        'simplified_text': _lastProcessedDocument!.simplifiedText,
        'extracted_terms': _lastProcessedDocument!.extractedTerms.map((t) => t.toJson()).toList(),
        'processing_status': _lastProcessedDocument!.processingStatus,
        'terms_count': _lastProcessedDocument!.termsCount,
        'spanner_matches': _lastProcessedDocument!.spannerMatches,
        'gemini_matches': _lastProcessedDocument!.geminiMatches,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      bool firestoreSaveSuccessful = false;
      
      try {
        // Try Firestore first
        print('🔍 DEBUG: Attempting to save to Firestore...');
        
        // First, ensure user document exists (create if needed)
        final userDocRef = _firestore.collection('users').doc(user.email!);
        final userDoc = await userDocRef.get();
        
        if (!userDoc.exists) {
          print('🔍 DEBUG: Creating user document for: ${user.email}');
          await userDocRef.set({
            'uid': user.uid,
            'email': user.email!,
            'created_at': FieldValue.serverTimestamp(),
            'last_login_at': FieldValue.serverTimestamp(),
          });
          print('✅ User document created successfully');
        }

        // Save to Firestore using the structure: users/{email}/summaries/{summaryId}
        await _firestore
            .collection('users')
            .doc(user.email!)
            .collection('summaries')
            .doc(summaryId)
            .set(summaryData);

        print('✅ Summary saved successfully to Firestore with ID: $summaryId');
        firestoreSaveSuccessful = true;
        
      } catch (firestoreError) {
        print('⚠️ Firestore save failed: $firestoreError');
        print('🔄 Falling back to backend API...');
        firestoreSaveSuccessful = false;
      }

      // Use backend API as fallback or backup
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/save-summary'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'user_email': user.email!,
            'document_title': title,
            'summary_data': {
              'original_text': _lastProcessedDocument!.originalText,
              'simplified_text': _lastProcessedDocument!.simplifiedText,
              'extracted_terms': _lastProcessedDocument!.extractedTerms.map((t) => t.toJson()).toList(),
              'processing_status': _lastProcessedDocument!.processingStatus,
              'total_terms_found': _lastProcessedDocument!.termsCount,
              'spanner_terms': _lastProcessedDocument!.spannerMatches,
              'gemini_terms': _lastProcessedDocument!.geminiMatches,
            },
          }),
        ).timeout(Duration(seconds: AppConfig.connectionTimeout));

        if (response.statusCode == 200) {
          if (firestoreSaveSuccessful) {
            print('✅ Summary also saved to backend as backup');
          } else {
            print('✅ Summary saved to backend API successfully (Firestore fallback)');
          }
        } else {
          print('⚠️ Backend save failed: ${response.statusCode}');
          if (!firestoreSaveSuccessful) {
            throw Exception('Both Firestore and Backend save failed. Status: ${response.statusCode}');
          }
        }
      } catch (backendError) {
        print('⚠️ Backend save error: $backendError');
        if (!firestoreSaveSuccessful) {
          throw Exception('Both Firestore and Backend save failed. Backend error: $backendError');
        } else {
          print('⚠️ Backend failed but Firestore save succeeded');
        }
      }

      // If we reach here, at least one save method succeeded
      if (!firestoreSaveSuccessful) {
        print('⚠️ Note: Summary saved only to backend API due to Firestore issues');
      }

    } catch (e) {
      print('❌ Error saving summary: $e');
      throw Exception('Error saving summary: ${e.toString()}');
    }
  }

  Future<List<SavedSummary>> getUserSummaries() async {
    try {
      // Get current user from Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated or email not available. Please sign in again.');
      }

      print('🔍 DEBUG: Fetching summaries for user: ${user.email}');

      // Get summaries from Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.email!)
          .collection('summaries')
          .orderBy('created_at', descending: true)
          .get();

      print('🔍 DEBUG: Found ${snapshot.docs.length} summaries in Firestore');

      List<SavedSummary> summaries = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Handle timestamp conversion
          final createdAt = data['created_at'];
          final updatedAt = data['updated_at'];
          
          final summary = SavedSummary(
            id: data['id'] ?? doc.id,
            originalText: data['original_text'] ?? '',
            simplifiedText: data['simplified_text'] ?? '',
            extractedTerms: (data['extracted_terms'] as List<dynamic>? ?? [])
                .map((term) => LegalTerm.fromJson(term as Map<String, dynamic>))
                .toList(),
            documentTitle: data['title'] ?? 'Untitled Document',
            processingStatus: data['processing_status'] ?? 'completed',
            termsCount: data['terms_count'] ?? 0,
            spannerMatches: data['spanner_matches'] ?? 0,
            geminiMatches: data['gemini_matches'] ?? 0,
            createdAt: createdAt is Timestamp 
                ? createdAt.toDate() 
                : DateTime.now(),
            updatedAt: updatedAt is Timestamp 
                ? updatedAt.toDate() 
                : null,
          );
          
          summaries.add(summary);
        } catch (e) {
          print('⚠️ Error parsing summary document ${doc.id}: $e');
        }
      }

      print('✅ Successfully parsed ${summaries.length} summaries');
      return summaries;

    } catch (e) {
      print('❌ Error fetching summaries from Firestore: $e');
      
      // Fallback to backend API
      try {
        final user = FirebaseAuth.instance.currentUser;
        final response = await http.get(
          Uri.parse('$_baseUrl/summaries/${user!.email}'),
          headers: {
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: AppConfig.connectionTimeout));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final summariesData = responseData['summaries'] as List<dynamic>;
          
          return summariesData
              .map((summary) => SavedSummary.fromJson(summary))
              .toList();
        } else {
          throw Exception('Failed to fetch summaries from backend: ${response.statusCode}');
        }
      } catch (backendError) {
        print('❌ Backend fallback also failed: $backendError');
        throw Exception('Error fetching summaries: ${e.toString()}');
      }
    }
  }
}