import 'dart:typed_data';

import 'model_manager.dart';

/// Offline speech-to-text stub.
///
/// sherpa_onnx caused native library crashes on Android.
/// Stubbed out until migrated to a TFLite-based recognizer.
class SpeechRecognizer {
  SpeechRecognizer(this._models);

  final ModelManager _models;

  bool get isReady => false;
  String? get error => 'Live captions unavailable — model engine update required.';
  bool get isInstalled => _models.isReady('whisper');

  static const int sampleRate = 16000;

  Future<void> load() async {}

  Future<String> transcribe(Float32List samples) async => '';

  static Float32List pcm16ToFloat(Uint8List pcm16) {
    final out = Float32List(pcm16.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final lo = pcm16[i * 2];
      final hi = pcm16[i * 2 + 1];
      var sample = (hi << 8) | lo;
      if (sample > 32767) sample -= 65536;
      out[i] = sample / 32768.0;
    }
    return out;
  }
}
