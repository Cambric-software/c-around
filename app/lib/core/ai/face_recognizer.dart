import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

/// One face found in a photo.
class FaceBox {
  /// Create a face box.
  const FaceBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.score,
    required this.landmarks,
  });

  /// Left edge in source pixels.
  final double left;

  /// Top edge in source pixels.
  final double top;

  /// Box width in source pixels.
  final double width;

  /// Box height in source pixels.
  final double height;

  /// Detector confidence, 0..1.
  final double score;

  /// Five landmarks: two eyes, nose, two mouth corners, in source pixels.
  final List<Offset2> landmarks;
}

/// A plain x/y pair. Kept local so the recogniser does not depend on Flutter's
/// painting layer.
class Offset2 {
  /// Create a point.
  const Offset2(this.x, this.y);

  /// Horizontal position.
  final double x;

  /// Vertical position.
  final double y;
}

/// Result of matching one face against the enrolled people.
class FaceMatch {
  /// Create a match.
  const FaceMatch({
    required this.personId,
    required this.name,
    required this.similarity,
  });

  /// Database id of the person.
  final int personId;

  /// Display name.
  final String name;

  /// Cosine similarity, -1..1.
  final double similarity;
}

/// SCRFD face detection and MobileFaceNet embeddings, both on ONNX Runtime.
///
/// Both models are bundled (2.5 MB and 13.6 MB), so face enrolment and
/// recognition work with no download. They are the detector and recogniser
/// from InsightFace's buffalo_s package. Detection runs at 640x640; the
/// embedding model takes an aligned 112x112 crop and returns 512 values.
class FaceRecognizer {
  FaceRecognizer();

  OrtSession? _detector;
  OrtSession? _embedder;
  bool _loading = false;
  String? _error;

  /// True when faces can be found and embedded.
  bool get isReady => _detector != null && _embedder != null;

  /// Why loading failed, if it did.
  String? get error => _error;

  /// Detector score floor.
  static const double _scoreThreshold = 0.55;

  /// Overlap used to merge duplicate boxes.
  static const double _nmsThreshold = 0.3;

  /// Similarity needed before a face is called a person's name.
  ///
  /// Different people score below about 0.48 with this model and the same
  /// person across two photos scores above 0.9, so 0.58 leaves a wide margin
  /// on both sides. A false name is worse than no name.
  static const double matchThreshold = 0.58;

  /// Load both bundled models. Safe to call repeatedly.
  Future<void> load() async {
    if (_detector != null && _embedder != null) return;
    if (_loading) return;
    _loading = true;
    try {
      OrtEnv.instance.init();
      final options = OrtSessionOptions()
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

      final detectorData = await rootBundle.load('assets/models/det_500m.onnx');
      _detector = OrtSession.fromBuffer(
        detectorData.buffer.asUint8List(),
        options,
      );

      final embedderData = await rootBundle.load('assets/models/w600k_mbf.onnx');
      _embedder = OrtSession.fromBuffer(
        embedderData.buffer.asUint8List(),
        options,
      );
      _error = null;
    } catch (error) {
      _error = error.toString();
      _detector = null;
      _embedder = null;
    } finally {
      _loading = false;
    }
  }

  /// Find faces in an encoded image, largest first.
  Future<List<FaceBox>> detect(Uint8List encoded) async {
    final session = _detector;
    if (session == null) {
      throw StateError(_error ?? 'Face detection is not loaded');
    }
    final decoded = img.decodeImage(encoded);
    if (decoded == null) {
      throw const FormatException('The photo could not be decoded');
    }

    const inputSize = 640;
    final scale = math.min(inputSize / decoded.width, inputSize / decoded.height);
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
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
    img.compositeImage(canvas, resized, dstX: padX.round(), dstY: padY.round());

    final rgb = canvas.getBytes(order: img.ChannelOrder.rgb);
    const pixels = inputSize * inputSize;
    final input = Float32List(3 * pixels);
    for (var i = 0; i < pixels; i++) {
      input[i] = (rgb[i * 3] - 127.5) / 128.0;
      input[pixels + i] = (rgb[i * 3 + 1] - 127.5) / 128.0;
      input[2 * pixels + i] = (rgb[i * 3 + 2] - 127.5) / 128.0;
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

      // SCRFD emits scores, box distances and landmarks for strides 8, 16 and
      // 32, in that order, two anchors per grid cell.
      final candidates = <FaceBox>[];
      for (var i = 0; i < 3; i++) {
        final stride = <int>[8, 16, 32][i];
        final scores = _flatten(outputs[i]?.value);
        final boxes = _flatten(outputs[i + 3]?.value);
        final kps = _flatten(outputs[i + 6]?.value);
        final grid = inputSize ~/ stride;
        final anchors = grid * grid * 2;

        for (var a = 0; a < anchors; a++) {
          final score = scores[a];
          if (score < _scoreThreshold) continue;

          final cell = a ~/ 2;
          final cx = (cell % grid) * stride.toDouble();
          final cy = (cell ~/ grid) * stride.toDouble();

          final x1 = cx - boxes[a * 4] * stride;
          final y1 = cy - boxes[a * 4 + 1] * stride;
          final x2 = cx + boxes[a * 4 + 2] * stride;
          final y2 = cy + boxes[a * 4 + 3] * stride;

          double unpadX(double value) => (value - padX) / scale;
          double unpadY(double value) => (value - padY) / scale;

          candidates.add(
            FaceBox(
              left: unpadX(x1).clamp(0, decoded.width.toDouble()),
              top: unpadY(y1).clamp(0, decoded.height.toDouble()),
              width: (unpadX(x2) - unpadX(x1)).clamp(
                0,
                decoded.width.toDouble(),
              ),
              height: (unpadY(y2) - unpadY(y1)).clamp(
                0,
                decoded.height.toDouble(),
              ),
              score: score,
              landmarks: <Offset2>[
                for (var k = 0; k < 5; k++)
                  Offset2(
                    unpadX(cx + kps[a * 10 + k * 2] * stride),
                    unpadY(cy + kps[a * 10 + k * 2 + 1] * stride),
                  ),
              ],
            ),
          );
        }
      }

      final kept = _nms(candidates)
        ..sort(
          (FaceBox a, FaceBox b) =>
              (b.width * b.height).compareTo(a.width * a.height),
        );
      return kept;
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

  /// Turn a detected face into a 512-value embedding.
  Future<Float32List> embed(Uint8List encoded, FaceBox face) async {
    final session = _embedder;
    if (session == null) {
      throw StateError(_error ?? 'Face embedding is not loaded');
    }
    final decoded = img.decodeImage(encoded);
    if (decoded == null) {
      throw const FormatException('The photo could not be decoded');
    }

    final aligned = _align(decoded, face.landmarks);
    const pixels = 112 * 112;
    final input = Float32List(3 * pixels);
    for (var i = 0; i < pixels; i++) {
      input[i] = (aligned[i * 3] - 127.5) / 127.5;
      input[pixels + i] = (aligned[i * 3 + 1] - 127.5) / 127.5;
      input[2 * pixels + i] = (aligned[i * 3 + 2] - 127.5) / 127.5;
    }

    final tensor = OrtValueTensor.createTensorWithDataList(
      input,
      <int>[1, 3, 112, 112],
    );
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;
    try {
      outputs = session.run(runOptions, <String, OrtValue>{
        session.inputNames.first: tensor,
      });
      final values = _flatten(outputs.first?.value);
      final vector = Float32List(values.length);
      var norm = 0.0;
      for (var i = 0; i < values.length; i++) {
        vector[i] = values[i];
        norm += values[i] * values[i];
      }
      norm = math.sqrt(norm);
      if (norm > 0) {
        for (var i = 0; i < vector.length; i++) {
          vector[i] /= norm;
        }
      }
      return vector;
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

  /// Cosine similarity between two vectors.
  ///
  /// The embedder already returns L2-normalised vectors, but normalising here
  /// as well keeps the matcher correct for any caller and makes the threshold
  /// independent of vector length.
  static double similarity(Float32List a, Float32List b) {
    if (a.length != b.length) return -1;
    if (a.isEmpty) return 0;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA <= 0 || normB <= 0) return 0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Best enrolled person for a face, or null when nobody is close enough.
  static FaceMatch? bestMatch({
    required Float32List face,
    required Map<int, ({String name, Float32List vector})> people,
  }) {
    FaceMatch? best;
    for (final entry in people.entries) {
      final score = similarity(face, entry.value.vector);
      if (score >= matchThreshold &&
          (best == null || score > best.similarity)) {
        best = FaceMatch(
          personId: entry.key,
          name: entry.value.name,
          similarity: score,
        );
      }
    }
    return best;
  }

  /// Release both native sessions.
  void dispose() {
    _detector?.release();
    _detector = null;
    _embedder?.release();
    _embedder = null;
  }

  static List<FaceBox> _nms(List<FaceBox> input) {
    final sorted = List<FaceBox>.from(input)
      ..sort((FaceBox a, FaceBox b) => b.score.compareTo(a.score));
    final kept = <FaceBox>[];
    for (final candidate in sorted) {
      var overlaps = false;
      for (final existing in kept) {
        if (_iou(existing, candidate) > _nmsThreshold) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) kept.add(candidate);
    }
    return kept;
  }

  static double _iou(FaceBox a, FaceBox b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.left + a.width, b.left + b.width);
    final bottom = math.min(a.top + a.height, b.top + b.height);
    final intersection =
        math.max(0.0, right - left) * math.max(0.0, bottom - top);
    final union = a.width * a.height + b.width * b.height - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }

  /// Flatten the nested lists ONNX Runtime returns into one row.
  static List<double> _flatten(Object? value) {
    final out = <double>[];
    void walk(Object? node) {
      if (node == null) return;
      if (node is num) {
        out.add(node.toDouble());
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(value);
    return out;
  }

  /// ArcFace's standard 112x112 landmark template, in viewer order.
  static const List<Offset2> _template = <Offset2>[
    Offset2(38.2946, 51.6963),
    Offset2(73.5318, 51.5014),
    Offset2(56.0252, 71.7366),
    Offset2(41.5493, 92.3655),
    Offset2(70.7299, 92.2041),
  ];

  /// Similarity-transform the face so the landmarks land on the template,
  /// then sample it into a 112x112 RGB buffer.
  ///
  /// Least-squares similarity transform in complex form: one scale-rotation
  /// and one translation. Reflection is not allowed, because a mirrored face
  /// is not the same face.
  static Uint8List _align(img.Image source, List<Offset2> landmarks) {
    if (landmarks.length < 5) {
      return _resizeCrop(source, landmarks);
    }

    var srcMeanX = 0.0;
    var srcMeanY = 0.0;
    var dstMeanX = 0.0;
    var dstMeanY = 0.0;
    for (var i = 0; i < 5; i++) {
      srcMeanX += landmarks[i].x;
      srcMeanY += landmarks[i].y;
      dstMeanX += _template[i].x;
      dstMeanY += _template[i].y;
    }
    srcMeanX /= 5;
    srcMeanY /= 5;
    dstMeanX /= 5;
    dstMeanY /= 5;

    var numeratorRe = 0.0;
    var numeratorIm = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < 5; i++) {
      final sx = landmarks[i].x - srcMeanX;
      final sy = landmarks[i].y - srcMeanY;
      final dx = _template[i].x - dstMeanX;
      final dy = _template[i].y - dstMeanY;
      numeratorRe += dx * sx + dy * sy;
      numeratorIm += dy * sx - dx * sy;
      denominator += sx * sx + sy * sy;
    }

    if (denominator <= 1e-9) {
      return _resizeCrop(source, landmarks);
    }

    final aRe = numeratorRe / denominator;
    final aIm = numeratorIm / denominator;
    final bRe = dstMeanX - (aRe * srcMeanX - aIm * srcMeanY);
    final bIm = dstMeanY - (aIm * srcMeanX + aRe * srcMeanY);

    final det = aRe * aRe + aIm * aIm;
    if (det <= 1e-9) {
      return _resizeCrop(source, landmarks);
    }
    final invRe = aRe / det;
    final invIm = -aIm / det;

    final out = Uint8List(112 * 112 * 3);
    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        final px = x + 0.5 - bRe;
        final py = y + 0.5 - bIm;
        final sx = invRe * px - invIm * py;
        final sy = invIm * px + invRe * py;
        _sample(source, sx, sy, out, (y * 112 + x) * 3);
      }
    }
    return out;
  }

  /// Bilinear sample with edge clamping.
  static void _sample(
    img.Image source,
    double x,
    double y,
    Uint8List out,
    int offset,
  ) {
    final maxX = source.width - 1;
    final maxY = source.height - 1;
    final x0 = x.floor().clamp(0, maxX);
    final y0 = y.floor().clamp(0, maxY);
    final x1 = (x0 + 1).clamp(0, maxX);
    final y1 = (y0 + 1).clamp(0, maxY);
    final fx = (x - x.floor()).clamp(0.0, 1.0);
    final fy = (y - y.floor()).clamp(0.0, 1.0);

    final p00 = source.getPixel(x0, y0);
    final p10 = source.getPixel(x1, y0);
    final p01 = source.getPixel(x0, y1);
    final p11 = source.getPixel(x1, y1);

    double mix(num a, num b, num c, num d) =>
        a * (1 - fx) * (1 - fy) +
        b * fx * (1 - fy) +
        c * (1 - fx) * fy +
        d * fx * fy;

    out[offset] = mix(p00.r, p10.r, p01.r, p11.r).round().clamp(0, 255);
    out[offset + 1] = mix(p00.g, p10.g, p01.g, p11.g).round().clamp(0, 255);
    out[offset + 2] = mix(p00.b, p10.b, p01.b, p11.b).round().clamp(0, 255);
  }

  /// Fallback when landmarks are unusable: square crop around the face.
  static Uint8List _resizeCrop(img.Image source, List<Offset2> landmarks) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = 0.0;
    var maxY = 0.0;
    for (final point in landmarks) {
      minX = math.min(minX, point.x);
      minY = math.min(minY, point.y);
      maxX = math.max(maxX, point.x);
      maxY = math.max(maxY, point.y);
    }
    if (!minX.isFinite || !minY.isFinite) {
      minX = 0;
      minY = 0;
      maxX = source.width.toDouble();
      maxY = source.height.toDouble();
    }
    final size = math.max(maxX - minX, maxY - minY) * 2.4;
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    final out = Uint8List(112 * 112 * 3);
    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        final sx = cx + (x / 112 - 0.5) * size;
        final sy = cy + (y / 112 - 0.5) * size;
        _sample(source, sx, sy, out, (y * 112 + x) * 3);
      }
    }
    return out;
  }
}
