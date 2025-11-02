import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../models/legal_term.dart';
import '../services/speech_service.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  List<Map<String, String>> _popularTerms = [];
  bool _isVoiceSearching = false;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize dictionary provider and speech service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DictionaryProvider>(context, listen: false).initialize();
      _loadPopularTerms();
      _initializeSpeechService();
    });
  }
  
  Future<void> _initializeSpeechService() async {
    try {
      await _speechService.initialize();
      debugPrint('Speech service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize speech service: $e');
    }
  }
  
  void _loadPopularTerms() {
    // Use hardcoded popular terms instead of backend call
    setState(() {
      _popularTerms = [
        {
          'term': 'Plaintiff',
          'meaning': 'A plaintiff is the person or party who brings a lawsuit against another in a court of law. They claim to have suffered a loss or injury caused by the defendant\'s actions. The plaintiff presents evidence and arguments to prove their case. If successful, the court may award them compensation or relief.'
        },
        {
          'term': 'Defendant',
          'meaning': 'A defendant is the person or entity being sued or accused in a legal case. In criminal cases, the defendant is the one charged with committing a crime. They have the right to defend themselves through evidence and legal representation. The court decides guilt or liability based on the presented facts.'
        },
        {
          'term': 'Jurisdiction',
          'meaning': 'Jurisdiction refers to the legal authority of a court to hear and decide a case. It can be based on geography, subject matter, or the type of parties involved. Without proper jurisdiction, a court\'s decision is invalid. It ensures that legal matters are handled in the correct court system.'
        },
        {
          'term': 'Contract',
          'meaning': 'A contract is a legally binding agreement between two or more parties. It outlines rights, duties, and obligations that each party must follow. To be valid, it usually requires an offer, acceptance, and consideration. Breach of contract can lead to legal action or financial penalties.'
        },
      ];
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
            color: Colors.black.withValues(alpha: 0.05),
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
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  await _searchTerm(value.trim());
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isSearching ? Colors.grey : const Color(0xFF34A853),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: _isSearching 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.keyboard_return,
                    color: Colors.white,
                    size: 20,
                  ),
              onPressed: _isSearching ? null : () async {
                final term = _searchController.text.trim();
                if (term.isNotEmpty) {
                  await _searchTerm(term);
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isVoiceSearching ? Colors.red : const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isVoiceSearching ? Icons.mic : Icons.mic_outlined,
                  color: Colors.white,
                  size: 20,
                  key: ValueKey(_isVoiceSearching),
                ),
              ),
              onPressed: _toggleVoiceSearch,
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
                    color: Colors.black.withValues(alpha: 0.05),
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
              children: _popularTerms.take(4).map((termData) => _buildPopularTermChip(termData)).toList(),
            ),
      ],
    );
  }

  Widget _buildPopularTermChip(Map<String, String> termData) {
    final term = termData['term']!;
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
      onTap: () => _showPopularTermMeaning(termData),
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

  void _showPopularTermMeaning(Map<String, String> termData) {
    final term = termData['term']!;
    final meaning = termData['meaning']!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                term,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.volume_up_outlined,
                color: Color(0xFF4285F4),
                size: 24,
              ),
              onPressed: () => _playPronunciation(term),
              tooltip: 'Listen to pronunciation',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      meaning,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D2D2D),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_outlined,
                      color: Color(0xFF4285F4),
                      size: 20,
                    ),
                    onPressed: () => _playPronunciation(meaning),
                    tooltip: 'Listen to definition',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Definition with speaker button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        term.originalMeaning,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D2D2D),
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_outlined,
                        color: const Color(0xFF4285F4),
                        size: 20,
                      ),
                      onPressed: () {
                        _playPronunciation(term.originalMeaning);
                      },
                      tooltip: 'Listen to definition',
                    ),
                  ],
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
                  // Simplified meaning with speaker button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          term.simplifiedMeaning!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF5F6368),
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_outlined,
                          color: const Color(0xFF4285F4),
                          size: 20,
                        ),
                        onPressed: () {
                          _playPronunciation(term.simplifiedMeaning!);
                        },
                        tooltip: 'Listen to simplified explanation',
                      ),
                    ],
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
                        color: const Color(0xFF4285F4).withValues(alpha: 0.3),
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
                        color: const Color(0xFF4285F4).withValues(alpha: 0.3),
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
            color: Colors.black.withValues(alpha: 0.05),
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
        currentIndex: 3, // Dictionary tab is selected
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
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Dictionary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // Files
              Navigator.pushReplacementNamed(context, '/my-files');
              break;
            case 2:
              // Chat
              Navigator.pushReplacementNamed(context, '/legal-chat');
              break;
            case 3:
              // Dictionary - Already on Dictionary, do nothing
              break;
            case 4:
              // Profile
              _showProfileOptions();
              break;
          }
        },
      ),
    );
  }

  Future<void> _searchTerm(String term) async {
    setState(() {
      _isSearching = true;
    });
    
    try {
      await Provider.of<DictionaryProvider>(context, listen: false).searchTerm(term);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isVoiceSearching) {
      // Stop voice search
      await _speechService.stopListening();
      setState(() {
        _isVoiceSearching = false;
      });
    } else {
      // Start voice search
      setState(() {
        _isVoiceSearching = true;
      });
      
      try {
        await _speechService.startListening(
          timeout: const Duration(seconds: 30), // Shorter timeout for better UX
          onResult: (result) {
            if (result.isNotEmpty) {
              // Update the search text field with the voice result
              setState(() {
                _searchController.text = result;
                _isVoiceSearching = false; // Stop voice search after getting result
              });
              
              // Show feedback that voice input was captured
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Voice input captured: "$result"'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Search',
                      textColor: Colors.white,
                      onPressed: () {
                        if (result.trim().isNotEmpty) {
                          _searchTerm(result.trim());
                        }
                      },
                    ),
                  ),
                );
              }
            }
          },
        );
      } catch (e) {
        setState(() {
          _isVoiceSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice search failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _playPronunciation(String text) async {
    try {
      // Provide visual feedback that TTS is starting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Playing audio...',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4285F4),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
      
      // Use the speech service to speak the text
      await _speechService.speak(text);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Text-to-speech failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _playPronunciation(text),
            ),
          ),
        );
      }
    }
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

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen when available
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                
                if (shouldSignOut == true && mounted) {
                  // Note: Import AuthProvider as app_auth to avoid conflicts
                  // import '../providers/auth_provider.dart' as app_auth;
                  // await Provider.of<app_auth.AuthProvider>(context, listen: false).signOut();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}