import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  // Speech to Text
  stt.SpeechToText? _speechToText;
  bool _isListening = false;
  String _lastWords = '';
  bool _isInitialized = false;
  Function(String)? _onResultCallback;

  // Text to Speech
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;

  /// Initialize speech services
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Initialize Speech to Text
      _speechToText = stt.SpeechToText();
      final sttAvailable = await _speechToText!.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          // Don't automatically stop listening on status changes
          // Let the user control when to stop
        },
        onError: (error) {
          debugPrint('STT Error: $error');
          _isListening = false;
        },
      );

      // Initialize Text to Speech
      _flutterTts = FlutterTts();
      await _initializeTts();

      _isInitialized = sttAvailable;
      return sttAvailable;
    } catch (e) {
      debugPrint('Speech service initialization error: $e');
      return false;
    }
  }

  /// Initialize TTS settings
  Future<void> _initializeTts() async {
    if (_flutterTts == null) return;

    try {
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts!.setErrorHandler((message) {
        _isSpeaking = false;
        debugPrint('TTS Error: $message');
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  /// Start listening for speech input
  Future<void> startListening({
    String? localeId,
    Duration? timeout,
    Function(String)? onResult,
  }) async {
    if (_speechToText == null || !_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) {
      await stopListening();
    }

    _lastWords = '';
    _onResultCallback = onResult;
    _isListening = true;

    try {
      if (_speechToText == null) return;

      await _speechToText!.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          debugPrint('Speech result: $_lastWords');
          
          // Call the callback with the result
          if (_onResultCallback != null && _lastWords.isNotEmpty) {
            _onResultCallback!(_lastWords);
          }
        },
        localeId: localeId ?? 'en_US',
        listenFor: timeout ?? const Duration(minutes: 5), // Much longer timeout
        pauseFor: const Duration(seconds: 10), // Longer pause before stopping
        listenOptions: stt.SpeechListenOptions(
          partialResults: true, // Enable partial results for better UX
          cancelOnError: true,
        ),
      );

    } catch (e) {
      _isListening = false;
      debugPrint('Speech listening error: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_speechToText != null && _speechToText!.isListening) {
        await _speechToText!.stop();
      }
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
    _isListening = false;
  }

  /// Speak the given text
  Future<void> speak(String text, {String? language}) async {
    if (text.isEmpty || _flutterTts == null) return;

    try {
      // Stop any current speech
      if (_isSpeaking) {
        await stop();
      }

      // Set speaking state
      _isSpeaking = true;

      // Set language if provided
      if (language != null) {
        await _flutterTts!.setLanguage(language);
      }

      // Set speech rate and volume
      await _flutterTts!.setSpeechRate(0.5); // Slower rate for better comprehension
      await _flutterTts!.setVolume(0.8);
      await _flutterTts!.setPitch(1.0);

      debugPrint('TTS: Speaking text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      // Speak the text
      await _flutterTts!.speak(text);
      
      // Note: _isSpeaking will be set to false in completion handler
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
      rethrow; // Re-throw to let the caller handle the error
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      if (_flutterTts != null && _isSpeaking) {
        await _flutterTts!.stop();
      }
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
    _isSpeaking = false;
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    try {
      if (_speechToText == null) {
        return await initialize();
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('Is available error: $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    try {
      _speechToText?.cancel();
      _flutterTts?.stop();
    } catch (e) {
      debugPrint('Dispose error: $e');
    }
  }
}

/// Simple voice input button widget
class VoiceInputButton extends StatefulWidget {
  final Function(String) onSpeechResult;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const VoiceInputButton({
    super.key,
    required this.onSpeechResult,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final SpeechService _speechService = SpeechService();
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
        await _speechService.startListening(
          onResult: (result) {
            if (result.isNotEmpty) {
              widget.onSpeechResult(result);
            }
          },
        );
      } catch (e) {
        debugPrint('Voice input error: $e');
        setState(() {
          _isListening = false;
        });
      }
      // Note: Don't set _isListening to false here - user must click again to stop
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_outlined,
        color: _isListening 
            ? (widget.activeColor ?? Colors.red)
            : (widget.inactiveColor ?? Colors.grey),
        size: widget.size,
      ),
      onPressed: _toggleListening,
    );
  }
}

/// Simplified Voice Input Widget for compatibility
class VoiceInputWidget extends StatefulWidget {
  final Function(String) onSpeechResult;
  final String? hintText;
  final Color? activeColor;
  final Color? inactiveColor;

  const VoiceInputWidget({
    super.key,
    required this.onSpeechResult,
    this.hintText,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });
    
    try {
      await _speechService.startListening(
        onResult: (result) {
          if (result.isNotEmpty) {
            widget.onSpeechResult(result);
          }
        },
      );
    } catch (e) {
      debugPrint('Voice input error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice input failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isListening = false;
      });
    }
    // Note: Don't set _isListening to false here - user must tap again to stop
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isListening) {
          // Stop listening
          await _speechService.stopListening();
          setState(() {
            _isListening = false;
          });
        } else {
          // Start listening
          await _startListening();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isListening
              ? (widget.activeColor ?? Colors.red.withValues(alpha: 0.1))
              : (widget.inactiveColor ?? Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _isListening
                ? (widget.activeColor ?? Colors.red)
                : (widget.inactiveColor ?? Colors.grey),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening
                  ? (widget.activeColor ?? Colors.red)
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
    );
  }
}