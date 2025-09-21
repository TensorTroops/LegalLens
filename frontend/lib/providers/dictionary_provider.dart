import 'package:flutter/foundation.dart';
import '../models/legal_term.dart';
import '../services/dictionary_service.dart';

class DictionaryProvider with ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  
  // State variables
  LegalTerm? _selectedTerm;
  List<LegalTerm> _searchResults = [];
  List<LegalTerm> _recentSearches = [];
  List<LegalTerm> _favoriteTerms = [];
  List<LegalTerm> _bookmarkedTerms = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  String _lastSearchQuery = '';

  // Getters
  LegalTerm? get selectedTerm => _selectedTerm;
  List<LegalTerm> get searchResults => _searchResults;
  List<LegalTerm> get recentSearches => _recentSearches;
  List<LegalTerm> get favoriteTerms => _favoriteTerms;
  List<LegalTerm> get bookmarkedTerms => _bookmarkedTerms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get lastSearchQuery => _lastSearchQuery;

  /// Initialize the dictionary provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadRecentSearches();
      await _loadFavorites();
      await _loadBookmarks();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize dictionary: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Search for a legal term
  Future<void> searchTerm(String query) async {
    if (query.trim().isEmpty) return;
    
    _setLoading(true);
    _lastSearchQuery = query.trim();
    
    try {
      final term = await _dictionaryService.searchLegalTerm(query.trim());
      
      if (term != null) {
        _selectedTerm = term;
        _addToRecentSearches(term);
        _clearError();
      } else {
        _selectedTerm = null;
        _setError('Term "$query" not found in dictionary');
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to search for term: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Search for multiple terms (for autocomplete)
  Future<List<LegalTerm>> searchTerms(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final results = await _dictionaryService.searchMultipleTerms(query.trim());
      _searchResults = results;
      notifyListeners();
      return results;
    } catch (e) {
      _setError('Failed to search terms: ${e.toString()}');
      return [];
    }
  }

  /// Clear the selected term and return to search interface
  void clearSelectedTerm() {
    _selectedTerm = null;
    _clearError();
    notifyListeners();
  }

  /// Toggle favorite status of a term
  Future<void> toggleFavorite(String termId) async {
    try {
      final success = await _dictionaryService.toggleFavorite(termId);
      if (success) {
        // Update selected term if it's the same
        if (_selectedTerm?.termId == termId) {
          _selectedTerm = _selectedTerm!.copyWith(
            isFavorite: !_selectedTerm!.isFavorite,
          );
        }
        
        // Reload favorites list
        await _loadFavorites();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update favorite: ${e.toString()}');
    }
  }

  /// Toggle bookmark status of a term
  Future<void> toggleBookmark(String termId) async {
    try {
      final success = await _dictionaryService.toggleBookmark(termId);
      if (success) {
        // Update selected term if it's the same
        if (_selectedTerm?.termId == termId) {
          _selectedTerm = _selectedTerm!.copyWith(
            isBookmarked: !_selectedTerm!.isBookmarked,
          );
        }
        
        // Reload bookmarks list
        await _loadBookmarks();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update bookmark: ${e.toString()}');
    }
  }

  /// Get popular terms
  Future<List<LegalTerm>> getPopularTerms() async {
    try {
      return await _dictionaryService.getPopularTerms();
    } catch (e) {
      _setError('Failed to load popular terms: ${e.toString()}');
      return [];
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      await _dictionaryService.clearSearchHistory();
      _recentSearches.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear search history: ${e.toString()}');
    }
  }

  /// Remove a term from recent searches
  Future<void> removeFromRecentSearches(String termId) async {
    try {
      await _dictionaryService.removeFromRecentSearches(termId);
      _recentSearches.removeWhere((term) => term.termId == termId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove from recent searches: ${e.toString()}');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadRecentSearches() async {
    try {
      _recentSearches = await _dictionaryService.getRecentSearches();
    } catch (e) {
      debugPrint('Failed to load recent searches: ${e.toString()}');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      _favoriteTerms = await _dictionaryService.getFavoriteTerms();
    } catch (e) {
      debugPrint('Failed to load favorites: ${e.toString()}');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      _bookmarkedTerms = await _dictionaryService.getBookmarkedTerms();
    } catch (e) {
      debugPrint('Failed to load bookmarks: ${e.toString()}');
    }
  }

  void _addToRecentSearches(LegalTerm term) {
    // Remove if already exists to avoid duplicates
    _recentSearches.removeWhere((existingTerm) => existingTerm.termId == term.termId);
    
    // Add to beginning of list
    _recentSearches.insert(0, term.copyWith(lastSearched: DateTime.now()));
    
    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    
    // Save to persistent storage
    _dictionaryService.saveRecentSearch(term);
  }

  /// Clear all state
  void clear() {
    _selectedTerm = null;
    _searchResults.clear();
    _recentSearches.clear();
    _favoriteTerms.clear();
    _bookmarkedTerms.clear();
    _isLoading = false;
    _errorMessage = null;
    _lastSearchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}