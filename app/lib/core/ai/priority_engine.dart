import 'dart:math' as math;

import '../data/models.dart';

/// One object detected in a frame.
///
/// Coordinates are normalised to 0..1 so the same detection can be drawn over
/// a preview of any size.
class Detection {
  /// Create a detection.
  const Detection({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// COCO class name.
  final String label;

  /// Detector score, 0..1.
  final double confidence;

  /// Left edge, 0..1.
  final double left;

  /// Top edge, 0..1.
  final double top;

  /// Right edge, 0..1.
  final double right;

  /// Bottom edge, 0..1.
  final double bottom;

  /// Horizontal centre.
  double get centerX => (left + right) / 2;

  /// Height as a fraction of the frame, used as a rough proximity cue.
  double get height => (bottom - top).abs();

  /// Area as a fraction of the frame.
  double get area => (right - left).abs() * height;

  /// Where the object sits relative to the user.
  String get direction {
    if (centerX < 0.34) return 'on your left';
    if (centerX > 0.66) return 'on your right';
    return 'ahead';
  }
}

/// A sentence the priority engine decided is worth saying.
class Hazard {
  /// Create a hazard.
  const Hazard({
    required this.kind,
    required this.message,
    required this.level,
    required this.direction,
    required this.score,
  });

  /// Machine name, used for cooldown.
  final String kind;

  /// Sentence shown and spoken.
  final String message;

  /// Severity.
  final AwarenessLevel level;

  /// Left, right or ahead.
  final String direction;

  /// Confidence of the underlying detection.
  final double score;
}

/// Turns raw detections into a short, ordered list of things worth saying.
///
/// This is deliberately pure and has no Flutter or model dependency: the rules
/// that decide whether a staircase outranks a chair are testable without a
/// camera, and they are the part that matters most for safety.
class PriorityEngine {
  /// Create an engine.
  const PriorityEngine();

  /// COCO classes that are dangerous when close.
  static const Set<String> _vehicles = <String>{
    'car',
    'truck',
    'bus',
    'motorcycle',
    'train',
    'bicycle',
  };

  /// Furniture that becomes an obstacle when it fills the lower frame.
  static const Set<String> _obstacles = <String>{
    'chair',
    'couch',
    'bench',
    'dining table',
    'toilet',
    'potted plant',
    'bed',
  };

  /// Evaluate a frame.
  ///
  /// [confidenceThreshold] drops weak boxes before any rules run. The result is
  /// sorted by severity, then by how much of the frame the object fills, so the
  /// most important sentence is first.
  List<Hazard> evaluate(
    List<Detection> detections, {
    double confidenceThreshold = 0.45,
  }) {
    final hazards = <String, Hazard>{};

    void add(Hazard hazard) {
      final key = '${hazard.kind}|${hazard.direction}';
      final existing = hazards[key];
      if (existing == null || hazard.score > existing.score) {
        hazards[key] = hazard;
      }
    }

    for (final detection in detections) {
      if (detection.confidence < confidenceThreshold) continue;
      final label = detection.label.toLowerCase();
      final direction = detection.direction;
      final close = detection.height >= 0.32;
      final veryClose = detection.height >= 0.55;

      if (label == 'person') {
        add(
          Hazard(
            kind: 'person',
            message: close
                ? 'Person very close, $direction.'
                : 'Person $direction.',
            level: veryClose ? AwarenessLevel.warning : AwarenessLevel.info,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (_vehicles.contains(label)) {
        add(
          Hazard(
            kind: label,
            message: '${_label(label)} $direction.',
            level: close ? AwarenessLevel.danger : AwarenessLevel.warning,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (label == 'dog') {
        add(
          Hazard(
            kind: 'dog',
            message: 'Dog $direction.',
            level: AwarenessLevel.warning,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (label == 'knife' || label == 'scissors') {
        add(
          Hazard(
            kind: 'sharp',
            message: 'Sharp object $direction.',
            level: AwarenessLevel.warning,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (_obstacles.contains(label) && detection.bottom > 0.55) {
        add(
          Hazard(
            kind: 'obstacle',
            message: 'Obstacle $direction.',
            level: close ? AwarenessLevel.warning : AwarenessLevel.info,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (label == 'traffic light') {
        add(
          Hazard(
            kind: 'traffic_light',
            message: 'Traffic light $direction.',
            level: AwarenessLevel.info,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (label == 'stop sign') {
        add(
          Hazard(
            kind: 'stop_sign',
            message: 'Stop sign $direction.',
            level: AwarenessLevel.warning,
            direction: direction,
            score: detection.confidence,
          ),
        );
        continue;
      }

      if (label == 'backpack' ||
          label == 'handbag' ||
          label == 'suitcase' ||
          label == 'bottle' ||
          label == 'cup') {
        add(
          Hazard(
            kind: 'object',
            message: '${_label(label)} $direction.',
            level: AwarenessLevel.info,
            direction: direction,
            score: detection.confidence,
          ),
        );
      }
    }

    final ordered = hazards.values.toList()
      ..sort((Hazard a, Hazard b) {
        final byLevel = b.level.weight.compareTo(a.level.weight);
        if (byLevel != 0) return byLevel;
        return b.score.compareTo(a.score);
      });

    return ordered;
  }

  /// English label for a COCO class.
  static String _label(String label) {
    if (label.isEmpty) return 'Object';
    return label[0].toUpperCase() + label.substring(1);
  }

  /// Convert YOLO output boxes into [Detection]s.
  ///
  /// Exposed separately from the detector so it can be tested against a fixed
  /// tensor without loading ONNX. [output] is the flat `[1, 84, 8400]` tensor:
  /// four box values followed by eighty class scores for each anchor.
  static List<Detection> decodeYolo({
    required List<double> output,
    required int anchors,
    required int classes,
    required double confidenceThreshold,
    required double iouThreshold,
    required int imageWidth,
    required int imageHeight,
    required double scale,
    required double padX,
    required double padY,
  }) {
    final candidates = <Detection>[];

    for (var anchor = 0; anchor < anchors; anchor++) {
      var bestScore = 0.0;
      var bestClass = -1;
      for (var c = 0; c < classes; c++) {
        final score = output[(4 + c) * anchors + anchor];
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }
      if (bestScore < confidenceThreshold || bestClass < 0) continue;

      final cx = output[anchor];
      final cy = output[anchors + anchor];
      final w = output[2 * anchors + anchor];
      final h = output[3 * anchors + anchor];

      final left = (cx - w / 2 - padX) / scale;
      final top = (cy - h / 2 - padY) / scale;
      final right = (cx + w / 2 - padX) / scale;
      final bottom = (cy + h / 2 - padY) / scale;

      candidates.add(
        Detection(
          label: cocoNames[bestClass],
          confidence: bestScore,
          left: (left / imageWidth).clamp(0.0, 1.0),
          top: (top / imageHeight).clamp(0.0, 1.0),
          right: (right / imageWidth).clamp(0.0, 1.0),
          bottom: (bottom / imageHeight).clamp(0.0, 1.0),
        ),
      );
    }

    return _nms(candidates, iouThreshold);
  }

  static List<Detection> _nms(List<Detection> input, double threshold) {
    final sorted = List<Detection>.from(input)
      ..sort((Detection a, Detection b) => b.confidence.compareTo(a.confidence));
    final kept = <Detection>[];

    for (final candidate in sorted) {
      var overlaps = false;
      for (final existing in kept) {
        if (existing.label == candidate.label &&
            _iou(existing, candidate) > threshold) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) kept.add(candidate);
    }
    return kept;
  }

  static double _iou(Detection a, Detection b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.right, b.right);
    final bottom = math.min(a.bottom, b.bottom);
    final intersection =
        math.max(0.0, right - left) * math.max(0.0, bottom - top);
    final union = a.area + b.area - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }
}

/// COCO class names in the order YOLOv8 emits them.
const List<String> cocoNames = <String>[
  'person',
  'bicycle',
  'car',
  'motorcycle',
  'airplane',
  'bus',
  'train',
  'truck',
  'boat',
  'traffic light',
  'fire hydrant',
  'stop sign',
  'parking meter',
  'bench',
  'bird',
  'cat',
  'dog',
  'horse',
  'sheep',
  'cow',
  'elephant',
  'bear',
  'zebra',
  'giraffe',
  'backpack',
  'umbrella',
  'handbag',
  'tie',
  'suitcase',
  'frisbee',
  'skis',
  'snowboard',
  'sports ball',
  'kite',
  'baseball bat',
  'baseball glove',
  'skateboard',
  'surfboard',
  'tennis racket',
  'bottle',
  'wine glass',
  'cup',
  'fork',
  'knife',
  'spoon',
  'bowl',
  'banana',
  'apple',
  'sandwich',
  'orange',
  'broccoli',
  'carrot',
  'hot dog',
  'pizza',
  'donut',
  'cake',
  'chair',
  'couch',
  'potted plant',
  'bed',
  'dining table',
  'toilet',
  'tv',
  'laptop',
  'mouse',
  'remote',
  'keyboard',
  'cell phone',
  'microwave',
  'oven',
  'toaster',
  'sink',
  'refrigerator',
  'book',
  'clock',
  'vase',
  'scissors',
  'teddy bear',
  'hair drier',
  'toothbrush',
];
