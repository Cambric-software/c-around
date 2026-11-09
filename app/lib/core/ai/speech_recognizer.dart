import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'model_manager.dart';

/// Offline speech-to-text through sherpa-onnx Whisper.
///
/// The model is the multilingual Whisper tiny export (99 MB, optional pack).
/// Audio is recorded as 16 kHz mono PCM by `record`, converted to float
/// samples here, and decoded in one pass. Nothing is streamed to a server.
class SpeechRecognizer {
  SpeechRecognizer(this._models);

  final ModelManager _models;

  sherpa.OfflineRecognizer? _recognizer;
  bool _loading = false;
  String? _error;

  /// True when the recognizer is ready.
  bool get isReady => _recognizer != null;

  /// Why loading failed, if it did.
  String? get error => _error;

  /// True when the model pack is installed.
  bool get isInstalled => _models.isReady('whisper');

  /// Sample rate the model expects.
  static const int sampleRate = 16000;

  /// Load the model. Safe to call repeatedly.
  Future<void> load() async {
    if (_recognizer != null || _loading) return;
    if (!isInstalled) {
      _error = 'Install the Offline captions pack in Settings first.';
      return;
    }
    _loading = true;
    try {
      sherpa.initBindings();

      final encoder = _models.pathFor('whisper', 'tiny-encoder.int8.onnx');
      final decoder = _models.pathFor('whisper', 'tiny-decoder.int8.onnx');
      final tokens = _models.pathFor('whisper', 'tiny-tokens.txt');
      for (final path in <String>[encoder, decoder, tokens]) {
        if (!File(path).existsSync()) {
          throw StateError('Missing caption model file: $path');
        }
      }

      _recognizer = sherpa.OfflineRecognizer(
        sherpa.OfflineRecognizerConfig(
          model: sherpa.OfflineModelConfig(
            whisper: sherpa.OfflineWhisperModelConfig(
              encoder: encoder,
              decoder: decoder,
              language: 'en',
              task: 'transcribe',
            ),
            tokens: tokens,
            modelType: 'whisper',
            numThreads: math.max(2, Platform.numberOfProcessors - 2),
            debug: false,
            provider: 'cpu',
          ),
        ),
      );
      _error = null;
    } catch (error) {
      _error = error.toString();
      _recognizer = null;
    } finally {
      _loading = false;
    }
  }

  /// Transcribe mono float samples in -1..1.
  ///
  /// Returns an empty string when nothing intelligible was said, which is the
  /// normal result for a room with no speech rather than an error.
  Future<String> transcribe(Float32List samples) async {
    final recognizer = _recognizer;
    if (recognizer == null) {
      throw StateError(_error ?? 'The caption model is not loaded');
    }
    if (samples.isEmpty) return '';

    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
      recognizer.decode(stream);
      final text = recognizer.getResult(stream).text.trim();
      return text;
    } finally {
      stream.free();
    }
  }

  /// Convert little-endian 16-bit PCM bytes to float samples.
  static Float32List pcm16ToFloat(Uint8List bytes) {
    final count = bytes.lengthInBytes ~/ 2;
    final view = ByteData.sublistView(bytes, 0, count * 2);
    final out = Float32List(count);
    for (var i = 0; i < count; i++) {
      out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  /// Release the native recognizer.
  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}
