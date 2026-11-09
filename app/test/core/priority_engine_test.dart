import 'package:cambric_app/core/ai/priority_engine.dart';
import 'package:cambric_app/core/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a detection with a normalised box.
Detection detection({
  String label = 'person',
  double confidence = 0.9,
  double left = 0.4,
  double top = 0.3,
  double right = 0.6,
  double bottom = 0.7,
}) {
  return Detection(
    label: label,
    confidence: confidence,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}

void main() {
  group('Detection geometry', () {
    test('direction splits at the documented thresholds', () {
      expect(detection(left: 0.0, right: 0.2).direction, 'on your left');
      expect(detection(left: 0.33, right: 0.34).direction, 'on your left');
      expect(detection(left: 0.4, right: 0.6).direction, 'ahead');
      expect(detection(left: 0.67, right: 0.8).direction, 'on your right');
    });

    test('height and area are absolute fractions', () {
      final value = detection(left: 0.2, top: 0.1, right: 0.6, bottom: 0.5);
      expect(value.height, closeTo(0.4, 1e-9));
      expect(value.area, closeTo(0.16, 1e-9));
    });
  });

  group('decodeYolo', () {
    List<double> tensor({
      required int anchors,
      required int classes,
      required int anchor,
      required double cx,
      required double cy,
      required double w,
      required double h,
      required int classIndex,
      required double score,
    }) {
      final output = List<double>.filled((4 + classes) * anchors, 0);
      output[anchor] = cx;
      output[anchors + anchor] = cy;
      output[2 * anchors + anchor] = w;
      output[3 * anchors + anchor] = h;
      output[(4 + classIndex) * anchors + anchor] = score;
      return output;
    }

    test('converts centre boxes to normalised edges', () {
      final output = tensor(
        anchors: 1,
        classes: 80,
        anchor: 0,
        cx: 320,
        cy: 320,
        w: 128,
        h: 64,
        classIndex: 0,
        score: 0.9,
      );
      final result = PriorityEngine.decodeYolo(
        output: output,
        anchors: 1,
        classes: 80,
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        imageWidth: 640,
        imageHeight: 640,
        scale: 1,
        padX: 0,
        padY: 0,
      );
      expect(result, hasLength(1));
      expect(result.single.label, 'person');
      expect(result.single.left, closeTo(0.4, 1e-6));
      expect(result.single.top, closeTo(0.45, 1e-6));
      expect(result.single.right, closeTo(0.6, 1e-6));
      expect(result.single.bottom, closeTo(0.55, 1e-6));
    });

    test('letterbox padding is removed before normalising', () {
      final output = tensor(
        anchors: 1,
        classes: 80,
        anchor: 0,
        cx: 320,
        cy: 320,
        w: 100,
        h: 100,
        classIndex: 2,
        score: 0.8,
      );
      final result = PriorityEngine.decodeYolo(
        output: output,
        anchors: 1,
        classes: 80,
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        imageWidth: 1000,
        imageHeight: 500,
        scale: 0.5,
        padX: 70,
        padY: 160,
      );
      expect(result, hasLength(1));
      expect(result.single.label, 'car');
      expect(result.single.left, closeTo((320 - 50 - 70) / 0.5 / 1000, 1e-6));
      expect(result.single.top, closeTo((320 - 50 - 160) / 0.5 / 500, 1e-6));
    });

    test('drops boxes below the confidence threshold', () {
      final output = tensor(
        anchors: 1,
        classes: 80,
        anchor: 0,
        cx: 320,
        cy: 320,
        w: 10,
        h: 10,
        classIndex: 0,
        score: 0.2,
      );
      final result = PriorityEngine.decodeYolo(
        output: output,
        anchors: 1,
        classes: 80,
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        imageWidth: 640,
        imageHeight: 640,
        scale: 1,
        padX: 0,
        padY: 0,
      );
      expect(result, isEmpty);
    });

    test('non-max suppression keeps the strongest of two overlapping boxes',
        () {
      const anchors = 2;
      final output = List<double>.filled(84 * anchors, 0);
      // Anchor 0: weaker, anchor 1: stronger, same place and class.
      for (final (int index, double score) in <(int, double)>[
        (0, 0.6),
        (1, 0.9),
      ]) {
        output[index] = 320;
        output[anchors + index] = 320;
        output[2 * anchors + index] = 100;
        output[3 * anchors + index] = 100;
        output[(4 + 0) * anchors + index] = score;
      }
      final result = PriorityEngine.decodeYolo(
        output: output,
        anchors: anchors,
        classes: 80,
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        imageWidth: 640,
        imageHeight: 640,
        scale: 1,
        padX: 0,
        padY: 0,
      );
      expect(result, hasLength(1));
      expect(result.single.confidence, 0.9);
    });
  });

  group('evaluate', () {
    const engine = PriorityEngine();

    test('a close vehicle is danger and a far one is warning', () {
      final close = engine.evaluate(<Detection>[
        detection(label: 'car', top: 0.2, bottom: 0.8),
      ]);
      expect(close.single.level, AwarenessLevel.danger);
      expect(close.single.message, 'Car ahead.');

      final far = engine.evaluate(<Detection>[
        detection(label: 'car', top: 0.4, bottom: 0.5),
      ]);
      expect(far.single.level, AwarenessLevel.warning);
    });

    test('a person close enough to fill the frame is a warning', () {
      final result = engine.evaluate(<Detection>[
        detection(top: 0.1, bottom: 0.7),
      ]);
      expect(result.single.kind, 'person');
      expect(result.single.level, AwarenessLevel.warning);
      expect(result.single.message, 'Person very close, ahead.');
    });

    test('a distant person is only a notice', () {
      final result = engine.evaluate(<Detection>[
        detection(top: 0.4, bottom: 0.55),
      ]);
      expect(result.single.level, AwarenessLevel.info);
      expect(result.single.message, 'Person ahead.');
    });

    test('furniture low in the frame becomes an obstacle', () {
      final result = engine.evaluate(<Detection>[
        detection(label: 'chair', top: 0.4, bottom: 0.8),
      ]);
      expect(result.single.kind, 'obstacle');
      expect(result.single.level, AwarenessLevel.warning);
    });

    test('furniture high in the frame is ignored', () {
      final result = engine.evaluate(<Detection>[
        detection(label: 'chair', top: 0.1, bottom: 0.5),
      ]);
      expect(result, isEmpty);
    });

    test('knife and scissors collapse into one sharp-object warning', () {
      final result = engine.evaluate(<Detection>[
        detection(label: 'knife', left: 0.1, right: 0.2),
        detection(label: 'scissors', left: 0.1, right: 0.2),
      ]);
      expect(result, hasLength(1));
      expect(result.single.kind, 'sharp');
    });

    test('weak detections are filtered before the rules run', () {
      final result = engine.evaluate(
        <Detection>[detection(label: 'car', confidence: 0.3)],
        confidenceThreshold: 0.45,
      );
      expect(result, isEmpty);
    });

    test('danger sorts before warning and info', () {
      final result = engine.evaluate(<Detection>[
        detection(label: 'bottle', confidence: 0.9),
        detection(label: 'dog', confidence: 0.9),
        detection(label: 'car', confidence: 0.9, top: 0.2, bottom: 0.8),
      ]);
      expect(result.first.level, AwarenessLevel.danger);
      expect(result.last.kind, 'object');
    });

    test('the same kind and direction keeps only the strongest box', () {
      final result = engine.evaluate(<Detection>[
        detection(confidence: 0.6, top: 0.4, bottom: 0.55),
        detection(confidence: 0.95, top: 0.4, bottom: 0.55),
      ]);
      expect(result, hasLength(1));
      expect(result.single.score, 0.95);
    });
  });
}
