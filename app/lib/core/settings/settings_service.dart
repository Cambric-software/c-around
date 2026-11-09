import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The accessibility needs a person can select.
///
/// These are not a diagnosis and they are not exclusive: someone can be hard of
/// hearing and non-verbal. The app uses them to decide which outputs are on by
/// default, then the user can override every one.
enum AccessibilityNeed {
  /// Cannot see the screen; speech and haptics carry the interface.
  blind('blind', 'Blind'),

  /// Can see, but needs larger text and stronger contrast.
  lowVision('low_vision', 'Low vision'),

  /// Cannot hear sound alerts; vibration, flash and text carry them.
  deaf('deaf', 'Deaf'),

  /// Hears some sound, but not reliably.
  hardOfHearing('hard_of_hearing', 'Hard of hearing'),

  /// Speaks with text-to-speech or cards.
  nonVerbal('non_verbal', 'Non-verbal');

  const AccessibilityNeed(this.key, this.label);

  /// Stable key stored on disk.
  final String key;

  /// Human label.
  final String label;
}

/// All user preferences, persisted locally.
///
/// One object owns every preference so a screen cannot invent a key that only
/// it knows about. Setters write immediately and notify listeners; a failed
/// write is reported through [lastWriteError] rather than silently pretending
/// the choice was saved.
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  /// Last persistence error, if any. Shown in diagnostics.
  String? lastWriteError;

  static const String _kNeeds = 'needs';
  static const String _kSpeech = 'speech_enabled';
  static const String _kSpeechRate = 'speech_rate';
  static const String _kSpeechPitch = 'speech_pitch';
  static const String _kSpeechLanguage = 'speech_language';
  static const String _kHaptics = 'haptics_enabled';
  static const String _kFlash = 'flash_enabled';
  static const String _kSoundAlerts = 'sound_alerts_enabled';
  static const String _kHighContrast = 'high_contrast';
  static const String _kTextScale = 'text_scale';
  static const String _kConfidence = 'detection_confidence';
  static const String _kCooldown = 'announce_cooldown_seconds';
  static const String _kOnboarding = 'onboarding_complete';
  static const String _kMedicalName = 'medical_name';
  static const String _kMedicalConditions = 'medical_conditions';
  static const String _kMedicalAllergies = 'medical_allergies';
  static const String _kMedicalMedications = 'medical_medications';
  static const String _kMedicalBloodType = 'medical_blood_type';
  static const String _kContactName = 'contact_name';
  static const String _kContactPhone = 'contact_phone';
  static const String _kAnnounceInfo = 'announce_info';
  static const String _kSpeakCards = 'speak_cards';
  static const String _kThemeMode = 'theme_mode';
  static const String _kAutoUpdateCheck = 'auto_update_check';
  static const String _kAppLockEnabled = 'app_lock_enabled';
  static const String _kFeatureFlags = 'feature_flags';

  Set<AccessibilityNeed> _needs = <AccessibilityNeed>{};
  bool _speechEnabled = true;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  String _speechLanguage = 'en-US';
  bool _hapticsEnabled = true;
  bool _flashEnabled = true;
  bool _soundAlertsEnabled = true;
  bool _highContrast = false;
  double _textScale = 1.0;
  double _detectionConfidence = 0.45;
  int _announceCooldownSeconds = 6;
  bool _onboardingComplete = false;
  bool _announceInfo = true;
  bool _speakCards = true;
  String _themeMode = 'system';
  bool _autoUpdateCheck = true;
  bool _appLockEnabled = false;
  Map<String, bool> _featureFlags = const {};

  String _medicalName = '';
  String _medicalConditions = '';
  String _medicalAllergies = '';
  String _medicalMedications = '';
  String _medicalBloodType = '';
  String _contactName = '';
  String _contactPhone = '';

  /// Load every value from disk. Safe to call once at startup.
  Future<void> load() async {
    final stored = _prefs.getStringList(_kNeeds) ?? const <String>[];
    _needs = AccessibilityNeed.values
        .where((AccessibilityNeed need) => stored.contains(need.key))
        .toSet();

    _speechEnabled = _prefs.getBool(_kSpeech) ?? true;
    _speechRate = _prefs.getDouble(_kSpeechRate) ?? 0.5;
    _speechPitch = _prefs.getDouble(_kSpeechPitch) ?? 1.0;
    _speechLanguage = _prefs.getString(_kSpeechLanguage) ?? 'en-US';
    _hapticsEnabled = _prefs.getBool(_kHaptics) ?? true;
    _flashEnabled = _prefs.getBool(_kFlash) ?? true;
    _soundAlertsEnabled = _prefs.getBool(_kSoundAlerts) ?? true;
    _highContrast = _prefs.getBool(_kHighContrast) ?? false;
    _textScale = _prefs.getDouble(_kTextScale) ?? 1.0;
    _detectionConfidence = _prefs.getDouble(_kConfidence) ?? 0.45;
    _announceCooldownSeconds = _prefs.getInt(_kCooldown) ?? 6;
    _onboardingComplete = _prefs.getBool(_kOnboarding) ?? false;
    _announceInfo = _prefs.getBool(_kAnnounceInfo) ?? true;
    _speakCards = _prefs.getBool(_kSpeakCards) ?? true;
    _themeMode = _prefs.getString(_kThemeMode) ?? 'system';
    _autoUpdateCheck = _prefs.getBool(_kAutoUpdateCheck) ?? true;
    _appLockEnabled = _prefs.getBool(_kAppLockEnabled) ?? false;
    final flagsJson = _prefs.getString(_kFeatureFlags);
    if (flagsJson != null) {
      final decoded = jsonDecode(flagsJson);
      if (decoded is Map<String, dynamic>) {
        _featureFlags = Map<String, bool>.from(decoded);
      }
    }

    _medicalName = _prefs.getString(_kMedicalName) ?? '';
    _medicalConditions = _prefs.getString(_kMedicalConditions) ?? '';
    _medicalAllergies = _prefs.getString(_kMedicalAllergies) ?? '';
    _medicalMedications = _prefs.getString(_kMedicalMedications) ?? '';
    _medicalBloodType = _prefs.getString(_kMedicalBloodType) ?? '';
    _contactName = _prefs.getString(_kContactName) ?? '';
    _contactPhone = _prefs.getString(_kContactPhone) ?? '';

    notifyListeners();
  }

  /// The selected needs.
  Set<AccessibilityNeed> get needs => Set<AccessibilityNeed>.unmodifiable(_needs);

  /// True when the user asked for a blind-first interface.
  bool get isBlind => _needs.contains(AccessibilityNeed.blind);

  /// True when the user asked for large text and strong contrast defaults.
  bool get isLowVision => _needs.contains(AccessibilityNeed.lowVision);

  /// True when sound alone is not a reliable alert.
  bool get isDeafOrHardOfHearing =>
      _needs.contains(AccessibilityNeed.deaf) ||
      _needs.contains(AccessibilityNeed.hardOfHearing);

  /// True when the user communicates with cards or speech output.
  bool get isNonVerbal => _needs.contains(AccessibilityNeed.nonVerbal);

  /// Whether spoken output is enabled.
  bool get speechEnabled => _speechEnabled;

  /// Speech rate, 0.2 to 1.0.
  double get speechRate => _speechRate;

  /// Speech pitch, 0.5 to 2.0.
  double get speechPitch => _speechPitch;

  /// BCP-47 language tag for the voice.
  String get speechLanguage => _speechLanguage;

  /// Vibration on alerts.
  bool get hapticsEnabled => _hapticsEnabled;

  /// Screen flash on alerts.
  bool get flashEnabled => _flashEnabled;

  /// Audible emergency tone.
  bool get soundAlertsEnabled => _soundAlertsEnabled;

  /// High-contrast palette.
  bool get highContrast => _highContrast;

  /// Multiplier applied to every text size.
  double get textScale => _textScale;

  /// Minimum detector score before something is announced.
  double get detectionConfidence => _detectionConfidence;

  /// Minimum gap between two announcements of the same kind.
  int get announceCooldownSeconds => _announceCooldownSeconds;

  /// Whether the first-run flow has been completed.
  bool get onboardingComplete => _onboardingComplete;

  /// Whether low-priority descriptions are spoken as well as shown.
  bool get announceInfo => _announceInfo;

  /// Whether quick cards speak when tapped.
  bool get speakCards => _speakCards;

  /// `system`, `light` or `dark`.
  String get themeMode => _themeMode;

  /// Whether automatic update checks are enabled.
  bool get autoUpdateCheck => _autoUpdateCheck;

  /// Whether app lock (PIN) is enabled.
  bool get appLockEnabled => _appLockEnabled;

  /// Feature flags state.
  Map<String, bool> get featureFlags => Map<String, bool>.unmodifiable(_featureFlags);

  /// Name for the emergency card.
  String get medicalName => _medicalName;

  /// Conditions responders should know about.
  String get medicalConditions => _medicalConditions;

  /// Allergies.
  String get medicalAllergies => _medicalAllergies;

  /// Current medication.
  String get medicalMedications => _medicalMedications;

  /// Blood type.
  String get medicalBloodType => _medicalBloodType;

  /// Emergency contact name.
  String get contactName => _contactName;

  /// Emergency contact phone number.
  String get contactPhone => _contactPhone;

  /// True when there is enough on the medical card to be useful.
  bool get hasMedicalCard =>
      _medicalName.isNotEmpty ||
      _medicalConditions.isNotEmpty ||
      _medicalAllergies.isNotEmpty ||
      _medicalMedications.isNotEmpty ||
      _contactPhone.isNotEmpty;

  /// Replace the selected needs. Selecting a need applies its sensible
  /// defaults once, without overwriting a choice the user made afterwards.
  Future<void> setNeeds(Set<AccessibilityNeed> needs) async {
    final previous = _needs;
    _needs = Set<AccessibilityNeed>.from(needs);

    if (_needs.contains(AccessibilityNeed.blind) &&
        !previous.contains(AccessibilityNeed.blind)) {
      _speechEnabled = true;
      _hapticsEnabled = true;
      _textScale = _textScale < 1.2 ? 1.2 : _textScale;
    }
    if (_needs.contains(AccessibilityNeed.lowVision) &&
        !previous.contains(AccessibilityNeed.lowVision)) {
      _highContrast = true;
      _textScale = _textScale < 1.25 ? 1.25 : _textScale;
    }
    if (_needs.contains(AccessibilityNeed.deaf) &&
        !previous.contains(AccessibilityNeed.deaf)) {
      _flashEnabled = true;
      _hapticsEnabled = true;
      _soundAlertsEnabled = false;
    }
    if (_needs.contains(AccessibilityNeed.nonVerbal) &&
        !previous.contains(AccessibilityNeed.nonVerbal)) {
      _speechEnabled = true;
    }

    await _write(
      () => _prefs.setStringList(
        _kNeeds,
        _needs.map((AccessibilityNeed need) => need.key).toList(),
      ),
    );
    await _persistDefaults();
    notifyListeners();
  }

  Future<void> _persistDefaults() async {
    await _write(() => _prefs.setBool(_kSpeech, _speechEnabled));
    await _write(() => _prefs.setBool(_kHaptics, _hapticsEnabled));
    await _write(() => _prefs.setBool(_kFlash, _flashEnabled));
    await _write(() => _prefs.setBool(_kSoundAlerts, _soundAlertsEnabled));
    await _write(() => _prefs.setBool(_kHighContrast, _highContrast));
    await _write(() => _prefs.setDouble(_kTextScale, _textScale));
  }

  Future<void> setSpeechEnabled(bool value) async {
    _speechEnabled = value;
    await _write(() => _prefs.setBool(_kSpeech, value));
    notifyListeners();
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value.clamp(0.2, 1.0);
    await _write(() => _prefs.setDouble(_kSpeechRate, _speechRate));
    notifyListeners();
  }

  Future<void> setSpeechPitch(double value) async {
    _speechPitch = value.clamp(0.5, 2.0);
    await _write(() => _prefs.setDouble(_kSpeechPitch, _speechPitch));
    notifyListeners();
  }

  Future<void> setSpeechLanguage(String value) async {
    _speechLanguage = value;
    await _write(() => _prefs.setString(_kSpeechLanguage, value));
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    await _write(() => _prefs.setBool(_kHaptics, value));
    notifyListeners();
  }

  Future<void> setFlashEnabled(bool value) async {
    _flashEnabled = value;
    await _write(() => _prefs.setBool(_kFlash, value));
    notifyListeners();
  }

  Future<void> setSoundAlertsEnabled(bool value) async {
    _soundAlertsEnabled = value;
    await _write(() => _prefs.setBool(_kSoundAlerts, value));
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _write(() => _prefs.setBool(_kHighContrast, value));
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(0.9, 2.0);
    await _write(() => _prefs.setDouble(_kTextScale, _textScale));
    notifyListeners();
  }

  Future<void> setDetectionConfidence(double value) async {
    _detectionConfidence = value.clamp(0.2, 0.9);
    await _write(() => _prefs.setDouble(_kConfidence, _detectionConfidence));
    notifyListeners();
  }

  Future<void> setAnnounceCooldown(int seconds) async {
    _announceCooldownSeconds = seconds.clamp(2, 30);
    await _write(() => _prefs.setInt(_kCooldown, _announceCooldownSeconds));
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    await _write(() => _prefs.setBool(_kOnboarding, value));
    notifyListeners();
  }

  Future<void> setAnnounceInfo(bool value) async {
    _announceInfo = value;
    await _write(() => _prefs.setBool(_kAnnounceInfo, value));
    notifyListeners();
  }

  Future<void> setSpeakCards(bool value) async {
    _speakCards = value;
    await _write(() => _prefs.setBool(_kSpeakCards, value));
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    _themeMode = value;
    await _write(() => _prefs.setString(_kThemeMode, value));
    notifyListeners();
  }

  Future<void> setAutoUpdateCheck(bool value) async {
    _autoUpdateCheck = value;
    await _write(() => _prefs.setBool(_kAutoUpdateCheck, value));
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    await _write(() => _prefs.setBool(_kAppLockEnabled, value));
    notifyListeners();
  }

  Future<void> setFeatureFlag(String name, bool value) async {
    _featureFlags[name] = value;
    await _write(() => _prefs.setString(_kFeatureFlags, jsonEncode(_featureFlags)));
    notifyListeners();
  }

  /// Replace the emergency medical card.
  Future<void> setMedicalCard({
    required String name,
    required String conditions,
    required String allergies,
    required String medications,
    required String bloodType,
  }) async {
    _medicalName = name.trim();
    _medicalConditions = conditions.trim();
    _medicalAllergies = allergies.trim();
    _medicalMedications = medications.trim();
    _medicalBloodType = bloodType.trim();
    await _write(() => _prefs.setString(_kMedicalName, _medicalName));
    await _write(() => _prefs.setString(_kMedicalConditions, _medicalConditions));
    await _write(() => _prefs.setString(_kMedicalAllergies, _medicalAllergies));
    await _write(() => _prefs.setString(_kMedicalMedications, _medicalMedications));
    await _write(() => _prefs.setString(_kMedicalBloodType, _medicalBloodType));
    notifyListeners();
  }

  /// Replace the emergency contact.
  Future<void> setEmergencyContact({
    required String name,
    required String phone,
  }) async {
    _contactName = name.trim();
    _contactPhone = phone.trim();
    await _write(() => _prefs.setString(_kContactName, _contactName));
    await _write(() => _prefs.setString(_kContactPhone, _contactPhone));
    notifyListeners();
  }

  Future<void> _write(Future<bool> Function() action) async {
    try {
      final ok = await action();
      if (!ok) lastWriteError = 'Preferences rejected a write';
    } catch (error) {
      lastWriteError = error.toString();
    }
  }
}
