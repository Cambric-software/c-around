import 'dart:math' as math;
import 'dart:typed_data';

/// One face found in a photo.
class FaceBox {
  const FaceBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.score,
    required this.landmarks,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double score;
  final List<Offset2> landmarks;
}

/// Plain x/y pair.
class Offset2 {
  const Offset2(this.x, this.y);
  final double x;
  final double y;
}

/// Result of matching one face against enrolled people.
class FaceMatch {
  const FaceMatch({
    required this.personId,
    required this.name,
    required this.similarity,
  });

  final int personId;
  final String name;
  final double similarity;
}

/// Face detector and embedder stub.
///
/// ONNX Runtime caused a native library crash on Android (Xiaomi and others).
/// This stub returns empty results so the rest of the app works while we
/// migrate to a TFLite-based face recognizer.
class FaceRecognizer {
  FaceRecognizer();

  bool get isReady => false;
  String? get error => 'Face recognition unavailable — model engine update required.';

  static const double matchThreshold = 0.58;

  Future<void> load() async {}

  Future<List<FaceBox>> detect(Uint8List encoded) async => const <FaceBox>[];

  Future<Float32List> embed(Uint8List encoded, FaceBox face) async =>
      Float32List(0);

  static double similarity(Float32List a, Float32List b) {
    if (a.length != b.length || a.isEmpty) return 0;
    var dot = 0.0, normA = 0.0, normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA <= 0 || normB <= 0) return 0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  static FaceMatch? bestMatch({
    required Float32List face,
    required Map<int, ({String name, Float32List vector})> people,
  }) {
    FaceMatch? best;
    for (final entry in people.entries) {
      final score = similarity(face, entry.value.vector);
      if (score >= matchThreshold && (best == null || score > best.similarity)) {
        best = FaceMatch(
          personId: entry.key,
          name: entry.value.name,
          similarity: score,
        );
      }
    }
    return best;
  }

  void dispose() {}
}
