class ChatMessage {
  final String id;
  final String message;
  final DateTime timestamp;
  final bool isUser;
  final String messageType;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isUser,
    this.messageType = 'text',
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isUser: json['isUser'],
      messageType: json['messageType'] ?? 'text',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isUser': isUser,
      'messageType': messageType,
      'metadata': metadata,
    };
  }
}

class LegalDocumentResult {
  final String originalText;
  final String simplifiedText;
  final List<LegalTerm> extractedTerms;
  final String processingStatus;
  final int termsCount;
  final int spannerMatches;
  final int geminiMatches;

  LegalDocumentResult({
    required this.originalText,
    required this.simplifiedText,
    required this.extractedTerms,
    required this.processingStatus,
    required this.termsCount,
    required this.spannerMatches,
    required this.geminiMatches,
  });

  factory LegalDocumentResult.fromJson(Map<String, dynamic> json) {
    return LegalDocumentResult(
      originalText: json['original_text'],
      simplifiedText: json['simplified_text'],
      extractedTerms: (json['extracted_terms'] as List)
          .map((term) => LegalTerm.fromJson(term))
          .toList(),
      processingStatus: json['processing_status'],
      termsCount: json['terms_count'],
      spannerMatches: json['spanner_matches'],
      geminiMatches: json['gemini_fallbacks'],
    );
  }
}

class LegalTerm {
  final String term;
  final String definition;
  final String source;

  LegalTerm({
    required this.term,
    required this.definition,
    required this.source,
  });

  factory LegalTerm.fromJson(Map<String, dynamic> json) {
    return LegalTerm(
      term: json['term'],
      definition: json['definition'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'definition': definition,
      'source': source,
    };
  }
}

class SavedSummary {
  final String id;
  final String originalText;
  final String simplifiedText;
  final List<LegalTerm> extractedTerms;
  final String documentTitle;
  final String processingStatus;
  final int termsCount;
  final int spannerMatches;
  final int geminiMatches;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SavedSummary({
    required this.id,
    required this.originalText,
    required this.simplifiedText,
    required this.extractedTerms,
    required this.documentTitle,
    required this.processingStatus,
    required this.termsCount,
    required this.spannerMatches,
    required this.geminiMatches,
    required this.createdAt,
    this.updatedAt,
  });

  factory SavedSummary.fromJson(Map<String, dynamic> json) {
    return SavedSummary(
      id: json['id'],
      originalText: json['original_text'],
      simplifiedText: json['simplified_text'],
      extractedTerms: (json['extracted_terms'] as List)
          .map((term) => LegalTerm.fromJson(term))
          .toList(),
      documentTitle: json['document_title'],
      processingStatus: json['processing_status'],
      termsCount: json['terms_count'],
      spannerMatches: json['spanner_matches'],
      geminiMatches: json['gemini_fallbacks'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
}