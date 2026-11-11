import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// One microphone stream shared by every listener in the app.
///
/// Sound alerts and captions can both be on at once, and opening two recorders
/// at the same time fails on Android. This class opens the microphone once,
/// broadcasts 16 kHz mono PCM chunks, and closes it when the last consumer
/// releases it.
class MicrophoneSource extends ChangeNotifier {
  AudioRecorder? _recorderInstance;
  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();

  int _consumers = 0;
  bool _running = false;
  String? _error;

  /// Chunks of little-endian 16-bit PCM at [sampleRate].
  Stream<Uint8List> get chunks => _controller.stream;

  /// True while the microphone is open.
  bool get isRunning => _running;

  /// Why the microphone is unavailable.
  String? get error => _error;

  /// Sample rate every consumer can rely on.
  static const int sampleRate = 16000;

  /// Ask for the microphone, opening it when this is the first consumer.
  Future<bool> acquire() async {
    _consumers++;
    if (_running) return true;

    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        _consumers--;
        _error = 'Microphone permission was denied. Allow it in system '
            'settings to use sound alerts and captions.';
        notifyListeners();
        return false;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: true,
        ),
      );
      _running = true;
      _error = null;
      stream.listen(
        _controller.add,
        onError: (Object error) {
          _error = error.toString();
          notifyListeners();
        },
      );
      notifyListeners();
      return true;
    } catch (error) {
      _consumers = 0;
      _running = false;
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  /// Release the microphone. It closes when no consumer is left.
  Future<void> release() async {
    _consumers = _consumers > 0 ? _consumers - 1 : 0;
    if (_consumers > 0) return;
    await _close();
  }

  /// Force the microphone closed, for app shutdown.
  Future<void> close() async {
    _consumers = 0;
    await _close();
  }

  Future<void> _close() async {
    if (!_running) return;
    _running = false;
    try {
      await _recorder.stop();
    } catch (_) {
      // The stream may already be closed.
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_close());
    unawaited(_recorder.dispose());
    unawaited(_controller.close());
    super.dispose();
  }
}
