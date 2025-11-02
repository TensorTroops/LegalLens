import 'package:flutter/material.dart';
import '../services/comprehensive_legal_service.dart';

class ChatPDFDownloadButton extends StatefulWidget {
  final String documentId;
  final String? documentTitle;
  final VoidCallback? onDownloadComplete;

  const ChatPDFDownloadButton({
    super.key,
    required this.documentId,
    this.documentTitle,
    this.onDownloadComplete,
  });

  @override
  State<ChatPDFDownloadButton> createState() => _ChatPDFDownloadButtonState();
}

class _ChatPDFDownloadButtonState extends State<ChatPDFDownloadButton> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _downloadPDFReport,
        icon: _isGenerating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf, size: 16),
        label: Text(
          _isGenerating ? 'Generating...' : 'Download Full Report',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPDFReport() async {
    if (widget.documentId.isEmpty) {
      _showError('Document ID not available');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating comprehensive report...'),
                SizedBox(height: 8),
                Text(
                  'This includes legal terms, risk analysis, and applicable laws',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Request comprehensive analysis and PDF generation from backend
      // First, we need to get the analysis data for the document
      // In a real implementation, you would retrieve the analysis data and generate PDF bytes
      
      // Call the backend to get actual PDF bytes
      final service = ComprehensiveLegalService();
      final response = await service.generatePDFFromDocumentId(
        documentId: widget.documentId,
        documentTitle: widget.documentTitle,
      );
      
      // Check if we got a success response
      if (response['success'] == true) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show success with actual file location info
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('PDF downloaded successfully!'),
                        Text(
                          'File: ${response['filename']}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        Text(
                          'Size: ${response['size']} bytes',
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                        const Text(
                          'Check your Downloads folder',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        throw Exception('PDF generation failed: ${response['message'] ?? 'Unknown error'}');
      }

      // Call completion callback
      widget.onDownloadComplete?.call();

    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showError('Failed to generate PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}