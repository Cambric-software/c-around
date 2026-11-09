import 'dart:typed_data';

import 'package:cambric_app/core/ai/speech_recognizer.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pcm(List<int> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('converts silence to zeros', () {
    final result = SpeechRecognizer.pcm16ToFloat(pcm(<int>[0, 0, 0]));
    expect(result, hasLength(3));
    expect(result.every((double value) => value == 0), isTrue);
  });

  test('maps the full int16 range to -1..1', () {
    final result = SpeechRecognizer.pcm16ToFloat(
      pcm(<int>[32767, -32768, 16384]),
    );
    expect(result[0], closeTo(0.99997, 1e-4));
    expect(result[1], closeTo(-1.0, 1e-9));
    expect(result[2], closeTo(0.5, 1e-9));
  });

  test('ignores a trailing odd byte', () {
    final bytes = Uint8List.fromList(<int>[0x00, 0x40, 0xFF]);
    final result = SpeechRecognizer.pcm16ToFloat(bytes);
    expect(result, hasLength(1));
    expect(result.single, closeTo(0.5, 1e-9));
  });

  test('empty input gives an empty result', () {
    expect(SpeechRecognizer.pcm16ToFloat(Uint8List(0)), isEmpty);
  });
}
