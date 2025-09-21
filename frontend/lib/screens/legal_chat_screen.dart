import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/legal_chat_provider.dart';
import '../models/chat_message.dart';

class LegalChatScreen extends StatefulWidget {
  const LegalChatScreen({super.key});

  @override
  State<LegalChatScreen> createState() => _LegalChatScreenState();
}

class _LegalChatScreenState extends State<LegalChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LegalChatProvider>(context, listen: false);
      if (provider.messages.isEmpty) {
        _addWelcomeMessage();
      }
      
      // Check for navigation arguments containing extracted text
      _processNavigationArguments();
    });
  }

  void _processNavigationArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      print('🔍 DEBUG: Navigation arguments: $args');
      
      if (args != null && args.containsKey('initialText')) {
        final extractedText = args['initialText'] as String;
        final documentTitle = args['documentTitle'] as String? ?? 'Legal Document';
        
        print('🔍 DEBUG: Extracted text length: ${extractedText.length}');
        print('🔍 DEBUG: Document title: $documentTitle');
        
        if (extractedText.isNotEmpty) {
          final provider = Provider.of<LegalChatProvider>(context, listen: false);
          
          
          // Process the document
          provider.processLegalDocument(extractedText, documentTitle).then((_) {
            print('🔍 DEBUG: Document processing completed');
          }).catchError((error) {
            print('🔍 DEBUG: Document processing error: $error');
          });
          
          _scrollToBottom();
        } else {
          print('🔍 DEBUG: Extracted text is empty');
        }
      } else {
        print('🔍 DEBUG: No navigation arguments or initialText not found');
      }
    });
  }

  void _addWelcomeMessage() {
    final provider = Provider.of<LegalChatProvider>(context, listen: false);
    provider.addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: "Hello! I am your AI Legal Assistant.\nHow can I help you today?",
      timestamp: DateTime.now(),
      isUser: false,
      messageType: 'welcome',
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    
    final provider = Provider.of<LegalChatProvider>(context, listen: false);
    
    // Add user message
    provider.addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      timestamp: DateTime.now(),
      isUser: true,
    ));
    
    _scrollToBottom();
    
    // Process as legal question
    await provider.sendMessage(text);
    
    _scrollToBottom();
  }

  void _uploadDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('This feature will allow you to upload legal documents for analysis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _askQuestion() {
    _textController.text = 'What is a non-disclosure agreement?';
    _focusNode.requestFocus();
  }

  String _formatMessage(String message) {
    // Remove asterisks and format the message properly
    String formatted = message
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'') // Remove bold markdown
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'') // Remove italic markdown
        .replaceAll('*', '') // Remove any remaining asterisks
        .trim();
    
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.balance,
                    size: 18,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
          onPressed: () {},
        ),
        title: const Text(
          'Legal Assistant',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF6B7280)),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<LegalChatProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              
              // Loading indicator when processing
              if (provider.isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Processing document...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Suggested actions (only show if first message is welcome)
              if (provider.messages.length == 1 && provider.messages[0].messageType == 'welcome')
                _buildSuggestedActions(),
              
              // Input area
              _buildInputArea(),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final formattedMessage = _formatMessage(message.message);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.balance,
                      size: 16,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF4285F4) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedMessage,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser && message.messageType != 'welcome') ...[
                    const SizedBox(height: 12),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // _buildActionButton('Suggest Revisions', () {}),
                        const SizedBox(width: 8),
                        _buildActionButton('Save Summary', () {
                          _saveSummaryDirectly();
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _uploadDocument,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Upload Document',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _askQuestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ask Question',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF6B7280),
            ),
            onPressed: _uploadDocument,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type a test question...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.mic_outlined,
                      color: Color(0xFF6B7280),
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4285F4),
        unselectedItemColor: const Color(0xFF9CA3AF),
        currentIndex: 2, // Chat is selected
        elevation: 0,
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
            icon: Icon(Icons.chat_bubble),
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
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // Files
              break;
            case 2:
              // Already on Chat
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

  void _saveSummaryDirectly() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Saving summary...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final provider = Provider.of<LegalChatProvider>(context, listen: false);
      await provider.saveSummary();
      
      // Clear the loading snackbar and show success
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Summary saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Clear the loading snackbar and show error
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to save summary: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}