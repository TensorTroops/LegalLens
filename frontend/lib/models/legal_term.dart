class LegalTerm {
  final String termId;
  final String term;
  final String originalMeaning;
  final String? simplifiedMeaning;
  final String? pronunciation;
  final List<String>? relatedTerms;
  final bool isFavorite;
  final bool isBookmarked;
  final DateTime? lastSearched;

  LegalTerm({
    required this.termId,
    required this.term,
    required this.originalMeaning,
    this.simplifiedMeaning,
    this.pronunciation,
    this.relatedTerms,
    this.isFavorite = false,
    this.isBookmarked = false,
    this.lastSearched,
  });

  factory LegalTerm.fromJson(Map<String, dynamic> json) {
    return LegalTerm(
      termId: json['term_id'] ?? '',
      term: json['term'] ?? '',
      originalMeaning: json['meaning'] ?? '',
      simplifiedMeaning: json['simplified_meaning'],
      pronunciation: json['pronunciation'],
      relatedTerms: json['related_terms'] != null 
          ? List<String>.from(json['related_terms'])
          : null,
      isFavorite: json['is_favorite'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
      lastSearched: json['last_searched'] != null 
          ? DateTime.parse(json['last_searched'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term_id': termId,
      'term': term,
      'meaning': originalMeaning,
      'simplified_meaning': simplifiedMeaning,
      'pronunciation': pronunciation,
      'related_terms': relatedTerms,
      'is_favorite': isFavorite,
      'is_bookmarked': isBookmarked,
      'last_searched': lastSearched?.toIso8601String(),
    };
  }

  LegalTerm copyWith({
    String? termId,
    String? term,
    String? originalMeaning,
    String? simplifiedMeaning,
    String? pronunciation,
    List<String>? relatedTerms,
    bool? isFavorite,
    bool? isBookmarked,
    DateTime? lastSearched,
  }) {
    return LegalTerm(
      termId: termId ?? this.termId,
      term: term ?? this.term,
      originalMeaning: originalMeaning ?? this.originalMeaning,
      simplifiedMeaning: simplifiedMeaning ?? this.simplifiedMeaning,
      pronunciation: pronunciation ?? this.pronunciation,
      relatedTerms: relatedTerms ?? this.relatedTerms,
      isFavorite: isFavorite ?? this.isFavorite,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastSearched: lastSearched ?? this.lastSearched,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LegalTerm &&
        other.termId == termId &&
        other.term == term &&
        other.originalMeaning == originalMeaning;
  }

  @override
  int get hashCode {
    return termId.hashCode ^ term.hashCode ^ originalMeaning.hashCode;
  }

  @override
  String toString() {
    return 'LegalTerm(termId: $termId, term: $term, originalMeaning: $originalMeaning, simplifiedMeaning: $simplifiedMeaning)';
  }
}