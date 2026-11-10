import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import 'package:cambric_design/cambric_design.dart';
import '../cache/cache_screen.dart';
import '../diagnostics/diagnostics_screen.dart';

/// Full C Around settings screen: language, speech, accessibility,
/// appearance, app lock, auto-update, cache, diagnostics, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.services,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onReplayOnboarding,
    this.onLocaleChanged,
  });

  final AppServices services;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onReplayOnboarding;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppServices get _s => widget.services;

  static const List<_Lang> _languages = <_Lang>[
    _Lang('en', 'English', '🇬🇧'),
    _Lang('ar', 'العربية', '🇸🇦'),
    _Lang('fr', 'Français', '🇫🇷'),
    _Lang('de', 'Deutsch', '🇩🇪'),
  ];

  static const List<_Lang> _speechLanguages = <_Lang>[
    _Lang('en-US', 'English (US)', '🇺🇸'),
    _Lang('en-GB', 'English (UK)', '🇬🇧'),
    _Lang('ar-SA', 'Arabic', '🇸🇦'),
    _Lang('ar-EG', 'Arabic (Egypt)', '🇪🇬'),
    _Lang('fr-FR', 'French', '🇫🇷'),
    _Lang('de-DE', 'German', '🇩🇪'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = _s.settings;
    final config = _s.config;
    final currentLang = Localizations.localeOf(context).languageCode;

    return DsPage(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          // ── Language ────────────────────────────────────────────────────
          DsSection(
            title: 'Language',
            subtitle: 'Full interface in English, Arabic, French and German.',
            child: DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _languages.map((_Lang lang) {
                  final selected = currentLang == lang.code;
                  return ListTile(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(lang.label),
                    trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
                    selected: selected,
                    onTap: () {
                      widget.onLocaleChanged?.call(Locale(lang.code));
                      _persist('language', lang.code);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Speech ──────────────────────────────────────────────────────
          DsSection(
            title: 'Speech',
            subtitle: 'Text-to-speech output settings.',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Spoken output'),
                    subtitle: const Text('Announce hazards, faces and events aloud'),
                    value: settings.speechEnabled,
                    onChanged: (bool v) => setState(() {
                      settings.setSpeechEnabled(v);
                    }),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: Space.md),
                  const DsLabel('Voice language'),
                  const SizedBox(height: Space.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _speechLanguages.any((l) => l.code == settings.speechLanguage)
                        ? settings.speechLanguage
                        : 'en-US',
                    decoration: const InputDecoration(isDense: true),
                    items: _speechLanguages.map((_Lang lang) {
                      return DropdownMenuItem<String>(
                        value: lang.code,
                        child: Text('${lang.flag}  ${lang.label}'),
                      );
                    }).toList(),
                    onChanged: (String? v) {
                      if (v != null) {
                        setState(() => settings.setSpeechLanguage(v));
                        if (_s.isFullyInitialized) {
                          _s.tts.applySettings();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: Space.md),
                  const DsLabel('Speech rate'),
                  Slider(
                    value: settings.speechRate.clamp(0.2, 1.0),
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    label: settings.speechRate.toStringAsFixed(1),
                    onChanged: (double v) => setState(() => settings.setSpeechRate(v)),
                  ),
                  const DsLabel('Speech pitch'),
                  Slider(
                    value: settings.speechPitch.clamp(0.5, 2.0),
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: settings.speechPitch.toStringAsFixed(1),
                    onChanged: (double v) => setState(() => settings.setSpeechPitch(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Speak info-level descriptions'),
                    value: settings.announceInfo,
                    onChanged: (bool v) => setState(() => settings.setAnnounceInfo(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Speak cards on tap'),
                    value: settings.speakCards,
                    onChanged: (bool v) => setState(() => settings.setSpeakCards(v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Accessibility ───────────────────────────────────────────────
          DsSection(
            title: 'Accessibility',
            subtitle: 'Alert channels and display options.',
            child: DsCard(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vibration alerts'),
                    subtitle: const Text('Haptic feedback on hazard events'),
                    value: settings.hapticsEnabled,
                    onChanged: (bool v) => setState(() => settings.setHapticsEnabled(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Screen flash alerts'),
                    subtitle: const Text('Full-screen pulse for deaf users'),
                    value: settings.flashEnabled,
                    onChanged: (bool v) => setState(() => settings.setFlashEnabled(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Audio alerts'),
                    subtitle: const Text('Emergency alarm tone'),
                    value: settings.soundAlertsEnabled,
                    onChanged: (bool v) => setState(() => settings.setSoundAlertsEnabled(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('High contrast'),
                    value: settings.highContrast,
                    onChanged: (bool v) => setState(() => settings.setHighContrast(v)),
                  ),
                  const SizedBox(height: Space.sm),
                  const DsLabel('Text size'),
                  Slider(
                    value: settings.textScale.clamp(0.9, 2.0),
                    min: 0.9,
                    max: 2.0,
                    divisions: 11,
                    label: '${(settings.textScale * 100).round()}%',
                    onChanged: (double v) => setState(() => settings.setTextScale(v)),
                  ),
                  const DsLabel('Detection confidence threshold'),
                  Slider(
                    value: settings.detectionConfidence.clamp(0.2, 0.9),
                    min: 0.2,
                    max: 0.9,
                    divisions: 7,
                    label: '${(settings.detectionConfidence * 100).round()}%',
                    onChanged: (double v) => setState(() => settings.setDetectionConfidence(v)),
                  ),
                  const DsLabel('Announcement cooldown'),
                  Slider(
                    value: settings.announceCooldownSeconds.toDouble().clamp(2, 30),
                    min: 2,
                    max: 30,
                    divisions: 14,
                    label: '${settings.announceCooldownSeconds}s',
                    onChanged: (double v) => setState(() => settings.setAnnounceCooldown(v.round())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Appearance ──────────────────────────────────────────────────
          DsSection(
            title: 'Appearance',
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const DsLabel('Theme'),
                  const SizedBox(height: Space.sm),
                  DsSegmented<ThemeMode>(
                    value: widget.themeMode,
                    options: const <DsSegment<ThemeMode>>[
                      DsSegment<ThemeMode>(value: ThemeMode.system, label: 'System', icon: Icons.brightness_auto_outlined),
                      DsSegment<ThemeMode>(value: ThemeMode.light,  label: 'Light',  icon: Icons.light_mode_outlined),
                      DsSegment<ThemeMode>(value: ThemeMode.dark,   label: 'Dark',   icon: Icons.dark_mode_outlined),
                    ],
                    onChanged: widget.onThemeModeChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Security ────────────────────────────────────────────────────
          DsSection(
            title: 'Security',
            child: DsCard(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('App lock (PIN)'),
                    subtitle: const Text('Require a 6-digit PIN on launch'),
                    value: settings.appLockEnabled,
                    onChanged: (bool v) => setState(() => settings.setAppLockEnabled(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Automatic update checks'),
                    subtitle: const Text('Check GitHub for a newer version on launch'),
                    value: settings.autoUpdateCheck,
                    onChanged: (bool v) => setState(() => settings.setAutoUpdateCheck(v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── App / data ──────────────────────────────────────────────────
          DsSection(
            title: 'Data',
            child: DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('Cache'),
                    subtitle: const Text('Inspect and clear disposable files'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CacheScreen(services: _s),
                    )),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outline),
                  ListTile(
                    leading: const Icon(Icons.troubleshoot_outlined),
                    title: const Text('Diagnostics'),
                    subtitle: const Text('Local report — nothing is transmitted'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => DiagnosticsScreen(services: _s),
                    )),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outline),
                  ListTile(
                    leading: const Icon(Icons.replay_outlined),
                    title: const Text('Replay welcome'),
                    onTap: widget.onReplayOnboarding,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── About ───────────────────────────────────────────────────────
          DsSection(
            title: 'About',
            child: DsCard(
              child: Column(
                children: <Widget>[
                  _Row('App', config.productName),
                  _Row('Version', _s.version.versionString),
                  _Row('Platform', Theme.of(context).platform.name),
                  _Row('Repository', config.repository ?? 'Cambric-software/c-around'),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
      ),
    );
  }

  void _persist(String key, String value) {
    // Store language choice in preferences for next launch
    _s.preferences.setString('app_language', value);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: <Widget>[
        SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall)),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ]),
    );
  }
}

class _Lang {
  const _Lang(this.code, this.label, this.flag);
  final String code;
  final String label;
  final String flag;
}
