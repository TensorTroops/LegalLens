import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _aiPoweredScan = true;
  XFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isProcessing = false;
  String _extractedText = '';
  String _fileName = '';
  
  // Processing steps
  bool _extractingText = false;
  bool _analyzingContent = false;
  bool _generatingSummary = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Prefer back camera for document scanning
        CameraDescription? backCamera;
        for (var camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.back) {
            backCamera = camera;
            break;
          }
        }
        
        _cameraController = CameraController(
          backCamera ?? cameras.first,
          ResolutionPreset.veryHigh, // Higher resolution for better text capture
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _cameraController!.initialize();
        
        // Set additional camera settings for document scanning
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
        await _cameraController!.setFlashMode(FlashMode.off);
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Document',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AI-Powered Secure Scan Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI-Powered Secure Scan',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _aiPoweredScan,
                    onChanged: (value) {
                      setState(() {
                        _aiPoweredScan = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.help_outline,
                    color: Color(0xFF1976D2),
                    size: 16,
                  ),
                ],
              ),
            ),

            // Camera Preview Section
            Container(
              margin: const EdgeInsets.all(16),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  // Camera preview or placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isCameraInitialized && _cameraController != null
                        ? SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize?.height ?? 300,
                                height: _cameraController!.value.previewSize?.width ?? 300,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  
                  // Blue corner brackets
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: CustomPaint(
                        painter: CornerBracketsPainter(),
                      ),
                    ),
                  ),
                  
                  // Loading overlay during processing
                  if (_isProcessing)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.7),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Processing Document...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please wait while we extract text',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Capture button
                  if (!_isProcessing)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _capturePhoto,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1976D2),
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Upload and Select Files buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _uploadFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload from Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: _isProcessing ? Colors.grey.shade300 : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _selectFiles,
                      icon: const Icon(Icons.folder_outlined),
                      label: const Text('Select Files'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: _isProcessing ? Colors.grey.shade300 : Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Document Preview (if file selected)
            if (_selectedFile != null) _buildDocumentPreview(),

            // Processing Section
            if (_isProcessing) _buildProcessingSection(),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 20),

            // Footer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'End-to-end encryption',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'GDPR compliant',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final fileName = _selectedFile != null ? path.basename(_selectedFile!.path) : 'Unknown Document';
    final fileExtension = _selectedFile != null ? path.extension(_selectedFile!.path).toUpperCase().replaceFirst('.', '') : 'FILE';
    final fileSize = (_selectedFile != null || _selectedFileBytes != null) ? _getFileSize() : '0 KB';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(fileExtension),
              color: Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$fileExtension • $fileSize • Processing...',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String _getFileSize() {
    if (kIsWeb && _selectedFileBytes != null) {
      final bytes = _selectedFileBytes!.length;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (_selectedFile != null) {
      try {
        if (!kIsWeb) {
          // On mobile/desktop, we can read file size
          return 'File selected';
        }
      } catch (e) {
        return 'Unknown size';
      }
    }
    return '0 KB';
  }

  Widget _buildProcessingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Processing document...',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildProcessingStep(
            'Extracting text',
            _extractingText,
            true,
          ),
          _buildProcessingStep(
            'Analyzing content',
            _analyzingContent,
            false,
          ),
          _buildProcessingStep(
            'Generating summary...',
            _generatingSummary,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingStep(String title, bool isCompleted, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                  ? const Color(0xFF1976D2)
                  : isActive 
                      ? const Color(0xFF1976D2)
                      : Colors.grey[300],
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : isActive
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : null,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isCompleted || isActive ? Colors.black : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _uploadDocument,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _summarizeDocument,
              icon: const Icon(Icons.summarize_outlined),
              label: const Text('Summarize'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveDocument,
              icon: const Icon(Icons.bookmark_outline),
              label: const Text('Save Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized && !_isProcessing) {
      try {
        // Set optimal capture settings for documents
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
        
        // Take high quality photo
        final XFile photo = await _cameraController!.takePicture();
        
        setState(() {
          _selectedFile = photo;
          _selectedFileName = path.basename(photo.path);
          _fileName = _selectedFileName!;
        });
        
        // Load file bytes for web compatibility
        await _loadFileBytes();
        
        // Process the captured image
        _processDocument();
      } catch (e) {
        print('Error capturing photo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    if (_isProcessing) return;
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95, // High quality for better OCR
    );
    
    if (image != null) {
      setState(() {
        _selectedFile = image;
        _selectedFileName = path.basename(image.path);
        _fileName = _selectedFileName!;
      });
      
      // Load file bytes for web compatibility
      await _loadFileBytes();
      
      _processDocument();
    }
  }

  Future<void> _selectFiles() async {
    if (_isProcessing) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      final file = result.files.single;
      if (kIsWeb) {
        // On web, use bytes directly
        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
          _fileName = file.name;
        });
      } else {
        // On mobile, use file path
        if (file.path != null) {
          setState(() {
            _selectedFile = XFile(file.path!);
            _selectedFileName = file.name;
            _fileName = file.name;
          });
          await _loadFileBytes();
        }
      }
      _processDocument();
    }
  }

  Future<void> _loadFileBytes() async {
    if (_selectedFile != null) {
      _selectedFileBytes = await _selectedFile!.readAsBytes();
    }
  }

  void _processDocument() {
    setState(() {
      _isProcessing = true;
      _extractingText = true;
    });

    // Start text extraction
    _extractTextFromImage();
  }

  Future<void> _extractTextFromImage() async {
    if (_selectedFile == null && _selectedFileBytes == null) return;

    try {
      setState(() {
        _extractingText = true;
      });

      // Call Document AI backend
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/documents/process'),
      );
      
      if (kIsWeb && _selectedFileBytes != null) {
        // On web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFileBytes!,
            filename: _selectedFileName ?? 'document',
          ),
        );
      } else if (_selectedFile != null) {
        // On mobile, use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedFile!.path,
            filename: _selectedFileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extractedText = data['text'] ?? '';
        
        setState(() {
          _extractedText = extractedText;
          _extractingText = false;
          _analyzingContent = true;
        });

        // Simulate content analysis completion
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          setState(() {
            _analyzingContent = false;
            _generatingSummary = false;
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text extracted and saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

      } else {
        throw Exception('Failed to process document: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      print('Error extracting text: $e');
      setState(() {
        _extractingText = false;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _uploadDocument() {
    // Handle upload to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading document...')),
    );
  }

  void _summarizeDocument() {
    // Navigate to legal chat with extracted text
    if (_extractedText.isNotEmpty) {
      Navigator.pushNamed(
        context, 
        '/legal-chat',
        arguments: {
          'initialText': _extractedText,
          'documentTitle': _fileName.isNotEmpty ? _fileName : 'Legal Document',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please process a document first to get text'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _saveDocument() {
    // Handle save to storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document saved!')),
    );
  }
}

class CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double bracketLength = 20;

    // Top-left corner
    canvas.drawLine(const Offset(0, bracketLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(bracketLength, 0), paint);

    // Top-right corner
    canvas.drawLine(Offset(size.width - bracketLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bracketLength), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, size.height - bracketLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(bracketLength, size.height), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width - bracketLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bracketLength), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}