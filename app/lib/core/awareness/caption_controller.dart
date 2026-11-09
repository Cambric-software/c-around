import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/speech_recognizer.dart';
import '../data/ca_database.dart';
import 'microphone_source.dart';

/// Turns live speech into on-screen captions, fully offline.
///
/// Audio is buffered for a few seconds, transcribed by Whisper through
/// sherpa-onnx, and stored locally. Nothing is uploaded and no transcript is
/// kept after the user clears history.
class CaptionController extends ChangeNotifier {
  CaptionController({
    required this.recognizer,
    required this.microphone,
    required this.database,
    this.chunk = const Duration(seconds: 4),
  });

  /// Offline Whisper recogniser.
  final SpeechRecognizer recognizer;

  /// Shared microphone.
  final MicrophoneSource microphone;

  /// Local caption history.
  final CaDatabase database;

  /// How much audio is transcribed at a time.
  final Duration chunk;

  StreamSubscription<Uint8List>? _subscription;
  Timer? _timer;
  final List<int> _pcm = <int>[];
  final List<CaptionLine> _lines = <CaptionLine>[];
  bool _running = false;
  bool _transcribing = false;
  String? _error;

  /// Newest first, capped at 100 lines.
  List<CaptionLine> get lines => List<CaptionLine>.unmodifiable(_lines);

  /// True while listening.
  bool get isRunning => _running;

  /// True while a chunk is being transcribed.
  bool get isTranscribing => _transcribing;

  /// Why captioning is unavailable.
  String? get error => _error;

  /// True when the optional Whisper pack is installed.
  bool get isInstalled => recognizer.isInstalled;

  /// True when the recogniser is loaded.
  bool get isReady => recognizer.isReady;

  /// Load history from the database.
  Future<void> loadHistory() async {
    try {
      final stored = await database.captions(limit: 100);
      _lines
        ..clear()
        ..addAll(stored);
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  /// Start listening and captioning.
  Future<bool> start() async {
    if (_running) return true;
    if (!isInstalled) {
      _error = 'Install the Offline captions pack in Settings first.';
      notifyListeners();
      return false;
    }

    await recognizer.load();
    if (!recognizer.isReady) {
      _error = recognizer.error ?? 'The caption model could not be loaded.';
      notifyListeners();
      return false;
    }

    final acquired = await microphone.acquire();
    if (!acquired) {
      _error = microphone.error ?? 'The microphone is not available.';
      notifyListeners();
      return false;
    }

    _pcm.clear();
    _running = true;
    _error = null;
    _subscription = microphone.chunks.listen(
      (Uint8List data) {
        _pcm.addAll(data);
        const maxBytes = SpeechRecognizer.sampleRate * 2 * 8;
        if (_pcm.length > maxBytes) {
          _pcm.removeRange(0, _pcm.length - maxBytes);
        }
      },
      onError: (Object error) {
        _error = error.toString();
        notifyListeners();
      },
      cancelOnError: false,
    );
    _timer?.cancel();
    _timer = Timer.periodic(chunk, (_) => unawaited(_transcribeChunk()));
    notifyListeners();
    return true;
  }

  /// Stop listening.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _subscription?.cancel();
    _subscription = null;
    if (_running) {
      _running = false;
      await microphone.release();
    }
    _pcm.clear();
    notifyListeners();
  }

  /// Toggle listening.
  Future<bool> toggle() async {
    if (_running) {
      await stop();
      return false;
    }
    return start();
  }

  Future<void> _transcribeChunk() async {
    if (!_running || _transcribing) return;
    if (_pcm.length < SpeechRecognizer.sampleRate) return;

    final bytes = Uint8List.fromList(_pcm);
    _pcm.clear();
    _transcribing = true;
    notifyListeners();
    try {
      final samples = SpeechRecognizer.pcm16ToFloat(bytes);
      final text = await recognizer.transcribe(samples);
      final cleaned = text.trim();
      if (cleaned.isNotEmpty && cleaned != '[BLANK_AUDIO]') {
        final line = CaptionLine(text: cleaned, createdAt: DateTime.now());
        await database.insertCaption(cleaned);
        _lines.insert(0, line);
        if (_lines.length > 100) {
          _lines.removeRange(100, _lines.length);
        }
      }
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _transcribing = false;
      notifyListeners();
    }
  }

  /// Remove caption history from memory and disk.
  Future<void> clear() async {
    _lines.clear();
    _pcm.clear();
    await database.clearCaptions();
    notifyListeners();
  }
}
