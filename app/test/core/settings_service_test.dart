import 'package:cambric_app/core/settings/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsService> loaded([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final service = SettingsService(prefs);
  await service.load();
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults are safe for a first launch', () async {
    final settings = await loaded();
    expect(settings.needs, isEmpty);
    expect(settings.speechEnabled, isTrue);
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.flashEnabled, isTrue);
    expect(settings.soundAlertsEnabled, isTrue);
    expect(settings.highContrast, isFalse);
    expect(settings.textScale, 1.0);
    expect(settings.detectionConfidence, 0.45);
    expect(settings.announceCooldownSeconds, 6);
    expect(settings.onboardingComplete, isFalse);
    expect(settings.speechLanguage, 'en-US');
  });

  test('blind defaults turn on speech, haptics and larger text', () async {
    final settings = await loaded();
    await settings.setNeeds(<AccessibilityNeed>{AccessibilityNeed.blind});
    expect(settings.isBlind, isTrue);
    expect(settings.speechEnabled, isTrue);
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.textScale, greaterThanOrEqualTo(1.2));
  });

  test('low vision defaults turn on contrast and larger text', () async {
    final settings = await loaded();
    await settings.setNeeds(<AccessibilityNeed>{AccessibilityNeed.lowVision});
    expect(settings.isLowVision, isTrue);
    expect(settings.highContrast, isTrue);
    expect(settings.textScale, greaterThanOrEqualTo(1.25));
  });

  test('deaf defaults prefer flash and vibration over sound', () async {
    final settings = await loaded();
    await settings.setNeeds(<AccessibilityNeed>{AccessibilityNeed.deaf});
    expect(settings.isDeafOrHardOfHearing, isTrue);
    expect(settings.flashEnabled, isTrue);
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.soundAlertsEnabled, isFalse);
  });

  test('needs persist and reload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final first = SettingsService(prefs);
    await first.load();
    await first.setNeeds(<AccessibilityNeed>{
      AccessibilityNeed.hardOfHearing,
      AccessibilityNeed.nonVerbal,
    });
    await first.setOnboardingComplete(true);

    final second = SettingsService(prefs);
    await second.load();
    expect(second.needs, contains(AccessibilityNeed.hardOfHearing));
    expect(second.needs, contains(AccessibilityNeed.nonVerbal));
    expect(second.onboardingComplete, isTrue);
  });

  test('sliders clamp to their documented range', () async {
    final settings = await loaded();
    await settings.setSpeechRate(9);
    expect(settings.speechRate, 1.0);
    await settings.setSpeechRate(-1);
    expect(settings.speechRate, 0.2);

    await settings.setSpeechPitch(9);
    expect(settings.speechPitch, 2.0);
    await settings.setSpeechPitch(0);
    expect(settings.speechPitch, 0.5);

    await settings.setTextScale(9);
    expect(settings.textScale, 2.0);
    await settings.setTextScale(0);
    expect(settings.textScale, 0.9);

    await settings.setDetectionConfidence(0);
    expect(settings.detectionConfidence, 0.2);
    await settings.setDetectionConfidence(1);
    expect(settings.detectionConfidence, 0.9);

    await settings.setAnnounceCooldown(0);
    expect(settings.announceCooldownSeconds, 2);
    await settings.setAnnounceCooldown(99);
    expect(settings.announceCooldownSeconds, 30);
  });

  test('medical card and contact are trimmed and persisted', () async {
    final settings = await loaded();
    await settings.setMedicalCard(
      name: '  Asser  ',
      conditions: 'Asthma',
      allergies: 'Penicillin',
      medications: 'Inhaler',
      bloodType: 'O+',
    );
    expect(settings.medicalName, 'Asser');
    expect(settings.hasMedicalCard, isTrue);

    await settings.setEmergencyContact(name: ' Mariam ', phone: ' 0100 ');
    expect(settings.contactName, 'Mariam');
    expect(settings.contactPhone, '0100');
  });
}
