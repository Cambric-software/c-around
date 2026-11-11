import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import '../settings/settings_service.dart';

/// Spoken output.
///
/// Android and Windows use the platform voice through `flutter_tts`. Linux has
/// no implementation in that plugin, so it falls back to `spd-say` when speech
/// dispatcher is installed; if neither exists the app says so in Settings
/// rather than pretending a sentence was spoken.
class TtsService {
  TtsService(this._settings);

  final SettingsService _settings;
  FlutterTts? _ttsInstance;
  FlutterTts get _tts => _ttsInstance ??= FlutterTts();

  bool _ready = false;
  bool _linuxFallback = false;
  String? _error;

  /// True when a voice is available.
  bool get isAvailable => _ready;

  /// Why speech is unavailable, if it is.
  String? get error => _error;

  /// True when speech is enabled in settings.
  bool get enabled => _settings.speechEnabled;

  /// Prepare the voice. Safe to call once at startup.
  Future<void> initialize() async {
    if (Platform.isLinux) {
      _linuxFallback = await _commandExists('spd-say');
      _ready = _linuxFallback;
      if (!_ready) {
        _error = 'Install speech-dispatcher (spd-say) to enable spoken output.';
      }
      return;
    }

    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(_settings.speechRate);
      await _tts.setPitch(_settings.speechPitch);
      final languages = await _tts.getLanguages;
      if (languages is List && languages.isNotEmpty) {
        final available =
            languages.map((Object? value) => value.toString()).toList();
        final wanted = _settings.speechLanguage.toLowerCase();
        final match = available.firstWhere(
          (String value) =>
              value.toLowerCase() == wanted ||
              value.toLowerCase().startsWith(wanted.split('-').first),
          orElse: () => available.first,
        );
        await _tts.setLanguage(match);
      }
      _ready = true;
      _error = null;
    } catch (error) {
      _ready = false;
      _error = error.toString();
    }
  }

  /// Speak [text]. Returns true when the sentence was handed to a voice.
  ///
  /// [interrupt] stops anything already speaking. Emergencies and direct user
  /// actions use it; background awareness does not, so a warning is not cut off
  /// by the next harmless observation.
  Future<bool> speak(String text, {bool interrupt = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_settings.speechEnabled || !_ready) return false;

    try {
      if (_linuxFallback) {
        await Process.run('spd-say', <String>['-w', trimmed]);
        return true;
      }
      if (interrupt) {
        await _tts.stop();
      }
      await _tts.setSpeechRate(_settings.speechRate);
      await _tts.setPitch(_settings.speechPitch);
      final result = await _tts.speak(trimmed);
      return result == 1 || result == true;
    } catch (error) {
      _error = error.toString();
      return false;
    }
  }

  /// Stop speaking.
  Future<void> stop() async {
    try {
      if (_linuxFallback) {
        await Process.run('spd-say', <String>['-C']);
      } else {
        await _tts.stop();
      }
    } catch (_) {
      // Stopping is best effort; there is nothing useful to show the user.
    }
  }

  /// Refresh rate, pitch and language after a settings change.
  Future<void> applySettings() async {
    if (!_ready || _linuxFallback) return;
    try {
      await _tts.setSpeechRate(_settings.speechRate);
      await _tts.setPitch(_settings.speechPitch);
      await _tts.setLanguage(_settings.speechLanguage);
    } catch (error) {
      _error = error.toString();
    }
  }

  /// Speak a sample so the user can judge rate and pitch.
  Future<void> preview() async {
    await speak(
      'This is how C Around will sound. Stairs ahead, two steps down.',
      interrupt: true,
    );
  }

  /// Voices reported by the platform, for the settings picker.
  Future<List<String>> languages() async {
    if (_linuxFallback) {
      return const <String>['en', 'ar'];
    }
    try {
      final value = await _tts.getLanguages;
      if (value is List) {
        return value.map((Object? item) => item.toString()).toList()..sort();
      }
    } catch (error) {
      _error = error.toString();
    }
    return const <String>[];
  }

  static Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        <String>[command],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Which speech backend is in use, shown in Settings.
  String get backend => _linuxFallback ? 'spd-say' : 'flutter_tts';
}
