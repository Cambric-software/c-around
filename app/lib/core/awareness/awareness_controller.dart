import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/face_recognizer.dart';
import '../ai/moondream_client.dart';
import '../ai/priority_engine.dart';
import '../ai/yolo_detector.dart';
import '../data/ca_database.dart';
import '../data/models.dart';
import '../output/announcer.dart';
import '../output/speech_strings.dart';
import '../settings/settings_service.dart';
import '../vision/camera_frame_source.dart';

/// Drives continuous camera awareness.
///
/// One timer captures a still, runs the object detector, turns the detections
/// into a short ordered list and hands the important ones to [Announcer]. It
/// also owns the two Moondream actions that need a fresh frame - describe and
/// read text - so every screen uses the same camera lifecycle instead of
/// starting a second one.
class AwarenessController extends ChangeNotifier {
  AwarenessController({
    required this.settings,
    required this.camera,
    required this.detector,
    required this.faces,
    required this.moondream,
    required this.announcer,
    required this.database,
    this.interval = const Duration(milliseconds: 2500),
  });

  /// User preferences.
  final SettingsService settings;

  /// Camera used for stills and preview.
  final CameraFrameSource camera;

  /// Bundled object detector.
  final YoloDetector detector;

  /// Bundled face detector and embedder.
  final FaceRecognizer faces;

  /// Desktop-only scene describer.
  final MoondreamClient moondream;

  /// Speech, haptics and event history.
  final Announcer announcer;

  /// People enrolled for face recognition.
  final CaDatabase database;

  /// Gap between automatic scans.
  final Duration interval;

  Timer? _timer;
  bool _running = false;
  bool _busy = false;
  bool _describing = false;
  bool _reading = false;
  String? _error;
  VisionResult? _lastVision;
  Uint8List? _lastFrame;
  List<Hazard> _hazards = const <Hazard>[];
  Map<int, ({String name, Float32List vector})> _people =
      <int, ({String name, Float32List vector})>{};
  DateTime? _lastFaceCheck;

  /// True while automatic scanning is on.
  bool get isRunning => _running;

  /// True while a scan is in flight.
  bool get isBusy => _busy;

  /// True while Moondream is describing a fresh frame.
  bool get isDescribing => _describing;

  /// True while Moondream is reading text.
  bool get isReading => _reading;

  /// Why the camera or detector is unavailable.
  String? get error => _error;

  /// Most recent detector result, for the preview overlay and list.
  VisionResult? get lastVision => _lastVision;

  /// Most recent captured JPEG, for a still preview.
  Uint8List? get lastFrame => _lastFrame;

  /// Hazards from the most recent scan, most urgent first.
  List<Hazard> get hazards => List<Hazard>.unmodifiable(_hazards);

  /// Number of enrolled people loaded for matching.
  int get knownPeopleCount => _people.length;

  /// Speech strings in the user's language.
  SpeechStrings get _strings => SpeechStrings(settings.speechLanguage);

  /// Start the camera and the scan timer.
  Future<bool> start() async {
    if (_running) return true;
    final started = await camera.start();
    if (!started) {
      _error = camera.error ?? 'The camera could not be started.';
      notifyListeners();
      return false;
    }

    await detector.load();
    // If detector is unavailable (stubbed), still start camera for
    // the live preview and scene description via YOLO fallback.
    // isReady = false just means auto-scanning won't produce hazard alerts.

    await refreshPeople();
    _error = null;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _scan());
    notifyListeners();
    unawaited(_scan());
    return true;
  }

  /// Stop scanning and release the camera.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    await camera.stop();
    notifyListeners();
  }

  /// Toggle automatic scanning.
  Future<bool> toggle() async {
    if (_running) {
      await stop();
      return false;
    }
    return start();
  }

  /// Reload the enrolled face vectors.
  Future<void> refreshPeople() async {
    try {
      final people = await database.people();
      final loaded = <int, ({String name, Float32List vector})>{};
      for (final person in people) {
        final id = person.id;
        final vector = CaDatabase.decodeEmbedding(person.embedding);
        if (id != null && vector != null) {
          loaded[id] = (name: person.name, vector: vector);
        }
      }
      _people = loaded;
    } catch (error) {
      debugPrint('Could not load enrolled faces: $error');
    }
  }

  Future<void> _scan() async {
    if (!_running || _busy) return;
    _busy = true;
    try {
      final bytes = await camera.capture();
      if (bytes == null) {
        _error = camera.error;
        return;
      }
      _lastFrame = bytes;
      final vision = await detector.detect(bytes);
      _lastVision = vision;

      final hazards = const PriorityEngine().evaluate(
        vision.detections,
        confidenceThreshold: settings.detectionConfidence,
        strings: _strings,
      );
      _hazards = hazards;

      final named = await _identifyPeople(bytes, hazards);
      for (final hazard in hazards) {
        if (named && hazard.kind == 'person') continue;
        await announcer.announce(
          kind: hazard.kind,
          message: hazard.message,
          level: hazard.level,
          source: 'vision',
        );
      }
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Match faces against enrolled people. Returns true when a name was said.
  Future<bool> _identifyPeople(Uint8List bytes, List<Hazard> hazards) async {
    if (_people.isEmpty) return false;
    if (!hazards.any((Hazard hazard) => hazard.kind == 'person')) return false;
    final now = DateTime.now();
    final last = _lastFaceCheck;
    if (last != null && now.difference(last) < const Duration(seconds: 4)) {
      return false;
    }
    _lastFaceCheck = now;

    try {
      await faces.load();
      if (!faces.isReady) return false;
      final boxes = await faces.detect(bytes);
      if (boxes.isEmpty) return false;
      var named = false;
      for (final box in boxes.take(2)) {
        if (box.width < 40 || box.height < 40) continue;
        final vector = await faces.embed(bytes, box);
        final match = FaceRecognizer.bestMatch(face: vector, people: _people);
        if (match == null) continue;
        final cx = box.left + box.width / 2;
        await announcer.announce(
          kind: 'face_${match.personId}',
          message: _strings.faceRecognised(match.name, _strings.direction(cx)),
          level: AwarenessLevel.info,
          source: 'face',
        );
        named = true;
      }
      return named;
    } catch (error) {
      debugPrint('Face identification failed: $error');
      return false;
    }
  }

  /// Capture a fresh frame and describe it with Moondream.
  Future<String> describeScene() async {
    final bytes = await _freshFrame();
    _describing = true;
    notifyListeners();
    try {
      // Try Moondream first (desktop). On Android it returns an error immediately.
      String text;
      try {
        text = await moondream.describe(bytes);
      } on Exception {
        // Moondream unavailable — fall back to YOLO-based description.
        text = await _yoloDescription(bytes);
      }
      _lastFrame = bytes;
      await announcer.speakDirect(text);
      return text;
    } finally {
      _describing = false;
      notifyListeners();
    }
  }

  /// Capture a fresh frame and read the words in it.
  Future<String> readText() async {
    final bytes = await _freshFrame();
    _reading = true;
    notifyListeners();
    try {
      String text;
      try {
        text = await moondream.readText(bytes);
      } on Exception {
        // Moondream unavailable — run YOLO and report what was found.
        text = await _yoloDescription(bytes);
      }
      _lastFrame = bytes;
      await announcer.speakDirect(text);
      return text;
    } finally {
      _reading = false;
      notifyListeners();
    }
  }

  /// Ask Moondream a free-form question about a fresh frame.
  Future<String> ask(String question) async {
    final bytes = await _freshFrame();
    String text;
    try {
      text = await moondream.ask(bytes, question);
    } on Exception {
      text = await _yoloDescription(bytes);
    }
    _lastFrame = bytes;
    await announcer.speakDirect(text);
    return text;
  }

  /// Describe a photo the user picked from disk.
  Future<String> describeImage(Uint8List bytes) async {
    String text;
    try {
      text = await moondream.describe(bytes);
    } on Exception {
      text = await _yoloDescription(bytes);
    }
    _lastFrame = bytes;
    await announcer.speakDirect(text);
    return text;
  }

  /// Read text from a photo the user picked from disk.
  Future<String> readImage(Uint8List bytes) async {
    String text;
    try {
      text = await moondream.readText(bytes);
    } on Exception {
      text = await _yoloDescription(bytes);
    }
    _lastFrame = bytes;
    await announcer.speakDirect(text);
    return text;
  }

  /// Ask a question about a photo the user picked from disk.
  Future<String> askImage(Uint8List bytes, String question) async {
    String text;
    try {
      text = await moondream.ask(bytes, question);
    } on Exception {
      text = await _yoloDescription(bytes);
    }
    _lastFrame = bytes;
    await announcer.speakDirect(text);
    return text;
  }

  /// Run the object detector on a photo and announce what it finds.
  Future<VisionResult> analyseImage(Uint8List bytes) async {
    await detector.load();
    if (!detector.isReady) {
      throw StateError(detector.error ?? 'The object detector is not loaded.');
    }
    final vision = await detector.detect(bytes);
    _lastFrame = bytes;
    _lastVision = vision;
    final hazards = const PriorityEngine().evaluate(
      vision.detections,
      confidenceThreshold: settings.detectionConfidence,
    );
    _hazards = hazards;
    for (final hazard in hazards.take(3)) {
      await announcer.announce(
        kind: hazard.kind,
        message: hazard.message,
        level: hazard.level,
        source: 'vision',
      );
    }
    notifyListeners();
    return vision;
  }

  /// YOLO-based scene description — used on Android when Moondream is not available.
  ///
  /// Runs the object detector on [bytes] and builds a natural spoken sentence
  /// from what it finds, with positions derived from bounding-box centres.
  Future<String> _yoloDescription(Uint8List bytes) async {
    // If detector not available, speak an honest message in the user's language
    if (!detector.isReady) {
      final msg = _strings.nothingDetected();
      await announcer.speakDirect(msg);
      return msg;
    }
    try {
      final vision = await detector.detect(bytes);
      if (vision.detections.isEmpty) {
        return _strings.nothingDetected();
      }

      final s = _strings;
      final sorted = List.of(vision.detections)
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final top = sorted.take(5).toList();

      final parts = <String>[];
      for (final d in top) {
        final cx = (d.left + d.right) / 2;
        parts.add('${s.translateLabel(d.label)} ${s.direction(cx)}');
      }

      return s.iCanSeeMultiple(parts);
    } catch (e) {
      return _strings.cannotAnalyse();
    }
  }

  Future<Uint8List> _freshFrame() async {
    if (!camera.isReady) {
      final started = await camera.start();
      if (!started) {
        throw StateError(camera.error ?? 'The camera is not available.');
      }
    }
    final bytes = await camera.capture();
    if (bytes == null) {
      throw StateError(camera.error ?? 'The camera did not return a frame.');
    }
    return bytes;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
