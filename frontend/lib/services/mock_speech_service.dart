import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Mock speech service for testing and fallback functionality
class MockSpeechService {
  static final MockSpeechService _instance = MockSpeechService._internal();
  factory MockSpeechService() => _instance;
  MockSpeechService._internal();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';

  // Mock phrases for testing
  final List<String> _mockPhrases = [
    'What is negligence?',
    'Contract law definition',
    'Legal precedent explained',
    'Constitutional rights',
    'Intellectual property law',
    'Employment law basics',
    'Criminal law overview',
    'Civil procedure rules',
    'Evidence law principles',
    'Family law matters',
  ];

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;

  /// Initialize mock speech services
  Future<bool> initialize() async {
    debugPrint('Mock Speech Service initialized');
    return true;
  }

  /// Mock listening for speech input
  Future<String?> startListening({
    String? localeId,
    Duration? timeout,
  }) async {
    if (_isListening) return null;

    _isListening = true;
    debugPrint('Mock: Starting to listen...');

    // Simulate listening delay
    await Future.delayed(const Duration(seconds: 2));

    if (_isListening) {
      // Generate a random mock result
      final random = Random();
      _lastWords = _mockPhrases[random.nextInt(_mockPhrases.length)];
      
      debugPrint('Mock: Speech result: $_lastWords');
      _isListening = false;
      return _lastWords;
    }

    return null;
  }

  /// Stop mock listening
  Future<void> stopListening() async {
    _isListening = false;
    debugPrint('Mock: Stopped listening');
  }

  /// Mock speak functionality
  Future<void> speak(String text, {String? language}) async {
    if (text.isEmpty) return;

    _isSpeaking = true;
    debugPrint('Mock: Speaking: $text');

    // Simulate speaking duration based on text length
    final duration = Duration(milliseconds: text.length * 50);
    await Future.delayed(duration);

    _isSpeaking = false;
    debugPrint('Mock: Finished speaking');
  }

  /// Stop mock speaking
  Future<void> stop() async {
    _isSpeaking = false;
    debugPrint('Mock: Stopped speaking');
  }

  /// Check mock availability
  Future<bool> isAvailable() async {
    return true;
  }

  /// Dispose mock resources
  void dispose() {
    _isListening = false;
    _isSpeaking = false;
    debugPrint('Mock: Speech service disposed');
  }
}

/// Mock Voice Input Widget
class MockVoiceInputWidget extends StatefulWidget {
  final Function(String) onSpeechResult;
  final String? hintText;
  final Color? activeColor;
  final Color? inactiveColor;

  const MockVoiceInputWidget({
    super.key,
    required this.onSpeechResult,
    this.hintText,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<MockVoiceInputWidget> createState() => _MockVoiceInputWidgetState();
}

class _MockVoiceInputWidgetState extends State<MockVoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final MockSpeechService _speechService = MockSpeechService();
  late AnimationController _animationController;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });
    
    _animationController.repeat();
    
    try {
      final result = await _speechService.startListening();
      if (result != null && result.isNotEmpty) {
        widget.onSpeechResult(result);
      }
    } catch (e) {
      debugPrint('Mock voice input error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mock voice input: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      _animationController.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isListening ? null : _startListening,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isListening
              ? (widget.activeColor ?? Colors.blue.withValues(alpha: 0.1))
              : (widget.inactiveColor ?? Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _isListening
                ? (widget.activeColor ?? Colors.blue)
                : (widget.inactiveColor ?? Colors.grey),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _animationController,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening
                    ? (widget.activeColor ?? Colors.blue)
                    : (widget.inactiveColor ?? Colors.grey),
                size: 24,
              ),
            ),
            if (_isListening) ...[
              const SizedBox(width: 8),
              Text(
                'Listening...',
                style: TextStyle(
                  color: widget.activeColor ?? Colors.blue,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mock Voice Input Button for simple integration
class MockVoiceInputButton extends StatefulWidget {
  final Function(String) onSpeechResult;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const MockVoiceInputButton({
    super.key,
    required this.onSpeechResult,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
  });

  @override
  State<MockVoiceInputButton> createState() => _MockVoiceInputButtonState();
}

class _MockVoiceInputButtonState extends State<MockVoiceInputButton> {
  final MockSpeechService _speechService = MockSpeechService();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });
      
      try {
        final result = await _speechService.startListening();
        if (result != null && result.isNotEmpty) {
          widget.onSpeechResult(result);
        }
      } catch (e) {
        debugPrint('Mock voice input error: $e');
      } finally {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_outlined,
        color: _isListening 
            ? (widget.activeColor ?? Colors.blue)
            : (widget.inactiveColor ?? Colors.grey),
        size: widget.size,
      ),
      onPressed: _toggleListening,
      tooltip: _isListening ? 'Stop Listening' : 'Start Voice Input (Mock)',
    );
  }
}