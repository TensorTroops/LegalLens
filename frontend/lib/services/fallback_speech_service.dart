import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'mock_speech_service.dart';

/// Fallback speech service that uses real speech when available, mock when not
class FallbackSpeechService {
  static final FallbackSpeechService _instance = FallbackSpeechService._internal();
  factory FallbackSpeechService() => _instance;
  FallbackSpeechService._internal();

  final SpeechService _realSpeechService = SpeechService();
  final MockSpeechService _mockSpeechService = MockSpeechService();
  
  bool _useRealSpeech = true;
  bool _isInitialized = false;

  // Getters
  bool get isListening => _useRealSpeech 
      ? _realSpeechService.isListening 
      : _mockSpeechService.isListening;
      
  bool get isSpeaking => _useRealSpeech 
      ? _realSpeechService.isSpeaking 
      : _mockSpeechService.isSpeaking;
      
  String get lastWords => _useRealSpeech 
      ? _realSpeechService.lastWords 
      : _mockSpeechService.lastWords;

  bool get isUsingRealSpeech => _useRealSpeech;

  /// Initialize speech services with fallback
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Try to initialize real speech service
      debugPrint('Attempting to initialize real speech service...');
      _useRealSpeech = await _realSpeechService.initialize();
      
      if (_useRealSpeech) {
        debugPrint('Real speech service initialized successfully');
      } else {
        debugPrint('Real speech service failed, falling back to mock service');
        _useRealSpeech = false;
        await _mockSpeechService.initialize();
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Speech service initialization error: $e, using mock service');
      _useRealSpeech = false;
      await _mockSpeechService.initialize();
      _isInitialized = true;
      return true;
    }
  }

  /// Start listening with fallback
  Future<String?> startListening({
    String? localeId,
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_useRealSpeech) {
        // For real speech service, we need to use a different approach since it returns void
        // and uses callbacks. For now, return null and let the callback handle the result.
        await _realSpeechService.startListening(
          localeId: localeId,
          timeout: timeout,
        );
        return null; // Real speech service uses callbacks, not direct returns
      } else {
        return await _mockSpeechService.startListening(
          localeId: localeId,
          timeout: timeout,
        );
      }
    } catch (e) {
      debugPrint('Speech listening error: $e');
      if (_useRealSpeech) {
        // Fallback to mock service on error
        debugPrint('Falling back to mock service due to error');
        _useRealSpeech = false;
        return await _mockSpeechService.startListening(
          localeId: localeId,
          timeout: timeout,
        );
      }
      return null;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_useRealSpeech) {
        await _realSpeechService.stopListening();
      } else {
        await _mockSpeechService.stopListening();
      }
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
  }

  /// Speak with fallback
  Future<void> speak(String text, {String? language}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_useRealSpeech) {
        await _realSpeechService.speak(text, language: language);
      } else {
        await _mockSpeechService.speak(text, language: language);
      }
    } catch (e) {
      debugPrint('Speech speak error: $e');
      if (_useRealSpeech) {
        // Fallback to mock service on error
        debugPrint('Falling back to mock service for TTS');
        await _mockSpeechService.speak(text, language: language);
      }
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      if (_useRealSpeech) {
        await _realSpeechService.stop();
      } else {
        await _mockSpeechService.stop();
      }
    } catch (e) {
      debugPrint('Stop speaking error: $e');
    }
  }

  /// Check availability
  Future<bool> isAvailable() async {
    if (_useRealSpeech) {
      try {
        return await _realSpeechService.isAvailable();
      } catch (e) {
        debugPrint('Real speech availability check failed: $e');
        _useRealSpeech = false;
        return await _mockSpeechService.isAvailable();
      }
    } else {
      return await _mockSpeechService.isAvailable();
    }
  }

  /// Force switch to mock service
  void switchToMockService() {
    _useRealSpeech = false;
    debugPrint('Manually switched to mock speech service');
  }

  /// Try to switch back to real service
  Future<bool> tryRealService() async {
    try {
      final available = await _realSpeechService.initialize();
      if (available) {
        _useRealSpeech = true;
        debugPrint('Successfully switched back to real speech service');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to switch to real service: $e');
    }
    return false;
  }

  /// Dispose resources
  void dispose() {
    try {
      _realSpeechService.dispose();
      _mockSpeechService.dispose();
    } catch (e) {
      debugPrint('Dispose error: $e');
    }
  }
}

/// Adaptive Voice Input Widget that uses fallback service
class AdaptiveVoiceInputWidget extends StatefulWidget {
  final Function(String) onSpeechResult;
  final String? hintText;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showServiceIndicator;

  const AdaptiveVoiceInputWidget({
    super.key,
    required this.onSpeechResult,
    this.hintText,
    this.activeColor,
    this.inactiveColor,
    this.showServiceIndicator = true,
  });

  @override
  State<AdaptiveVoiceInputWidget> createState() => _AdaptiveVoiceInputWidgetState();
}

class _AdaptiveVoiceInputWidgetState extends State<AdaptiveVoiceInputWidget> {
  final FallbackSpeechService _speechService = FallbackSpeechService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });
    
    try {
      final result = await _speechService.startListening();
      if (result != null && result.isNotEmpty) {
        widget.onSpeechResult(result);
      }
    } catch (e) {
      debugPrint('Adaptive voice input error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isListening ? null : _startListening,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isListening
                  ? (widget.activeColor ?? Colors.green.withValues(alpha: 0.1))
                  : (widget.inactiveColor ?? Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _isListening
                    ? (widget.activeColor ?? Colors.green)
                    : (widget.inactiveColor ?? Colors.grey),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening
                      ? (widget.activeColor ?? Colors.green)
                      : (widget.inactiveColor ?? Colors.grey),
                  size: 24,
                ),
                if (_isListening) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.showServiceIndicator) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _speechService.isUsingRealSpeech 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _speechService.isUsingRealSpeech 
                    ? Colors.green
                    : Colors.orange,
                width: 0.5,
              ),
            ),
            child: Text(
              _speechService.isUsingRealSpeech ? 'Real Speech' : 'Mock Speech',
              style: TextStyle(
                fontSize: 10,
                color: _speechService.isUsingRealSpeech 
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple Adaptive Voice Button
class AdaptiveVoiceInputButton extends StatefulWidget {
  final Function(String) onSpeechResult;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const AdaptiveVoiceInputButton({
    super.key,
    required this.onSpeechResult,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
  });

  @override
  State<AdaptiveVoiceInputButton> createState() => _AdaptiveVoiceInputButtonState();
}

class _AdaptiveVoiceInputButtonState extends State<AdaptiveVoiceInputButton> {
  final FallbackSpeechService _speechService = FallbackSpeechService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

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
        debugPrint('Adaptive voice input error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_outlined,
            color: _isListening 
                ? (widget.activeColor ?? Colors.green)
                : (widget.inactiveColor ?? Colors.grey),
            size: widget.size,
          ),
          onPressed: _toggleListening,
        ),
        if (!_speechService.isUsingRealSpeech)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}