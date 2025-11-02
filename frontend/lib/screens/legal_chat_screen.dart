import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/legal_chat_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../models/chat_message.dart';
import '../services/speech_service.dart';
import '../services/document_upload_service.dart';
import '../widgets/chat_message_bubble.dart';

class LegalChatScreen extends StatefulWidget {
  const LegalChatScreen({super.key});

  @override
  State<LegalChatScreen> createState() => _LegalChatScreenState();
}

class _LegalChatScreenState extends State<LegalChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SpeechService _speechService = SpeechService();
  bool _isVoiceInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LegalChatProvider>(context, listen: false);
      if (provider.messages.isEmpty) {
        _addWelcomeMessage();
      }
      _processNavigationArguments();
    });
  }

  void _processNavigationArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialText')) {
        final extractedText = args['initialText'] as String;
        final documentTitle = args['documentTitle'] as String? ?? 'Legal Document';
        final useComprehensiveAnalysis = args['comprehensive'] as bool? ?? true; // Default to comprehensive
        
        if (extractedText.isNotEmpty) {
          final provider = Provider.of<LegalChatProvider>(context, listen: false);
          
          // Use comprehensive analysis for better document processing
          if (useComprehensiveAnalysis) {
            provider.processComprehensiveLegalDocument(extractedText, documentTitle).then((_) {
              // Success - comprehensive analysis completed
            }).catchError((error) {
              debugPrint('Comprehensive analysis error: $error');
              // Fallback to regular processing
              provider.processLegalDocument(extractedText, documentTitle);
            });
          } else {
            // Use the original processing method
            provider.processLegalDocument(extractedText, documentTitle).then((_) {
            }).catchError((error) {
              debugPrint('Document processing error: $error');
            });
          }
          
          _scrollToBottom();
        }
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
    _scrollToBottom();
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  void _uploadDocument() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to upload documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DocumentUploadDialog(
        userEmail: user.email!,
        onUploadComplete: (result) {
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Document "${result.filename}" uploaded and processed successfully!',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            if (result.processingData != null) {
              _processMCPResponse(
                  result.processingData!, result.filename ?? 'Document');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(result.error ?? 'Upload failed')),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
      ),
    );
  }

  void _processMCPResponse(Map<String, dynamic> mcpData, String filename) {
    final provider = Provider.of<LegalChatProvider>(context, listen: false);
    final comprehensiveAnalysis = mcpData['comprehensive_analysis'];
    final documentExtraction = mcpData['document_extraction'];

    if (comprehensiveAnalysis != null) {
      String responseMessage = '''Document "$filename" Analysis Complete!

**Document Analysis Completed Successfully**

Document processed successfully - you can now ask questions about it!

Try asking:
• "What are the main obligations in this document?"
• "Explain the key terms in simple language"
• "What should I be aware of in this document?"''';

      // Add to chat history

      provider.addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: responseMessage,
        timestamp: DateTime.now(),
        isUser: false,
        messageType: 'document_result',
        metadata: {
          'filename': filename,
          'comprehensiveAnalysis': comprehensiveAnalysis,
          'documentExtraction': documentExtraction,
          'mcpProcessed': true,
        },
      ));
      _scrollToBottom();
    }
  }

  void _askQuestion() {
    _textController.text = 'What is a non-disclosure agreement?';
    _focusNode.requestFocus();
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
                  return const Icon(Icons.balance,
                      size: 18, color: Colors.white);
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
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              if (provider.isLoading || provider.isSavingDemo)
                Padding(
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
                        provider.isSavingDemo 
                            ? 'Saving document summary...' 
                            : 'Processing document...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              if (provider.messages.length == 1 &&
                  provider.messages[0].messageType == 'welcome')
                _buildSuggestedActions(),
              _buildInputArea(),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return ChatMessageBubble(
      message: message,
      onSaveSummary: message.messageType == 'document_result' ? () => _saveSummary() : null,
    );
  }

  Future<void> _saveSummary() async {
    final provider = Provider.of<LegalChatProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final isDemoUser = user?.email == 'smp@gmail.com';
    
    try {
      // Only show dialog for non-demo users
      if (!isDemoUser) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Saving summary...'),
              ],
            ),
          ),
        );
      }

      // Save the summary (this will handle demo delay internally)
      await provider.saveSummary();

      // Close loading dialog for non-demo users
      if (!isDemoUser && mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDemoUser 
                ? 'Demo: Document summary saved successfully!' 
                : 'Document summary saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog for non-demo users
      if (!isDemoUser && mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save summary: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildSuggestedActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildRoundedButton('Upload Document', Icons.upload_file, _uploadDocument),
          _buildRoundedButton('Ask Question', Icons.question_answer, _askQuestion),
        ],
      ),
    );
  }

  Widget _buildRoundedButton(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4285F4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
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
            icon: const Icon(Icons.upload_file, color: Color(0xFF6B7280)),
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
                        hintStyle:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isVoiceInput ? Icons.mic : Icons.mic_outlined,
                        color: _isVoiceInput
                            ? Colors.red
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    onPressed: _toggleVoiceInput,
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          size: 16, color: Colors.white),
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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF4285F4),
      unselectedItemColor: const Color(0xFF9CA3AF),
      currentIndex: 2,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined), label: 'Files'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), label: 'Chat'),
        BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined), label: 'Dictionary'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/my-files');
            break;
          case 2:
            // Already on Chat - do nothing
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/dictionary');
            break;
          case 4:
            // Profile - could show profile menu or navigate to profile screen
            _showProfileOptions();
            break;
        }
      },
    );
  }

  Future<void> _toggleVoiceInput() async {
    if (_isVoiceInput) {
      await _speechService.stopListening();
      setState(() => _isVoiceInput = false);
    } else {
      setState(() => _isVoiceInput = true);
      try {
        await _speechService.startListening(
          timeout: const Duration(minutes: 5),
          onResult: (result) {
            if (result.isNotEmpty) {
              setState(() => _textController.text = result);
              _focusNode.requestFocus();
            }
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice input failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                  await Provider.of<app_auth.AuthProvider>(context, listen: false).signOut();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
