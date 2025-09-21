import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../models/legal_term.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _popularTerms = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize dictionary provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DictionaryProvider>(context, listen: false).initialize();
      _loadPopularTerms();
    });
  }
  
  void _loadPopularTerms() async {
    final provider = Provider.of<DictionaryProvider>(context, listen: false);
    final popularTerms = await provider.getPopularTerms();
    setState(() {
      _popularTerms = popularTerms.map((term) => term.term).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<DictionaryProvider>(
                builder: (context, provider, child) {
                  if (provider.selectedTerm != null) {
                    return _buildTermDetail(provider.selectedTerm!);
                  }
                  return _buildSearchInterface();
                },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          // App icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.balance,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Legal Dictionary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const Spacer(),
          // Light/Dark mode toggle
          IconButton(
            icon: const Icon(
              Icons.light_mode_outlined,
              color: Color(0xFF757575),
              size: 20,
            ),
            onPressed: () {
              // Toggle theme
            },
          ),
          // Settings
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Color(0xFF757575),
              size: 20,
            ),
            onPressed: () {
              // Help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildClearHistoryButton(),
          const SizedBox(height: 24),
          _buildPopularTermsSection(),
          const SizedBox(height: 24),
          _buildRecentSearchesSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Type to search...',
                hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF9E9E9E),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchTerm(value.trim());
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.mic_outlined,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                // Voice search functionality
                _showVoiceSearch();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearHistoryButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Clear search history
          _showClearHistoryDialog();
        },
        child: const Text(
          'Clear History',
          style: TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPopularTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Terms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 12),
        _popularTerms.isEmpty 
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularTerms.take(6).map((term) => _buildPopularTermChip(term)).toList(),
            ),
      ],
    );
  }

  Widget _buildPopularTermChip(String term) {
    // Use different colors for variety
    final colors = [
      const Color(0xFF4285F4), // Blue
      const Color(0xFF34A853), // Green  
      const Color(0xFFEA4335), // Red
      const Color(0xFFFBBC04), // Yellow
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
    ];
    
    final colorIndex = term.hashCode % colors.length;
    final chipColor = colors[colorIndex.abs()];

    return GestureDetector(
      onTap: () => _searchTerm(term),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          term,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchesSection() {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        if (provider.recentSearches.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No recent searches',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            ...provider.recentSearches.take(5).map((term) => _buildRecentSearchItem(term)),
          ],
        );
      },
    );
  }

  Widget _buildRecentSearchItem(LegalTerm term) {
    final timeAgo = term.lastSearched != null 
        ? _getTimeAgo(term.lastSearched!)
        : 'Unknown time';
        
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          term.term,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D2D2D),
          ),
        ),
        trailing: Text(
          timeAgo,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
        onTap: () => _searchTerm(term.term),
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildTermDetail(LegalTerm term) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Provider.of<DictionaryProvider>(context, listen: false).clearSelectedTerm();
                },
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Term title with pronunciation
          Text(
            term.term,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Pronunciation
          Row(
            children: [
              Text(
                term.pronunciation ?? '[${term.term.toLowerCase()}]',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9E9E9E),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.volume_up_outlined,
                  color: Color(0xFF4285F4),
                  size: 20,
                ),
                onPressed: () {
                  // Play pronunciation
                  _playPronunciation(term.term);
                },
              ),
              const Spacer(),
              // Favorite and bookmark icons
              IconButton(
                icon: Icon(
                  term.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: term.isFavorite ? Colors.red : Color(0xFF9E9E9E),
                  size: 24,
                ),
                onPressed: () {
                  Provider.of<DictionaryProvider>(context, listen: false).toggleFavorite(term.termId);
                },
              ),
              IconButton(
                icon: Icon(
                  term.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: term.isBookmarked ? Color(0xFF4285F4) : Color(0xFF9E9E9E),
                  size: 24,
                ),
                onPressed: () {
                  Provider.of<DictionaryProvider>(context, listen: false).toggleBookmark(term.termId);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Original meaning container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term.originalMeaning,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D2D2D),
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
                if (term.simplifiedMeaning != null && term.simplifiedMeaning != term.originalMeaning) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 16),
                  const Text(
                    'Simplified Explanation:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    term.simplifiedMeaning!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5F6368),
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Related terms section
          if (term.relatedTerms != null && term.relatedTerms!.isNotEmpty) ...[
            const Text(
              'See Also:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: term.relatedTerms!.map((relatedTerm) => 
                GestureDetector(
                  onTap: () => _searchTerm(relatedTerm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4285F4).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      relatedTerm,
                      style: const TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ] else ...[
            // Show some default related legal terms
            const Text(
              'See Also:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Contract Law', 'Frustration Law', 'Impossibility'].map((relatedTerm) => 
                GestureDetector(
                  onTap: () => _searchTerm(relatedTerm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4285F4).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      relatedTerm,
                      style: const TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4285F4),
        unselectedItemColor: const Color(0xFF9E9E9E),
        currentIndex: 1, // Dictionary tab is selected
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context); // Go back to Home
              break;
            case 1:
              // Files
              break;
            case 2:
              // Chat
              Navigator.pushNamed(context, '/legal-chat');
              break;
            case 3:
              // Learn
              break;
            case 4:
              // Profile
              break;
          }
        },
      ),
    );
  }

  void _searchTerm(String term) {
    Provider.of<DictionaryProvider>(context, listen: false).searchTerm(term);
  }

  void _showVoiceSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Column(
          children: [
            const Icon(
              Icons.mic,
              size: 48,
              color: Color(0xFF4285F4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Speak now...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Say a legal term to search',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Are you sure you want to clear all search history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear history logic here
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _playPronunciation(String term) {
    // Implement text-to-speech for pronunciation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing pronunciation for "$term"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}