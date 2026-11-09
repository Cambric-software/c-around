import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'sound_events.dart';

/// One scored AudioSet class.
class SoundHit {
  /// Create a hit.
  const SoundHit({required this.name, required this.score, this.alert});

  /// AudioSet display name.
  final String name;

  /// Probability averaged over the clip.
  final double score;

  /// The alert this class maps to, when it is one the app acts on.
  final SoundAlert? alert;
}

/// YAMNet sound classification on ONNX Runtime.
///
/// The model is the 521-class AudioSet classifier (16 MB, bundled). It takes
/// 15,600 mono samples at 16 kHz - 0.975 s - and returns one score row per
/// frame. Scores are averaged across the clip so a short bang still registers.
class YamnetClassifier {
  YamnetClassifier();

  OrtSession? _session;
  OrtSessionOptions? _options;
  List<String> _classNames = const <String>[];
  bool _loading = false;
  String? _error;

  /// True once the model and class map are loaded.
  bool get isReady => _session != null && _classNames.isNotEmpty;

  /// Why loading failed, if it did.
  String? get error => _error;

  /// Samples per classification window.
  static const int windowSamples = 15600;

  /// Sample rate the model expects.
  static const int sampleRate = 16000;

  /// Load the bundled model and class map.
  Future<void> load() async {
    if (_session != null || _loading) return;
    _loading = true;
    try {
      OrtEnv.instance.init();
      final model = await rootBundle.load('assets/models/yamnet.onnx');
      final options = OrtSessionOptions()
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
      _options = options;
      _session = OrtSession.fromBuffer(model.buffer.asUint8List(), options);

      final csv = await rootBundle.loadString('assets/models/yamnet_class_map.csv');
      _classNames = _parseClassMap(csv);
      if (_classNames.isEmpty) {
        throw StateError('YAMNet class map is empty');
      }
      _error = null;
    } catch (error) {
      _error = error.toString();
      _session = null;
      _classNames = const <String>[];
    } finally {
      _loading = false;
    }
  }

  /// Classify a window of mono float samples in -1..1.
  Future<List<SoundHit>> classify(Float32List samples) async {
    final session = _session;
    if (session == null || _classNames.isEmpty) {
      throw StateError(_error ?? 'Sound model is not loaded');
    }
    if (samples.length < windowSamples) {
      throw ArgumentError.value(
        samples.length,
        'samples',
        'Need $windowSamples samples',
      );
    }

    final tensor = OrtValueTensor.createTensorWithDataList(
      samples,
      <int>[samples.length],
    );
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;
    try {
      outputs = session.run(runOptions, <String, OrtValue>{
        session.inputNames.first: tensor,
      });
      final raw = outputs.first?.value;
      if (raw is! List || raw.isEmpty) {
        throw StateError('Sound model returned no scores');
      }

      final frames = raw.length;
      final totals = List<double>.filled(_classNames.length, 0);
      for (final frame in raw) {
        final row = frame as List;
        final count = math.min(row.length, totals.length);
        for (var i = 0; i < count; i++) {
          totals[i] += (row[i] as num).toDouble();
        }
      }
      for (var i = 0; i < totals.length; i++) {
        totals[i] /= frames;
      }

      final hits = <SoundHit>[];
      for (var i = 0; i < totals.length; i++) {
        final score = totals[i];
        if (score < 0.05) continue;
        final name = _classNames[i];
        hits.add(
          SoundHit(
            name: name,
            score: score,
            alert: soundAlertFor(name, score),
          ),
        );
      }
      hits.sort((SoundHit a, SoundHit b) => b.score.compareTo(a.score));
      return hits.take(5).toList();
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

  /// Parse `index,mid,display_name` rows, honouring quoted commas.
  static List<String> _parseClassMap(String csv) {
    final names = <String>[];
    for (final line in csv.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final fields = _splitCsv(trimmed);
      if (fields.length < 3) continue;
      final index = int.tryParse(fields[0]);
      if (index == null) continue;
      while (names.length <= index) {
        names.add('class_${names.length}');
      }
      names[index] = fields[2].replaceAll('"', '').trim();
    }
    return names;
  }

  static List<String> _splitCsv(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        quoted = !quoted;
      } else if (char == ',' && !quoted) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }
}
