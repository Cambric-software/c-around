import 'dart:typed_data';

import 'priority_engine.dart';

/// Result of running the detector on one photo.
class VisionResult {
  const VisionResult({
    required this.detections,
    required this.width,
    required this.height,
    required this.inferenceMillis,
  });

  final List<Detection> detections;
  final int width;
  final int height;
  final int inferenceMillis;
}

/// YOLOv8n object detector stub.
///
/// ONNX Runtime caused native library crash on Android (Xiaomi and others).
/// This stub keeps the app working while we migrate to TensorFlow Lite.
/// isReady returns false → awareness controller shows "not available" state.
class YoloDetector {
  YoloDetector({this.inputSize = 640});

  final int inputSize;

  bool get isReady => false;
  String? get error => 'Object detection unavailable — model engine update required.';

  Future<void> load() async {
    // No-op: onnxruntime removed to fix Android crash.
  }

  Future<VisionResult> detect(Uint8List bytes) async {
    return const VisionResult(
      detections: <Detection>[],
      width: 640,
      height: 640,
      inferenceMillis: 0,
    );
  }
}
