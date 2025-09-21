import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/legal_term.dart';
import '../services/api_client.dart';

class DictionaryService {
  final ApiClient _apiClient = ApiClient();
  
  // Cache keys
  static const String _recentSearchesKey = 'recent_searches';
  static const String _favoritesKey = 'favorite_terms';
  static const String _bookmarksKey = 'bookmarked_terms';

  /// Search for a specific legal term in Spanner database
  Future<LegalTerm?> searchLegalTerm(String term) async {
    try {
      // Call backend API to search Spanner DB and get Gemini-simplified meaning
      final response = await _apiClient.searchLegalTerms(term);
      
      if (response['success'] == true && response['data'] != null) {
        final termData = response['data'];
        
        return LegalTerm(
          termId: termData['term_id'] ?? term.toLowerCase().replaceAll(' ', '_'),
          term: termData['term'] ?? term,
          originalMeaning: termData['original_meaning'] ?? '',
          simplifiedMeaning: termData['simplified_meaning'],
          pronunciation: termData['pronunciation'],
          relatedTerms: termData['related_terms'] != null 
              ? List<String>.from(termData['related_terms'])
              : null,
        );
      }
      
      return null;
    } catch (e) {
      // If API fails, return null (term not found)
      return null;
    }
  }

  /// Search for multiple terms (for autocomplete)
  Future<List<LegalTerm>> searchMultipleTerms(String query) async {
    try {
      final response = await _apiClient.autocompleteLegalTerms(query);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> termsData = response['data'];
        
        return termsData.map((data) => LegalTerm(
          termId: data['term_id'] ?? data['term'].toString().toLowerCase().replaceAll(' ', '_'),
          term: data['term'] ?? '',
          originalMeaning: data['original_meaning'] ?? '',
          simplifiedMeaning: data['simplified_meaning'],
          pronunciation: data['pronunciation'],
        )).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get popular legal terms
  Future<List<LegalTerm>> getPopularTerms() async {
    try {
      final response = await _apiClient.getPopularTerms();
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> termsData = response['data'];
        
        return termsData.map((data) => LegalTerm(
          termId: data['term_id'] ?? data['term'].toString().toLowerCase().replaceAll(' ', '_'),
          term: data['term'] ?? '',
          originalMeaning: data['original_meaning'] ?? '',
          simplifiedMeaning: data['simplified_meaning'],
          pronunciation: data['pronunciation'],
        )).toList();
      }
      
      return _getDefaultPopularTerms();
    } catch (e) {
      return _getDefaultPopularTerms();
    }
  }

  /// Get recent searches from local storage
  Future<List<LegalTerm>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recentSearchesJson = prefs.getString(_recentSearchesKey);
      
      if (recentSearchesJson != null) {
        final List<dynamic> decoded = jsonDecode(recentSearchesJson);
        return decoded.map((data) => LegalTerm.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Save a recent search to local storage
  Future<void> saveRecentSearch(LegalTerm term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<LegalTerm> recentSearches = await getRecentSearches();
      
      // Remove if already exists
      recentSearches.removeWhere((existingTerm) => existingTerm.termId == term.termId);
      
      // Add to beginning
      recentSearches.insert(0, term.copyWith(lastSearched: DateTime.now()));
      
      // Keep only last 10
      if (recentSearches.length > 10) {
        recentSearches.removeRange(10, recentSearches.length);
      }
      
      // Save to storage
      final String encoded = jsonEncode(recentSearches.map((t) => t.toJson()).toList());
      await prefs.setString(_recentSearchesKey, encoded);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Remove a term from recent searches
  Future<void> removeFromRecentSearches(String termId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<LegalTerm> recentSearches = await getRecentSearches();
      
      recentSearches.removeWhere((term) => term.termId == termId);
      
      final String encoded = jsonEncode(recentSearches.map((t) => t.toJson()).toList());
      await prefs.setString(_recentSearchesKey, encoded);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Get favorite terms from local storage
  Future<List<LegalTerm>> getFavoriteTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        return decoded.map((data) => LegalTerm.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Toggle favorite status of a term
  Future<bool> toggleFavorite(String termId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<LegalTerm> favorites = await getFavoriteTerms();
      
      final existingIndex = favorites.indexWhere((term) => term.termId == termId);
      
      if (existingIndex >= 0) {
        // Remove from favorites
        favorites.removeAt(existingIndex);
      } else {
        // Add to favorites (need to get the full term data)
        // For now, we'll just mark it as favorite
        // In a real app, you'd fetch the full term data
      }
      
      final String encoded = jsonEncode(favorites.map((t) => t.toJson()).toList());
      await prefs.setString(_favoritesKey, encoded);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get bookmarked terms from local storage
  Future<List<LegalTerm>> getBookmarkedTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? bookmarksJson = prefs.getString(_bookmarksKey);
      
      if (bookmarksJson != null) {
        final List<dynamic> decoded = jsonDecode(bookmarksJson);
        return decoded.map((data) => LegalTerm.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Toggle bookmark status of a term
  Future<bool> toggleBookmark(String termId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<LegalTerm> bookmarks = await getBookmarkedTerms();
      
      final existingIndex = bookmarks.indexWhere((term) => term.termId == termId);
      
      if (existingIndex >= 0) {
        // Remove from bookmarks
        bookmarks.removeAt(existingIndex);
      } else {
        // Add to bookmarks (need to get the full term data)
        // For now, we'll just mark it as bookmarked
        // In a real app, you'd fetch the full term data
      }
      
      final String encoded = jsonEncode(bookmarks.map((t) => t.toJson()).toList());
      await prefs.setString(_bookmarksKey, encoded);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get default popular terms if API fails
  List<LegalTerm> _getDefaultPopularTerms() {
    return [
      LegalTerm(
        termId: 'Subrogation',
        term: 'Subrogation',
        originalMeaning: 'The legal right of an insurer to pursue a third party responsible for an insurance loss to the insured, allowing the insurer to recover the amount paid to the policyholder.',
        simplifiedMeaning: 'The legal right of an insurer to pursue a third party responsible for an insurance loss to the insured, allowing the insurer to recover the amount paid to the policyholder.',
        pronunciation: '[Subrogation]',
      ),
      LegalTerm(
        termId: 'Res Judicata',
        term: 'Res Judicata',
        originalMeaning: 'A legal doctrine that bars continued litigation of a case that has already been conclusively decided by a competent court.',
        simplifiedMeaning: 'A legal doctrine that prevents the same issue from being tried again.',
        pronunciation: '[rez joo-di-kah-tah]',
      ),
      LegalTerm(
        termId: 'Indemnity',
        term: 'Indemnity',
        originalMeaning: 'A contractual obligation of one party to compensate the loss incurred by another party due to acts of the indemnifier or any other party.',
        simplifiedMeaning: 'A contractual obligation to compensate for loss or damage.',
        pronunciation: '[ɪnˈdɛm.nɪ.ti]',
      ),
      LegalTerm(
        termId: 'affidavit',
        term: 'Affidavit',
        originalMeaning: 'A written statement confirmed by oath or affirmation, for use as evidence in court.',
        simplifiedMeaning: 'A written statement that you swear is true, which can be used in court.',
        pronunciation: '[af-i-DAY-vit]',
      ),
      LegalTerm(
        termId: 'jurisdiction',
        term: 'Jurisdiction',
        originalMeaning: 'The authority given to a legal body, such as a court, to administer justice within a defined field of responsibility.',
        simplifiedMeaning: 'The power and authority of a court to hear and decide cases in a particular area.',
        pronunciation: '[joor-is-DIK-shuhn]',
      ),
    ];
  }
}