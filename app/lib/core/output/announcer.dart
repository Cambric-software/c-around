import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../data/ca_database.dart';
import '../data/models.dart';
import '../output/alert_service.dart';
import '../output/tts_service.dart';
import '../settings/settings_service.dart';

/// The single place that decides what gets said, shown and felt.
///
/// Screens push observations here instead of calling text-to-speech directly.
/// That is what makes the cooldown, the "do not repeat the same sentence"
/// rule and the accessibility routing apply everywhere, rather than being
/// reimplemented - and forgotten - per screen.
class Announcer extends ChangeNotifier {
  Announcer({
    required this.settings,
    required this.tts,
    required this.alerts,
    required this.database,
  });

  /// User preferences.
  final SettingsService settings;

  /// Spoken output.
  final TtsService tts;

  /// Vibration and flash.
  final AlertService alerts;

  /// Event history.
  final CaDatabase database;

  final List<AwarenessEvent> _recent = <AwarenessEvent>[];
  final Map<String, DateTime> _lastSpoken = <String, DateTime>{};
  final Map<String, DateTime> _lastShown = <String, DateTime>{};

  /// Newest first, capped at forty entries.
  List<AwarenessEvent> get recent => List<AwarenessEvent>.unmodifiable(_recent);

  /// The last thing that was announced, useful for a large caption bar.
  AwarenessEvent? get latest => _recent.isEmpty ? null : _recent.first;

  /// Push an observation.
  ///
  /// [force] bypasses the cooldown for a direct user action such as "describe
  /// the scene"; background observations never set it.
  Future<void> announce({
    required String kind,
    required String message,
    required AwarenessLevel level,
    required String source,
    bool force = false,
    bool speak = true,
  }) async {
    final now = DateTime.now();
    final lastShown = _lastShown[kind];
    if (!force &&
        lastShown != null &&
        now.difference(lastShown).inMilliseconds < 1800) {
      return;
    }

    final event = AwarenessEvent(
      kind: kind,
      message: message,
      level: level,
      source: source,
      createdAt: now,
    );

    _recent.insert(0, event);
    if (_recent.length > 40) _recent.removeRange(40, _recent.length);
    _lastShown[kind] = now;

    final cooldown = Duration(
      seconds: level == AwarenessLevel.danger
          ? (settings.announceCooldownSeconds / 2).ceil().clamp(2, 30).toInt()
          : settings.announceCooldownSeconds,
    );
    final lastSpoken = _lastSpoken[kind];
    final maySpeak = force ||
        lastSpoken == null ||
        now.difference(lastSpoken) >= cooldown;

    final shouldSpeak = speak &&
        maySpeak &&
        settings.speechEnabled &&
        (level != AwarenessLevel.info || settings.announceInfo);

    if (shouldSpeak) {
      _lastSpoken[kind] = now;
      unawaited(
        tts.speak(
          message,
          interrupt: level == AwarenessLevel.danger || force,
        ),
      );
      unawaited(alerts.react(level));
    }

    // A screen reader gets the same sentence as a live region, so a user who
    // has TalkBack or Narrator running is not dependent on the app's own voice.
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      unawaited(
        SemanticsService.sendAnnouncement(view, message, TextDirection.ltr),
      );
    }

    if (level != AwarenessLevel.info || shouldSpeak) {
      unawaited(database.insertEvent(event));
    }

    notifyListeners();
  }

  /// Speak a sentence the user asked for, without treating it as a hazard.
  Future<void> speakDirect(String text, {bool interrupt = true}) async {
    await announce(
      kind: 'direct',
      message: text,
      level: AwarenessLevel.info,
      source: 'user',
      force: true,
      speak: true,
    );
  }

  /// Clear the on-screen feed. History in the database is untouched.
  void clearFeed() {
    _recent.clear();
    _lastShown.clear();
    _lastSpoken.clear();
    notifyListeners();
  }
}
