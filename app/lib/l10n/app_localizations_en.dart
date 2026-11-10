// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'C Around';

  @override
  String get navAround => 'Around';

  @override
  String get navTalk => 'Talk';

  @override
  String get navPeople => 'People';

  @override
  String get navNavigate => 'Navigate';

  @override
  String get navEmergency => 'Emergency';

  @override
  String get navSettings => 'Settings';

  @override
  String get aroundTitle => 'C Around';

  @override
  String get aroundStart => 'Start';

  @override
  String get aroundStop => 'Stop';

  @override
  String get aroundDescribeScene => 'Describe scene';

  @override
  String get aroundReadText => 'Read text';

  @override
  String get aroundAsk => 'Ask a question';

  @override
  String get aroundSoundMonitor => 'Sound monitor';

  @override
  String get aroundNoCamera => 'Camera not available';

  @override
  String get aroundScanningHint => 'Scanning for hazards…';

  @override
  String get aroundHazardsNone => 'No hazards detected';

  @override
  String get talkTitle => 'Talk';

  @override
  String get talkQuickPhrases => 'Quick phrases';

  @override
  String get talkAllPhrases => 'All phrases';

  @override
  String get talkAddPhrase => 'Add phrase';

  @override
  String get talkSpeak => 'Speak';

  @override
  String get talkTypeHere => 'Type something…';

  @override
  String get talkCaptionsTitle => 'Live captions';

  @override
  String get talkCaptionsEmpty =>
      'Nothing transcribed yet. Tap Start to begin.';

  @override
  String get talkCaptionsStart => 'Start captions';

  @override
  String get talkCaptionsStop => 'Stop captions';

  @override
  String get talkCaptionsClear => 'Clear history';

  @override
  String get peopleTitle => 'People';

  @override
  String get peopleAdd => 'Enrol person';

  @override
  String get peopleEmpty => 'No one enrolled yet.\nTap + to add someone.';

  @override
  String get peopleName => 'Name';

  @override
  String get peopleRelationship => 'Relationship';

  @override
  String get peopleDelete => 'Remove';

  @override
  String get peopleTakePhoto => 'Take photo';

  @override
  String get peoplePhotoRequired => 'A face photo is required';

  @override
  String get navigateTitle => 'Navigate';

  @override
  String get navigatePlaces => 'Saved places';

  @override
  String get navigateItems => 'Tracked items';

  @override
  String get navigateAddPlace => 'Add place';

  @override
  String get navigateAddItem => 'Add item';

  @override
  String get navigatePlacesEmpty => 'No saved places yet.';

  @override
  String get navigateItemsEmpty => 'No tracked items yet.';

  @override
  String get emergencyTitle => 'Emergency';

  @override
  String get emergencyMedicalCard => 'Medical card';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String emergencyCallContact(String name) {
    return 'Call $name';
  }

  @override
  String get emergencyShareCard => 'Share card';

  @override
  String get emergencyNoCard =>
      'No medical card set up. Go to Settings to add your information.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccessibility => 'Accessibility needs';

  @override
  String get settingsSpeech => 'Speech';

  @override
  String get settingsSpeechEnabled => 'Spoken output';

  @override
  String get settingsSpeechRate => 'Speech rate';

  @override
  String get settingsSpeechPitch => 'Speech pitch';

  @override
  String get settingsSpeechLanguage => 'Voice language';

  @override
  String get settingsHaptics => 'Vibration alerts';

  @override
  String get settingsFlash => 'Screen flash alerts';

  @override
  String get settingsSoundAlerts => 'Audio alerts';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsTextScale => 'Text size';

  @override
  String get settingsConfidence => 'Detection confidence';

  @override
  String get settingsCooldown => 'Announce cooldown (seconds)';

  @override
  String get settingsAnnounceInfo => 'Speak low-priority descriptions';

  @override
  String get settingsSpeakCards => 'Speak cards on tap';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsAppLockEnabled => 'Require PIN on launch';

  @override
  String get settingsChangePIN => 'Change PIN';

  @override
  String get settingsAutoUpdate => 'Automatic update checks';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get settingsDiagnosticsView => 'View diagnostic report';

  @override
  String get settingsClearDiagnostics => 'Clear diagnostics';

  @override
  String get settingsReplayOnboarding => 'Replay welcome';

  @override
  String get settingsMedicalCard => 'Medical card';

  @override
  String get settingsMedicalName => 'Name';

  @override
  String get settingsMedicalConditions => 'Conditions';

  @override
  String get settingsMedicalAllergies => 'Allergies';

  @override
  String get settingsMedicalMedications => 'Medications';

  @override
  String get settingsMedicalBloodType => 'Blood type';

  @override
  String get settingsContactName => 'Emergency contact name';

  @override
  String get settingsContactPhone => 'Emergency contact phone';

  @override
  String get onboardingWelcomeTitle => 'The world, explained.';

  @override
  String get onboardingWelcomeBody =>
      'C Around describes what is in front of you, names the people you know, reads signs aloud, and monitors sounds — all offline.';

  @override
  String get onboardingNeedsTitle => 'What do you need?';

  @override
  String get onboardingNeedsBody =>
      'Choose your accessibility needs. C Around adjusts its defaults. You can change everything later in Settings.';

  @override
  String get onboardingReadyTitle => 'Ready to go.';

  @override
  String get onboardingReadyBody =>
      'C Around is ready to use. The models for object detection and sound classification are already bundled.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Get started';

  @override
  String get needBlind => 'Blind';

  @override
  String get needLowVision => 'Low vision';

  @override
  String get needDeaf => 'Deaf';

  @override
  String get needHardOfHearing => 'Hard of hearing';

  @override
  String get needNonVerbal => 'Non-verbal';

  @override
  String get lockTitle => 'Enter PIN';

  @override
  String get lockHint => 'Enter your 6-digit PIN';

  @override
  String get lockError => 'Incorrect PIN';

  @override
  String lockLockedOut(int minutes) {
    return 'Too many attempts. Try again in $minutes minutes.';
  }

  @override
  String get lockForgot => 'Forgot PIN? Reset in Settings.';

  @override
  String get modelPacksTitle => 'Model packs';

  @override
  String get modelPacksInstalled => 'Installed';

  @override
  String get modelPacksNotInstalled => 'Not installed';

  @override
  String get modelPacksDownload => 'Download';

  @override
  String get modelPacksRemove => 'Remove';

  @override
  String get modelPacksDesktopOnly => 'Desktop only';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorNoCamera => 'Camera is not available on this device.';

  @override
  String get errorNoMicrophone => 'Microphone permission denied.';

  @override
  String get errorNoLocation => 'Location permission denied.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String get permissionDenied => 'Permission denied';
}
