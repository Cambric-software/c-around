import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import '../../../l10n/app_localizations.dart';
import 'package:cambric_design/cambric_design.dart';
import '../cache/cache_screen.dart';
import '../diagnostics/diagnostics_screen.dart';

class _Lang {
  const _Lang(this.code, this.label, this.flag);
  final String code;
  final String label;
  final String flag;
}

const List<_Lang> _kLanguages = <_Lang>[
  _Lang('en', 'English',  '🇬🇧'),
  _Lang('ar', 'العربية',  '🇸🇦'),
  _Lang('fr', 'Français', '🇫🇷'),
  _Lang('de', 'Deutsch',  '🇩🇪'),
];

const List<_Lang> _kVoices = <_Lang>[
  _Lang('en-US', 'English (US)',   '🇺🇸'),
  _Lang('en-GB', 'English (UK)',   '🇬🇧'),
  _Lang('ar-SA', 'العربية',        '🇸🇦'),
  _Lang('ar-EG', 'العربية (مصر)', '🇪🇬'),
  _Lang('fr-FR', 'Français',       '🇫🇷'),
  _Lang('de-DE', 'Deutsch',        '🇩🇪'),
];

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

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final theme  = Theme.of(context);
    final s      = _s.settings;
    final config = _s.config;
    final currentLang = Localizations.localeOf(context).languageCode;
    final currentVoice = _kVoices.any((v) => v.code == s.speechLanguage)
        ? s.speechLanguage
        : 'en-US';

    return DsPage(
      title: l.settingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          // ── UI Language ──────────────────────────────────────────────────
          DsSection(
            title: l.settingsLanguage,
            child: DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (final lang in _kLanguages)
                    ListTile(
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(lang.label),
                      trailing: currentLang == lang.code
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
                      selected: currentLang == lang.code,
                      onTap: () {
                        widget.onLocaleChanged?.call(Locale(lang.code));
                        _s.preferences.setString('app_language', lang.code);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Speech ───────────────────────────────────────────────────────
          DsSection(
            title: l.settingsSpeech,
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsSpeechEnabled),
                    subtitle: const Text('Announce hazards and events aloud'),
                    value: s.speechEnabled,
                    onChanged: (bool v) => setState(() => s.setSpeechEnabled(v)),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: Space.md),
                  DsLabel(l.settingsSpeechLanguage),
                  const SizedBox(height: Space.sm),
                  DropdownButton<String>(
                    value: currentVoice,
                    isExpanded: true,
                    items: _kVoices.map((v) => DropdownMenuItem<String>(
                      value: v.code,
                      child: Text('${v.flag}  ${v.label}'),
                    )).toList(),
                    onChanged: (String? v) {
                      if (v == null) return;
                      setState(() => s.setSpeechLanguage(v));
                      if (_s.isFullyInitialized) {
                        _s.tts.applySettings();
                        _s.tts.initialize();
                      }
                    },
                  ),
                  const SizedBox(height: Space.md),
                  DsLabel(l.settingsSpeechRate),
                  Slider(
                    value: s.speechRate.clamp(0.2, 1.0),
                    min: 0.2, max: 1.0, divisions: 8,
                    label: s.speechRate.toStringAsFixed(1),
                    onChanged: (double v) => setState(() => s.setSpeechRate(v)),
                  ),
                  DsLabel(l.settingsSpeechPitch),
                  Slider(
                    value: s.speechPitch.clamp(0.5, 2.0),
                    min: 0.5, max: 2.0, divisions: 6,
                    label: s.speechPitch.toStringAsFixed(1),
                    onChanged: (double v) => setState(() => s.setSpeechPitch(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsAnnounceInfo),
                    value: s.announceInfo,
                    onChanged: (bool v) => setState(() => s.setAnnounceInfo(v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsSpeakCards),
                    value: s.speakCards,
                    onChanged: (bool v) => setState(() => s.setSpeakCards(v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Accessibility ────────────────────────────────────────────────
          DsSection(
            title: l.settingsAccessibility,
            child: DsCard(
              child: Column(
                children: <Widget>[
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsHaptics),
                    value: s.hapticsEnabled,
                    onChanged: (bool v) => setState(() => s.setHapticsEnabled(v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsFlash),
                    value: s.flashEnabled,
                    onChanged: (bool v) => setState(() => s.setFlashEnabled(v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsSoundAlerts),
                    value: s.soundAlertsEnabled,
                    onChanged: (bool v) => setState(() => s.setSoundAlertsEnabled(v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsHighContrast),
                    value: s.highContrast,
                    onChanged: (bool v) => setState(() => s.setHighContrast(v))),
                  const SizedBox(height: Space.sm),
                  DsLabel(l.settingsTextScale),
                  Slider(
                    value: s.textScale.clamp(0.9, 2.0),
                    min: 0.9, max: 2.0, divisions: 11,
                    label: '${(s.textScale * 100).round()}%',
                    onChanged: (double v) => setState(() => s.setTextScale(v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Appearance ───────────────────────────────────────────────────
          DsSection(
            title: l.settingsTheme,
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: Space.sm),
                  DsSegmented<ThemeMode>(
                    value: widget.themeMode,
                    options: <DsSegment<ThemeMode>>[
                      DsSegment<ThemeMode>(value: ThemeMode.system, label: l.settingsThemeSystem, icon: Icons.brightness_auto_outlined),
                      DsSegment<ThemeMode>(value: ThemeMode.light,  label: l.settingsThemeLight,  icon: Icons.light_mode_outlined),
                      DsSegment<ThemeMode>(value: ThemeMode.dark,   label: l.settingsThemeDark,   icon: Icons.dark_mode_outlined),
                    ],
                    onChanged: widget.onThemeModeChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Security ─────────────────────────────────────────────────────
          DsSection(
            title: l.settingsAppLock,
            child: DsCard(
              child: Column(
                children: <Widget>[
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsAppLockEnabled),
                    value: s.appLockEnabled,
                    onChanged: (bool v) => setState(() => s.setAppLockEnabled(v))),
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsAutoUpdate),
                    value: s.autoUpdateCheck,
                    onChanged: (bool v) => setState(() => s.setAutoUpdateCheck(v))),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── Data / diagnostics ───────────────────────────────────────────
          DsSection(
            title: 'Data',
            child: DsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.troubleshoot_outlined),
                    title: Text(l.settingsDiagnosticsView),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => DiagnosticsScreen(services: _s),
                    )),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outline),
                  ListTile(
                    leading: const Icon(Icons.replay_outlined),
                    title: Text(l.settingsReplayOnboarding),
                    onTap: widget.onReplayOnboarding,
                  ),
                  Divider(height: 1, color: theme.colorScheme.outline),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('Cache'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CacheScreen(services: _s),
                    )),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),

          // ── About ────────────────────────────────────────────────────────
          DsSection(
            title: 'About',
            child: DsCard(
              child: Column(
                children: <Widget>[
                  _InfoRow('App',      config.productName),
                  _InfoRow('Version',  _s.version.versionString),
                  _InfoRow('Platform', theme.platform.name),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
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
