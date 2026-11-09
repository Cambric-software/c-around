import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/sound_classifier.dart';
import '../ai/speech_recognizer.dart';
import '../output/announcer.dart';
import 'microphone_source.dart';

/// Listens to the microphone and announces recognised sounds.
///
/// Audio never leaves the device. Chunks from [MicrophoneSource] are converted
/// to float samples, classified by YAMNet, and only the classes mapped in
/// `sound_events.dart` are announced; everything else is ignored so the user is
/// not trained to ignore the alerts that matter.
class SoundMonitor extends ChangeNotifier {
  SoundMonitor({
    required this.classifier,
    required this.announcer,
    required this.microphone,
  });

  /// Bundled YAMNet classifier.
  final YamnetClassifier classifier;

  /// Speech and event history.
  final Announcer announcer;

  /// Shared microphone.
  final MicrophoneSource microphone;

  StreamSubscription<Uint8List>? _subscription;
  final List<int> _pcm = <int>[];
  bool _running = false;
  bool _classifying = false;
  String? _error;
  List<SoundHit> _lastHits = const <SoundHit>[];

  /// True while the microphone is open for sound alerts.
  bool get isRunning => _running;

  /// Why listening is unavailable.
  String? get error => _error;

  /// The strongest classes from the last window.
  List<SoundHit> get lastHits => List<SoundHit>.unmodifiable(_lastHits);

  /// True when the model loaded.
  bool get isReady => classifier.isReady;

  /// Start listening. Requests microphone permission on first use.
  Future<bool> start() async {
    if (_running) return true;
    await classifier.load();
    if (!classifier.isReady) {
      _error = classifier.error ?? 'The sound model could not be loaded.';
      notifyListeners();
      return false;
    }

    final acquired = await microphone.acquire();
    if (!acquired) {
      _error = microphone.error ?? 'The microphone is not available.';
      notifyListeners();
      return false;
    }

    _pcm.clear();
    _running = true;
    _error = null;
    _subscription = microphone.chunks.listen(
      _onChunk,
      onError: (Object error) {
        _error = error.toString();
        notifyListeners();
      },
      cancelOnError: false,
    );
    notifyListeners();
    return true;
  }

  /// Stop listening and release the microphone.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_running) {
      _running = false;
      await microphone.release();
    }
    _pcm.clear();
    notifyListeners();
  }

  /// Toggle listening.
  Future<bool> toggle() async {
    if (_running) {
      await stop();
      return false;
    }
    return start();
  }

  void _onChunk(Uint8List chunk) {
    _pcm.addAll(chunk);
    const windowBytes = YamnetClassifier.windowSamples * 2;
    if (_pcm.length < windowBytes) return;

    final window = Uint8List.fromList(_pcm.take(windowBytes).toList());
    _pcm.removeRange(0, windowBytes);
    // If the classifier is slower than real time, drop old audio rather than
    // queueing minutes of it.
    if (_pcm.length > windowBytes * 3) {
      _pcm.removeRange(0, _pcm.length - windowBytes);
    }
    unawaited(_classify(window));
  }

  Future<void> _classify(Uint8List pcm16) async {
    if (_classifying) return;
    _classifying = true;
    try {
      final samples = SpeechRecognizer.pcm16ToFloat(pcm16);
      final hits = await classifier.classify(samples);
      _lastHits = hits;
      for (final hit in hits) {
        final alert = hit.alert;
        if (alert == null) continue;
        await announcer.announce(
          kind: alert.kind,
          message: alert.message,
          level: alert.level,
          source: 'sound',
        );
      }
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _classifying = false;
      notifyListeners();
    }
  }
}
