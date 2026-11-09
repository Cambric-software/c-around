import 'package:cambric_app/core/ai/sound_events.dart';
import 'package:cambric_app/core/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('soundAlertFor', () {
    test('ignores labels below the confidence floor', () {
      expect(soundAlertFor('Smoke detector, smoke alarm', 0.17), isNull);
      expect(soundAlertFor('Siren', 0.0), isNull);
    });

    test('fire and smoke alarms are danger', () {
      for (final String label in <String>[
        'Smoke detector, smoke alarm',
        'Fire alarm',
      ]) {
        final alert = soundAlertFor(label, 0.6);
        expect(alert?.kind, 'fire_alarm');
        expect(alert?.level, AwarenessLevel.danger);
      }
    });

    test('maps the danger sounds', () {
      expect(soundAlertFor('Siren', 0.5)?.kind, 'siren');
      expect(soundAlertFor('Glass', 0.5)?.kind, 'glass');
      expect(soundAlertFor('Shatter', 0.5)?.kind, 'glass');
      expect(soundAlertFor('Gunshot, gunfire', 0.5)?.kind, 'gunshot');
      for (final String kind in <String>['siren', 'glass', 'gunshot']) {
        expect(soundAlertFor(kind, 0.5), isNotNull);
      }
    });

    test('maps warnings with the right severity', () {
      final cases = <String, String>{
        'Car horn, honking': 'horn',
        'Baby cry, infant cry': 'baby',
        'Dog': 'dog',
        'Bark': 'dog',
        'Screaming': 'shout',
        'Shout': 'shout',
        'Alarm clock': 'alarm_clock',
      };
      cases.forEach((String label, String kind) {
        final alert = soundAlertFor(label, 0.4);
        expect(alert?.kind, kind, reason: label);
        expect(alert?.level, AwarenessLevel.warning, reason: label);
      });
    });

    test('maps notices as info', () {
      for (final String label in <String>['Thunder', 'Doorbell', 'Knock']) {
        final alert = soundAlertFor(label, 0.4);
        expect(alert, isNotNull, reason: label);
        expect(alert?.level, AwarenessLevel.info, reason: label);
      }
    });

    test('does not invent alerts for unmapped classes', () {
      for (final String label in <String>[
        'Speech',
        'Music',
        'Silence',
        'Inside, small room',
      ]) {
        expect(soundAlertFor(label, 0.99), isNull, reason: label);
      }
    });

    test('matching is case-insensitive', () {
      expect(soundAlertFor('SMOKE ALARM', 0.9)?.kind, 'fire_alarm');
      expect(soundAlertFor('car HORN', 0.9)?.kind, 'horn');
    });
  });
}
