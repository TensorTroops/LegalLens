import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../services/comprehensive_legal_service.dart';

class PDFDownloadButton extends StatefulWidget {
  final ComprehensiveAnalysisResult analysisResult;
  final String? documentTitle;

  const PDFDownloadButton({
    super.key,
    required this.analysisResult,
    this.documentTitle,
  });

  @override
  State<PDFDownloadButton> createState() => _PDFDownloadButtonState();
}

class _PDFDownloadButtonState extends State<PDFDownloadButton> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _downloadPDFReport,
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf, size: 20),
        label: Text(_isGenerating ? 'Generating PDF...' : 'Download Full Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPDFReport() async {
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
                Text('Generating comprehensive legal report...'),
                SizedBox(height: 8),
                Text(
                  'Including all terms, risk analysis, and applicable laws',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      // Generate PDF (Note: In a real implementation, you'd need to add 
      // a PDF generation endpoint to your backend)
      final pdfBytes = await ComprehensiveLegalService.generatePDFReport(
        analysisResult: widget.analysisResult,
        filename: widget.documentTitle ?? 'legal_analysis_report',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success and offer to save/share
      await _showPDFOptions(pdfBytes);

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to generate PDF: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _showPDFOptions(Uint8List pdfBytes) async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Report Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your comprehensive legal analysis report has been generated successfully.'),
            const SizedBox(height: 16),
            Text('Report includes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildReportFeature('Document Summary'),
            _buildReportFeature('Legal Terms & Meanings (${widget.analysisResult.legalTerms.length} terms)'),
            _buildReportFeature('Professional Risk Analysis'),
            _buildReportFeature('Applicable Laws (${widget.analysisResult.applicableLaws.length} laws)'),
            const SizedBox(height: 16),
            Text(
              'File size: ${(pdfBytes.length / 1024).toStringAsFixed(1)} KB',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _savePDFToDevice(pdfBytes);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Save to Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _savePDFToDevice(Uint8List pdfBytes) async {
    try {
      // For web, this would trigger a download
      // For mobile, you'd use path_provider and file system
      
      // Copy to clipboard as fallback for now
      await Clipboard.setData(const ClipboardData(text: 'PDF report generated - download functionality would be implemented here'));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('PDF download functionality would be implemented here'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}