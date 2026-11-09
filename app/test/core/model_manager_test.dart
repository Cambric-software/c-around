import 'dart:io';

import 'package:cambric_app/core/ai/model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the two optional packs are offered', () {
    final ids = ModelManager.packs.map((ModelPack pack) => pack.id).toList();
    expect(ids, <String>['moondream', 'whisper']);
  });

  test('Moondream is desktop-only and needs its server', () {
    final pack = ModelManager.packs
        .firstWhere((ModelPack value) => value.id == 'moondream');
    expect(pack.requiresDesktop, isTrue);
    expect(pack.requiredNames, contains('text.gguf'));
    expect(pack.requiredNames, contains('mmproj.gguf'));
    expect(pack.requiredNames, contains(ModelManager.serverExecutable));
    expect(pack.totalBytes, greaterThan(1500000000));
  });

  test('Whisper needs exactly the three published files', () {
    final pack = ModelManager.packs
        .firstWhere((ModelPack value) => value.id == 'whisper');
    expect(pack.requiresDesktop, isFalse);
    expect(
      pack.requiredNames,
      <String>[
        'tiny-encoder.int8.onnx',
        'tiny-decoder.int8.onnx',
        'tiny-tokens.txt',
      ],
    );
    expect(pack.totalBytes, 12937772 + 89855401 + 816730);
  });

  test('the pinned llama.cpp build is stable', () {
    expect(ModelManager.llamaBuild, 'b12224');
  });

  test('server executable matches the host platform', () {
    expect(
      ModelManager.serverExecutable,
      Platform.isWindows ? 'llama-server.exe' : 'llama-server',
    );
  });

  test('pack paths stay inside the pack directory', () {
    final root = Directory.systemTemp.createTempSync('c_around_models');
    addTearDown(() => root.deleteSync(recursive: true));
    final manager = ModelManager(root: root);
    expect(
      manager.pathFor('whisper', 'tiny-tokens.txt'),
      '${root.path}${Platform.pathSeparator}whisper'
      '${Platform.pathSeparator}tiny-tokens.txt',
    );
    expect(
      manager.directoryFor('moondream').path,
      '${root.path}${Platform.pathSeparator}moondream',
    );
  });
}
