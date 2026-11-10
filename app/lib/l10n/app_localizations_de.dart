// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'C Around';

  @override
  String get navAround => 'Umgebung';

  @override
  String get navTalk => 'Sprechen';

  @override
  String get navPeople => 'Personen';

  @override
  String get navNavigate => 'Navigation';

  @override
  String get navEmergency => 'Notfall';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get aroundTitle => 'C Around';

  @override
  String get aroundStart => 'Starten';

  @override
  String get aroundStop => 'Stoppen';

  @override
  String get aroundDescribeScene => 'Szene beschreiben';

  @override
  String get aroundReadText => 'Text lesen';

  @override
  String get aroundAsk => 'Frage stellen';

  @override
  String get aroundSoundMonitor => 'Soundüberwachung';

  @override
  String get aroundNoCamera => 'Kamera nicht verfügbar';

  @override
  String get aroundScanningHint => 'Suche nach Gefahren…';

  @override
  String get aroundHazardsNone => 'Keine Gefahren erkannt';

  @override
  String get talkTitle => 'Sprechen';

  @override
  String get talkQuickPhrases => 'Schnellphrasen';

  @override
  String get talkAllPhrases => 'Alle Phrasen';

  @override
  String get talkAddPhrase => 'Phrase hinzufügen';

  @override
  String get talkSpeak => 'Sprechen';

  @override
  String get talkTypeHere => 'Etwas eingeben…';

  @override
  String get talkCaptionsTitle => 'Live-Untertitel';

  @override
  String get talkCaptionsEmpty =>
      'Noch nichts transkribiert. Tippen Sie auf Starten.';

  @override
  String get talkCaptionsStart => 'Untertitel starten';

  @override
  String get talkCaptionsStop => 'Untertitel stoppen';

  @override
  String get talkCaptionsClear => 'Verlauf löschen';

  @override
  String get peopleTitle => 'Personen';

  @override
  String get peopleAdd => 'Person registrieren';

  @override
  String get peopleEmpty =>
      'Noch keine Personen registriert.\nTippen Sie auf +, um eine Person hinzuzufügen.';

  @override
  String get peopleName => 'Name';

  @override
  String get peopleRelationship => 'Beziehung';

  @override
  String get peopleDelete => 'Entfernen';

  @override
  String get peopleTakePhoto => 'Foto aufnehmen';

  @override
  String get peoplePhotoRequired => 'Ein Gesichtsfoto ist erforderlich';

  @override
  String get navigateTitle => 'Navigation';

  @override
  String get navigatePlaces => 'Gespeicherte Orte';

  @override
  String get navigateItems => 'Verfolgte Gegenstände';

  @override
  String get navigateAddPlace => 'Ort hinzufügen';

  @override
  String get navigateAddItem => 'Gegenstand hinzufügen';

  @override
  String get navigatePlacesEmpty => 'Noch keine gespeicherten Orte.';

  @override
  String get navigateItemsEmpty => 'Noch keine verfolgten Gegenstände.';

  @override
  String get emergencyTitle => 'Notfall';

  @override
  String get emergencyMedicalCard => 'Medizinische Karte';

  @override
  String get emergencyContact => 'Notfallkontakt';

  @override
  String emergencyCallContact(String name) {
    return '$name anrufen';
  }

  @override
  String get emergencyShareCard => 'Karte teilen';

  @override
  String get emergencyNoCard =>
      'Keine medizinische Karte eingerichtet. Gehen Sie zu den Einstellungen, um Ihre Informationen hinzuzufügen.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAccessibility => 'Barrierefreiheitsbedürfnisse';

  @override
  String get settingsSpeech => 'Sprache';

  @override
  String get settingsSpeechEnabled => 'Sprachausgabe';

  @override
  String get settingsSpeechRate => 'Sprechgeschwindigkeit';

  @override
  String get settingsSpeechPitch => 'Stimmhöhe';

  @override
  String get settingsSpeechLanguage => 'Stimmensprache';

  @override
  String get settingsHaptics => 'Vibrationsalarme';

  @override
  String get settingsFlash => 'Bildschirmblitz-Alarme';

  @override
  String get settingsSoundAlerts => 'Audioalarme';

  @override
  String get settingsHighContrast => 'Hoher Kontrast';

  @override
  String get settingsTextScale => 'Textgröße';

  @override
  String get settingsConfidence => 'Erkennungsschwelle';

  @override
  String get settingsCooldown => 'Durchsageabstand (Sekunden)';

  @override
  String get settingsAnnounceInfo =>
      'Niedrig-Priorität-Beschreibungen sprechen';

  @override
  String get settingsSpeakCards => 'Karten beim Tippen sprechen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsAppLock => 'App-Sperre';

  @override
  String get settingsAppLockEnabled => 'PIN beim Start verlangen';

  @override
  String get settingsChangePIN => 'PIN ändern';

  @override
  String get settingsAutoUpdate => 'Automatische Update-Prüfung';

  @override
  String get settingsDiagnostics => 'Diagnose';

  @override
  String get settingsDiagnosticsView => 'Diagnosebericht anzeigen';

  @override
  String get settingsClearDiagnostics => 'Diagnose löschen';

  @override
  String get settingsReplayOnboarding => 'Willkommen wiederholen';

  @override
  String get settingsMedicalCard => 'Medizinische Karte';

  @override
  String get settingsMedicalName => 'Name';

  @override
  String get settingsMedicalConditions => 'Erkrankungen';

  @override
  String get settingsMedicalAllergies => 'Allergien';

  @override
  String get settingsMedicalMedications => 'Medikamente';

  @override
  String get settingsMedicalBloodType => 'Blutgruppe';

  @override
  String get settingsContactName => 'Name des Notfallkontakts';

  @override
  String get settingsContactPhone => 'Telefon des Notfallkontakts';

  @override
  String get onboardingWelcomeTitle => 'Die Welt, erklärt.';

  @override
  String get onboardingWelcomeBody =>
      'C Around beschreibt, was vor Ihnen liegt, nennt die Personen, die Sie kennen, liest Schilder vor und überwacht Geräusche — alles offline.';

  @override
  String get onboardingNeedsTitle => 'Was brauchen Sie?';

  @override
  String get onboardingNeedsBody =>
      'Wählen Sie Ihre Barrierefreiheitsbedürfnisse. C Around passt die Standardeinstellungen an. Sie können alles später in den Einstellungen ändern.';

  @override
  String get onboardingReadyTitle => 'Bereit zur Nutzung.';

  @override
  String get onboardingReadyBody =>
      'C Around ist einsatzbereit. Die Modelle für Objekterkennung und Soundklassifizierung sind bereits eingebunden.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingFinish => 'Loslegen';

  @override
  String get needBlind => 'Blind';

  @override
  String get needLowVision => 'Sehbehindert';

  @override
  String get needDeaf => 'Gehörlos';

  @override
  String get needHardOfHearing => 'Schwerhörig';

  @override
  String get needNonVerbal => 'Nicht verbal';

  @override
  String get lockTitle => 'PIN eingeben';

  @override
  String get lockHint => 'Geben Sie Ihren 6-stelligen PIN ein';

  @override
  String get lockError => 'Falscher PIN';

  @override
  String lockLockedOut(int minutes) {
    return 'Zu viele Versuche. Versuchen Sie es in $minutes Minuten erneut.';
  }

  @override
  String get lockForgot => 'PIN vergessen? In den Einstellungen zurücksetzen.';

  @override
  String get modelPacksTitle => 'Modellpakete';

  @override
  String get modelPacksInstalled => 'Installiert';

  @override
  String get modelPacksNotInstalled => 'Nicht installiert';

  @override
  String get modelPacksDownload => 'Herunterladen';

  @override
  String get modelPacksRemove => 'Entfernen';

  @override
  String get modelPacksDesktopOnly => 'Nur Desktop';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen.';

  @override
  String get errorNoCamera => 'Kamera ist auf diesem Gerät nicht verfügbar.';

  @override
  String get errorNoMicrophone => 'Mikrofonberechtigung verweigert.';

  @override
  String get errorNoLocation => 'Standortberechtigung verweigert.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get close => 'Schließen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get loading => 'Laden…';

  @override
  String get permissionRequired => 'Berechtigung erforderlich';

  @override
  String get permissionDenied => 'Berechtigung verweigert';
}
