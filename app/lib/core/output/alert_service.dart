import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import '../data/models.dart';
import '../settings/settings_service.dart';

/// Non-speech output: vibration, screen flash and the emergency tone.
///
/// Every channel is independently switchable. A deaf user needs the flash; a
/// blind user needs the vibration; someone in a quiet room may want neither.
/// Nothing here assumes one disability.
class AlertService {
  AlertService(this._settings);

  final SettingsService _settings;
  final AudioPlayer _player = AudioPlayer();

  /// Increments on every visual alert. The root widget watches this and paints
  /// a short full-screen pulse, which is visible even when the phone is muted.
  final ValueNotifier<int> flashPulse = ValueNotifier<int>(0);

  /// True while the emergency tone is looping.
  bool get alarmPlaying => _alarmPlaying;
  bool _alarmPlaying = false;

  /// Prepare the audio player. Failures are non-fatal.
  Future<void> initialize() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
    } catch (_) {
      // Audio output is optional; the other channels still work.
    }
  }

  /// React to a hazard.
  Future<void> react(AwarenessLevel level) async {
    switch (level) {
      case AwarenessLevel.danger:
        await _vibrate(<int>[0, 500, 180, 500, 180, 500]);
        _pulse();
      case AwarenessLevel.warning:
        await _vibrate(<int>[0, 220, 120, 220]);
        _pulse();
      case AwarenessLevel.info:
        break;
    }
  }

  /// Start the emergency tone and a repeating vibration.
  Future<void> startEmergency() async {
    if (_settings.soundAlertsEnabled) {
      try {
        if (!_alarmPlaying) {
          await _player.play(AssetSource('audio/alarm.wav'));
          _alarmPlaying = true;
        }
      } catch (_) {
        _alarmPlaying = false;
      }
    }
    await _vibrate(<int>[0, 800, 250, 800, 250, 800, 250, 800]);
    _pulse();
  }

  /// Stop the emergency tone.
  Future<void> stopEmergency() async {
    _alarmPlaying = false;
    try {
      await _player.stop();
    } catch (_) {
      // Nothing to stop.
    }
  }

  /// Short confirmation pulse for a direct action.
  Future<void> confirm() => _vibrate(<int>[0, 60]);

  /// Show one visual alert pulse.
  void pulse() => _pulse();

  Future<void> _vibrate(List<int> pattern) async {
    if (!_settings.hapticsEnabled) return;
    try {
      final has = await Vibration.hasVibrator();
      if (has == true) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (_) {
      // Desktop platforms have no vibrator; that is expected, not an error.
    }
  }

  void _pulse() {
    if (!_settings.flashEnabled) return;
    flashPulse.value = flashPulse.value + 1;
  }

  /// Release the audio player.
  Future<void> dispose() async {
    await stopEmergency();
    await _player.dispose();
    flashPulse.dispose();
  }
}
