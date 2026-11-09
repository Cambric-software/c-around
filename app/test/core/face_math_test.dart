import 'dart:typed_data';

import 'package:cambric_app/core/ai/face_recognizer.dart';
import 'package:cambric_app/core/data/ca_database.dart';
import 'package:flutter_test/flutter_test.dart';

Float32List vector(List<double> values) => Float32List.fromList(values);

void main() {
  test('similarity is 1 for identical vectors and 0 for orthogonal ones', () {
    expect(
      FaceRecognizer.similarity(vector(<double>[1, 0, 0]), vector(<double>[1, 0, 0])),
      closeTo(1.0, 1e-6),
    );
    expect(
      FaceRecognizer.similarity(vector(<double>[1, 0, 0]), vector(<double>[0, 1, 0])),
      closeTo(0.0, 1e-6),
    );
  });

  test('similarity is symmetric and scale invariant', () {
    final a = vector(<double>[0.2, 0.5, 0.8]);
    final b = vector(<double>[0.4, 1.0, 1.6]);
    expect(
      FaceRecognizer.similarity(a, b),
      closeTo(FaceRecognizer.similarity(b, a), 1e-9),
    );
    expect(FaceRecognizer.similarity(a, b), closeTo(1.0, 1e-6));
  });

  test('zero vectors do not divide by zero', () {
    expect(
      FaceRecognizer.similarity(vector(<double>[0, 0, 0]), vector(<double>[1, 0, 0])),
      0.0,
    );
  });

  test('bestMatch picks the closest person above the threshold', () {
    final match = FaceRecognizer.bestMatch(
      face: vector(<double>[1, 0, 0]),
      people: <int, ({String name, Float32List vector})>{
        1: (name: 'Mariam', vector: vector(<double>[0.9, 0.1, 0])),
        2: (name: 'Omar', vector: vector(<double>[0, 1, 0])),
      },
    );
    expect(match?.personId, 1);
    expect(match?.name, 'Mariam');
    expect(match!.similarity, greaterThanOrEqualTo(FaceRecognizer.matchThreshold));
  });

  test('bestMatch refuses a weak match instead of guessing', () {
    final match = FaceRecognizer.bestMatch(
      face: vector(<double>[1, 0, 0]),
      people: <int, ({String name, Float32List vector})>{
        1: (name: 'Omar', vector: vector(<double>[0, 1, 0])),
      },
    );
    expect(match, isNull);
  });

  test('bestMatch on an empty set is null', () {
    expect(
      FaceRecognizer.bestMatch(
        face: vector(<double>[1, 0, 0]),
        people: <int, ({String name, Float32List vector})>{},
      ),
      isNull,
    );
  });

  test('embedding encoding preserves float32 values', () {
    final source = vector(<double>[0.5, -0.25, 1.0]);
    final decoded = CaDatabase.decodeEmbedding(
      CaDatabase.encodeEmbedding(source),
    );
    expect(decoded, isNotNull);
    expect(decoded!.length, 3);
    expect(decoded[0], closeTo(0.5, 1e-6));
    expect(decoded[1], closeTo(-0.25, 1e-6));
    expect(decoded[2], closeTo(1.0, 1e-6));
  });

  test('a corrupt embedding blob is rejected', () {
    expect(CaDatabase.decodeEmbedding(Uint8List.fromList(<int>[1, 2, 3])), isNull);
  });
}
