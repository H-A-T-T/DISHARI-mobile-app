import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech (TTS) Voice Service for Jonobondhu AI
/// Speaks responses out loud in Bengali and English.
class TtsService with ChangeNotifier {
  static final TtsService instance = TtsService._internal();

  TtsService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String? _currentSpeakingId;
  bool _isPlaying = false;
  bool _soundEnabled = true;

  String? get currentSpeakingId => _currentSpeakingId;
  bool get isPlaying => _isPlaying;
  bool get soundEnabled => _soundEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    if (!_soundEnabled) {
      stop();
    }
    notifyListeners();
  }

  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _currentSpeakingId = null;
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        _currentSpeakingId = null;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        _currentSpeakingId = null;
        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> speak({
    required String text,
    required String msgId,
    required bool isBn,
  }) async {
    if (!_soundEnabled) return;

    if (_isPlaying && _currentSpeakingId == msgId) {
      await stop();
      return;
    }

    await stop();
    await _initTts();

    // Strip [ACTION:...] and markdown formatting from speech text
    final cleanText = text
        .replaceAll(RegExp(r'\[ACTION:[^\]]+\]'), '')
        .replaceAll(RegExp(r'[*_#`~]'), '')
        .trim();

    if (cleanText.isEmpty) return;

    try {
      final lang = isBn ? 'bn-BD' : 'en-US';
      await _flutterTts.setLanguage(lang);
      _currentSpeakingId = msgId;
      _isPlaying = true;
      notifyListeners();

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isPlaying = false;
      _currentSpeakingId = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isPlaying = false;
    _currentSpeakingId = null;
    notifyListeners();
  }
}
