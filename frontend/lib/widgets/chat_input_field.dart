import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quick Actions Button
            IconButton(
              onPressed: widget.isEnabled ? _showQuickActions : null,
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF4285F4),
              ),
              tooltip: 'Quick Actions',
            ),
            
            const SizedBox(width: 8),
            
            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a legal question...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  onSubmitted: widget.isEnabled && _hasText 
                      ? (_) => widget.onSend()
                      : null,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send Button
            Container(
              decoration: BoxDecoration(
                color: _hasText && widget.isEnabled 
                    ? const Color(0xFF4285F4)
                    : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: _hasText && widget.isEnabled 
                    ? widget.onSend 
                    : null,
                icon: Icon(
                  Icons.send,
                  color: _hasText && widget.isEnabled 
                      ? Colors.white 
                      : const Color(0xFF9E9E9E),
                  size: 20,
                ),
                tooltip: 'Send Message',
              ),
            ),
            
            // Voice Input Button
            const SizedBox(width: 4),
            IconButton(
              onPressed: widget.isEnabled ? _startVoiceInput : null,
              icon: Icon(
                Icons.mic_outlined,
                color: widget.isEnabled 
                    ? const Color(0xFF4285F4)
                    : const Color(0xFF9E9E9E),
              ),
              tooltip: 'Voice Input',
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildQuickActionItem(
              icon: Icons.description_outlined,
              title: 'Upload Document',
              subtitle: 'Analyze a legal document',
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to home to upload
              },
            ),
            
            _buildQuickActionItem(
              icon: Icons.quiz_outlined,
              title: 'Ask Question',
              subtitle: 'Get legal information',
              onTap: () {
                Navigator.pop(context);
                widget.controller.text = 'What is a ';
              },
            ),
            
            _buildQuickActionItem(
              icon: Icons.history,
              title: 'View History',
              subtitle: 'See previous summaries',
              onTap: () {
                Navigator.pop(context);
                _showHistory();
              },
            ),
            
            _buildQuickActionItem(
              icon: Icons.help_outline,
              title: 'Legal Terms',
              subtitle: 'Common legal definitions',
              onTap: () {
                Navigator.pop(context);
                _showLegalTerms();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4285F4),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2D2D),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _startVoiceInput() {
    // TODO: Implement voice input functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHistory() {
    // TODO: Navigate to history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLegalTerms() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common Legal Terms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildTermItem('Force Majeure', 'Unforeseeable circumstances that prevent contract fulfillment'),
                    _buildTermItem('Non-Disclosure Agreement', 'Contract creating confidential relationship between parties'),
                    _buildTermItem('Indemnification', 'Protection against claims or damages'),
                    _buildTermItem('Liability', 'Legal responsibility for actions or damages'),
                    _buildTermItem('Breach of Contract', 'Failure to perform contractual obligations'),
                    _buildTermItem('Due Diligence', 'Investigation or audit of potential investment'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermItem(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            definition,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}