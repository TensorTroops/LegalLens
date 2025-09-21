import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSaveSummary;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onSaveSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: _buildMessageContainer(context),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.gavel,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF6C757D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageContainer(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser 
            ? const Color(0xFF4285F4) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: message.isUser 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
                ),
              ),
              if (!message.isUser && 
                  message.messageType == 'document_result' && 
                  onSaveSummary != null) ...[
                const Spacer(),
                _buildSaveSummaryButton(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    if (message.messageType == 'document_result') {
      return _buildDocumentResultContent();
    } else if (message.messageType == 'legal_answer') {
      return _buildLegalAnswerContent();
    } else {
      return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      message.message,
      style: TextStyle(
        fontSize: 14,
        color: message.isUser ? Colors.white : const Color(0xFF2D2D2D),
        height: 1.4,
      ),
    );
  }

  Widget _buildDocumentResultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(
              Icons.description,
              size: 16,
              color: Color(0xFF4285F4),
            ),
            const SizedBox(width: 8),
            const Text(
              'Document Analysis Complete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Content
        Text(
          message.message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D2D2D),
            height: 1.4,
          ),
        ),
        
        // Confidence indicator
        if (message.metadata != null) ...[
          const SizedBox(height: 12),
          _buildConfidenceIndicator(),
        ],
      ],
    );
  }

  Widget _buildLegalAnswerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Color(0xFF4285F4),
            ),
            SizedBox(width: 8),
            Text(
              'Legal Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Content
        Text(
          message.message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D2D2D),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator() {
    final metadata = message.metadata;
    if (metadata == null) return const SizedBox.shrink();
    
    final processingStatus = metadata['processingStatus'] as String?;
    final isSuccessful = processingStatus == 'success';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSuccessful 
            ? const Color(0xFF4285F4).withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccessful 
              ? const Color(0xFF4285F4).withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccessful ? Icons.verified : Icons.warning_amber_rounded,
            size: 16,
            color: isSuccessful ? const Color(0xFF4285F4) : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            isSuccessful ? 'Confidence 92%' : 'Partial Analysis',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSuccessful ? const Color(0xFF4285F4) : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveSummaryButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: onSaveSummary,
        icon: const Icon(Icons.save, size: 14),
        label: const Text(
          'Save Summary',
          style: TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}