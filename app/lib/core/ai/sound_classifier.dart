import 'dart:typed_data';

import 'sound_events.dart';

/// One scored AudioSet class.
class SoundHit {
  const SoundHit({required this.name, required this.score, this.alert});

  final String name;
  final double score;
  final SoundAlert? alert;
}

/// YAMNet sound classifier stub.
///
/// ONNX Runtime caused native library crash on Android.
/// This stub keeps the app working while we migrate to TensorFlow Lite.
class YamnetClassifier {
  YamnetClassifier();

  bool get isReady => false;
  String? get error => 'Sound classification unavailable — model engine update required.';

  static const int windowSamples = 15600;
  static const int sampleRate = 16000;

  Future<void> load() async {
    // No-op: onnxruntime removed to fix Android crash.
  }

  Future<List<SoundHit>> classify(Float32List samples) async {
    return const <SoundHit>[];
  }
}
