import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('fr')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'C Around'**
  String get appName;

  /// No description provided for @navAround.
  ///
  /// In en, this message translates to:
  /// **'Around'**
  String get navAround;

  /// No description provided for @navTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get navTalk;

  /// No description provided for @navPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get navPeople;

  /// No description provided for @navNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navNavigate;

  /// No description provided for @navEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get navEmergency;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @aroundTitle.
  ///
  /// In en, this message translates to:
  /// **'C Around'**
  String get aroundTitle;

  /// No description provided for @aroundStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get aroundStart;

  /// No description provided for @aroundStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get aroundStop;

  /// No description provided for @aroundDescribeScene.
  ///
  /// In en, this message translates to:
  /// **'Describe scene'**
  String get aroundDescribeScene;

  /// No description provided for @aroundReadText.
  ///
  /// In en, this message translates to:
  /// **'Read text'**
  String get aroundReadText;

  /// No description provided for @aroundAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get aroundAsk;

  /// No description provided for @aroundSoundMonitor.
  ///
  /// In en, this message translates to:
  /// **'Sound monitor'**
  String get aroundSoundMonitor;

  /// No description provided for @aroundNoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get aroundNoCamera;

  /// No description provided for @aroundScanningHint.
  ///
  /// In en, this message translates to:
  /// **'Scanning for hazards…'**
  String get aroundScanningHint;

  /// No description provided for @aroundHazardsNone.
  ///
  /// In en, this message translates to:
  /// **'No hazards detected'**
  String get aroundHazardsNone;

  /// No description provided for @talkTitle.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get talkTitle;

  /// No description provided for @talkQuickPhrases.
  ///
  /// In en, this message translates to:
  /// **'Quick phrases'**
  String get talkQuickPhrases;

  /// No description provided for @talkAllPhrases.
  ///
  /// In en, this message translates to:
  /// **'All phrases'**
  String get talkAllPhrases;

  /// No description provided for @talkAddPhrase.
  ///
  /// In en, this message translates to:
  /// **'Add phrase'**
  String get talkAddPhrase;

  /// No description provided for @talkSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get talkSpeak;

  /// No description provided for @talkTypeHere.
  ///
  /// In en, this message translates to:
  /// **'Type something…'**
  String get talkTypeHere;

  /// No description provided for @talkCaptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live captions'**
  String get talkCaptionsTitle;

  /// No description provided for @talkCaptionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing transcribed yet. Tap Start to begin.'**
  String get talkCaptionsEmpty;

  /// No description provided for @talkCaptionsStart.
  ///
  /// In en, this message translates to:
  /// **'Start captions'**
  String get talkCaptionsStart;

  /// No description provided for @talkCaptionsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop captions'**
  String get talkCaptionsStop;

  /// No description provided for @talkCaptionsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get talkCaptionsClear;

  /// No description provided for @peopleTitle.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleTitle;

  /// No description provided for @peopleAdd.
  ///
  /// In en, this message translates to:
  /// **'Enrol person'**
  String get peopleAdd;

  /// No description provided for @peopleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one enrolled yet.\nTap + to add someone.'**
  String get peopleEmpty;

  /// No description provided for @peopleName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get peopleName;

  /// No description provided for @peopleRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get peopleRelationship;

  /// No description provided for @peopleDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get peopleDelete;

  /// No description provided for @peopleTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get peopleTakePhoto;

  /// No description provided for @peoplePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'A face photo is required'**
  String get peoplePhotoRequired;

  /// No description provided for @navigateTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigateTitle;

  /// No description provided for @navigatePlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get navigatePlaces;

  /// No description provided for @navigateItems.
  ///
  /// In en, this message translates to:
  /// **'Tracked items'**
  String get navigateItems;

  /// No description provided for @navigateAddPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get navigateAddPlace;

  /// No description provided for @navigateAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get navigateAddItem;

  /// No description provided for @navigatePlacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet.'**
  String get navigatePlacesEmpty;

  /// No description provided for @navigateItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tracked items yet.'**
  String get navigateItemsEmpty;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyTitle;

  /// No description provided for @emergencyMedicalCard.
  ///
  /// In en, this message translates to:
  /// **'Medical card'**
  String get emergencyMedicalCard;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @emergencyCallContact.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String emergencyCallContact(String name);

  /// No description provided for @emergencyShareCard.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get emergencyShareCard;

  /// No description provided for @emergencyNoCard.
  ///
  /// In en, this message translates to:
  /// **'No medical card set up. Go to Settings to add your information.'**
  String get emergencyNoCard;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility needs'**
  String get settingsAccessibility;

  /// No description provided for @settingsSpeech.
  ///
  /// In en, this message translates to:
  /// **'Speech'**
  String get settingsSpeech;

  /// No description provided for @settingsSpeechEnabled.
  ///
  /// In en, this message translates to:
  /// **'Spoken output'**
  String get settingsSpeechEnabled;

  /// No description provided for @settingsSpeechRate.
  ///
  /// In en, this message translates to:
  /// **'Speech rate'**
  String get settingsSpeechRate;

  /// No description provided for @settingsSpeechPitch.
  ///
  /// In en, this message translates to:
  /// **'Speech pitch'**
  String get settingsSpeechPitch;

  /// No description provided for @settingsSpeechLanguage.
  ///
  /// In en, this message translates to:
  /// **'Voice language'**
  String get settingsSpeechLanguage;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration alerts'**
  String get settingsHaptics;

  /// No description provided for @settingsFlash.
  ///
  /// In en, this message translates to:
  /// **'Screen flash alerts'**
  String get settingsFlash;

  /// No description provided for @settingsSoundAlerts.
  ///
  /// In en, this message translates to:
  /// **'Audio alerts'**
  String get settingsSoundAlerts;

  /// No description provided for @settingsHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get settingsHighContrast;

  /// No description provided for @settingsTextScale.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextScale;

  /// No description provided for @settingsConfidence.
  ///
  /// In en, this message translates to:
  /// **'Detection confidence'**
  String get settingsConfidence;

  /// No description provided for @settingsCooldown.
  ///
  /// In en, this message translates to:
  /// **'Announce cooldown (seconds)'**
  String get settingsCooldown;

  /// No description provided for @settingsAnnounceInfo.
  ///
  /// In en, this message translates to:
  /// **'Speak low-priority descriptions'**
  String get settingsAnnounceInfo;

  /// No description provided for @settingsSpeakCards.
  ///
  /// In en, this message translates to:
  /// **'Speak cards on tap'**
  String get settingsSpeakCards;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Require PIN on launch'**
  String get settingsAppLockEnabled;

  /// No description provided for @settingsChangePIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsChangePIN;

  /// No description provided for @settingsAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Automatic update checks'**
  String get settingsAutoUpdate;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @settingsDiagnosticsView.
  ///
  /// In en, this message translates to:
  /// **'View diagnostic report'**
  String get settingsDiagnosticsView;

  /// No description provided for @settingsClearDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Clear diagnostics'**
  String get settingsClearDiagnostics;

  /// No description provided for @settingsReplayOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay welcome'**
  String get settingsReplayOnboarding;

  /// No description provided for @settingsMedicalCard.
  ///
  /// In en, this message translates to:
  /// **'Medical card'**
  String get settingsMedicalCard;

  /// No description provided for @settingsMedicalName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsMedicalName;

  /// No description provided for @settingsMedicalConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get settingsMedicalConditions;

  /// No description provided for @settingsMedicalAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get settingsMedicalAllergies;

  /// No description provided for @settingsMedicalMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get settingsMedicalMedications;

  /// No description provided for @settingsMedicalBloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get settingsMedicalBloodType;

  /// No description provided for @settingsContactName.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact name'**
  String get settingsContactName;

  /// No description provided for @settingsContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact phone'**
  String get settingsContactPhone;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'The world, explained.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'C Around describes what is in front of you, names the people you know, reads signs aloud, and monitors sounds — all offline.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get onboardingNeedsTitle;

  /// No description provided for @onboardingNeedsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your accessibility needs. C Around adjusts its defaults. You can change everything later in Settings.'**
  String get onboardingNeedsBody;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to go.'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'C Around is ready to use. The models for object detection and sound classification are already bundled.'**
  String get onboardingReadyBody;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingFinish;

  /// No description provided for @needBlind.
  ///
  /// In en, this message translates to:
  /// **'Blind'**
  String get needBlind;

  /// No description provided for @needLowVision.
  ///
  /// In en, this message translates to:
  /// **'Low vision'**
  String get needLowVision;

  /// No description provided for @needDeaf.
  ///
  /// In en, this message translates to:
  /// **'Deaf'**
  String get needDeaf;

  /// No description provided for @needHardOfHearing.
  ///
  /// In en, this message translates to:
  /// **'Hard of hearing'**
  String get needHardOfHearing;

  /// No description provided for @needNonVerbal.
  ///
  /// In en, this message translates to:
  /// **'Non-verbal'**
  String get needNonVerbal;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get lockTitle;

  /// No description provided for @lockHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit PIN'**
  String get lockHint;

  /// No description provided for @lockError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get lockError;

  /// No description provided for @lockLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {minutes} minutes.'**
  String lockLockedOut(int minutes);

  /// No description provided for @lockForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN? Reset in Settings.'**
  String get lockForgot;

  /// No description provided for @modelPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Model packs'**
  String get modelPacksTitle;

  /// No description provided for @modelPacksInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get modelPacksInstalled;

  /// No description provided for @modelPacksNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get modelPacksNotInstalled;

  /// No description provided for @modelPacksDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get modelPacksDownload;

  /// No description provided for @modelPacksRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get modelPacksRemove;

  /// No description provided for @modelPacksDesktopOnly.
  ///
  /// In en, this message translates to:
  /// **'Desktop only'**
  String get modelPacksDesktopOnly;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorNoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera is not available on this device.'**
  String get errorNoCamera;

  /// No description provided for @errorNoMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied.'**
  String get errorNoMicrophone;

  /// No description provided for @errorNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get errorNoLocation;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
