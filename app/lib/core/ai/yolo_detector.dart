import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import 'priority_engine.dart';

/// Result of running the detector on one photo.
class VisionResult {
  /// Create a result.
  const VisionResult({
    required this.detections,
    required this.width,
    required this.height,
    required this.inferenceMillis,
  });

  /// Objects found, already non-max suppressed.
  final List<Detection> detections;

  /// Source image width.
  final int width;

  /// Source image height.
  final int height;

  /// How long inference took, shown in diagnostics.
  final int inferenceMillis;
}

/// YOLOv8n on ONNX Runtime, running on the CPU.
///
/// The model is bundled (12 MB) so the first scan works without a download and
/// without a network. Input is 640x640, letterboxed, and the output is the
/// standard `[1, 84, 8400]` tensor: four box values and eighty class scores.
class YoloDetector {
  YoloDetector({this.inputSize = 640});

  /// Square model input.
  final int inputSize;

  OrtSession? _session;
  OrtSessionOptions? _options;
  bool _loading = false;
  String? _error;

  /// True once the model is ready.
  bool get isReady => _session != null;

  /// Why loading failed, if it did.
  String? get error => _error;

  /// Load the bundled model. Safe to call repeatedly.
  Future<void> load() async {
    if (_session != null || _loading) return;
    _loading = true;
    try {
      OrtEnv.instance.init();
      final data = await rootBundle.load('assets/models/yolov8n.onnx');
      final options = OrtSessionOptions()
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
      _options = options;
      _session = OrtSession.fromBuffer(data.buffer.asUint8List(), options);
      _error = null;
    } catch (error) {
      _error = error.toString();
      _session = null;
    } finally {
      _loading = false;
    }
  }

  /// Run detection on encoded image bytes.
  ///
  /// Throws [StateError] when the model has not loaded, so the caller can show
  /// an honest "vision model unavailable" state instead of an empty result.
  Future<VisionResult> detect(Uint8List bytes) async {
    final session = _session;
    if (session == null) {
      throw StateError(_error ?? 'Vision model is not loaded');
    }

    final stopwatch = Stopwatch()..start();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('The captured frame could not be decoded');
    }

    final scale = math.min(
      inputSize / decoded.width,
      inputSize / decoded.height,
    );
    final resizedWidth = math.max(1, (decoded.width * scale).round());
    final resizedHeight = math.max(1, (decoded.height * scale).round());
    final padX = (inputSize - resizedWidth) / 2;
    final padY = (inputSize - resizedHeight) / 2;

    final resized = img.copyResize(
      decoded,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.linear,
    );
    final canvas = img.Image(width: inputSize, height: inputSize, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(
      canvas,
      resized,
      dstX: padX.round(),
      dstY: padY.round(),
    );

    final rgb = canvas.getBytes(order: img.ChannelOrder.rgb);
    final pixels = inputSize * inputSize;
    final input = Float32List(3 * pixels);
    for (var i = 0; i < pixels; i++) {
      input[i] = rgb[i * 3] / 255.0;
      input[pixels + i] = rgb[i * 3 + 1] / 255.0;
      input[2 * pixels + i] = rgb[i * 3 + 2] / 255.0;
    }

    final tensor = OrtValueTensor.createTensorWithDataList(
      input,
      <int>[1, 3, inputSize, inputSize],
    );
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;
    try {
      outputs = session.run(runOptions, <String, OrtValue>{
        session.inputNames.first: tensor,
      });
      final raw = outputs.first?.value;
      if (raw is! List) {
        throw StateError('Vision model returned no tensor');
      }
      final batch = raw.first as List;
      final channels = batch.length;
      final anchors = (batch.first as List).length;
      final flat = List<double>.filled(channels * anchors, 0);
      for (var c = 0; c < channels; c++) {
        final row = batch[c] as List;
        for (var a = 0; a < anchors; a++) {
          flat[c * anchors + a] = (row[a] as num).toDouble();
        }
      }

      final detections = PriorityEngine.decodeYolo(
        output: flat,
        anchors: anchors,
        classes: channels - 4,
        confidenceThreshold: 0.35,
        iouThreshold: 0.45,
        imageWidth: decoded.width,
        imageHeight: decoded.height,
        scale: scale,
        padX: padX,
        padY: padY,
      );

      return VisionResult(
        detections: detections,
        width: decoded.width,
        height: decoded.height,
        inferenceMillis: stopwatch.elapsedMilliseconds,
      );
    } finally {
      tensor.release();
      runOptions.release();
      if (outputs != null) {
        for (final output in outputs) {
          output?.release();
        }
      }
    }
  }

  /// Release the native session.
  void dispose() {
    _session?.release();
    _session = null;
    _options?.release();
    _options = null;
  }
}
