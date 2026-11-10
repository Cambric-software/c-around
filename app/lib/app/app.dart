import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/screens/onboarding/ca_onboarding_screen.dart';
import 'app_services.dart';
import 'app_shell.dart';
import 'ca_theme.dart';

/// Shared preference keys used across the app.
abstract class AppPreferenceKeys {
  /// `system` / `light` / `dark`.
  static const String themeMode = 'theme_mode';

  /// Whether the user has completed first-run onboarding.
  static const String onboardingComplete = 'onboarding_complete';
}

/// Parse a stored theme name back to a [ThemeMode].
ThemeMode themeModeFromName(String? name) {
  switch (name) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Root widget that owns [ThemeMode] state.
class CambricApp extends StatefulWidget {
  /// Create the app.
  const CambricApp({
    super.key,
    required this.services,
    this.initialThemeMode = ThemeMode.system,
    this.initialOnboardingComplete = false,
  });

  /// Application services.
  final AppServices services;

  /// Theme choice loaded from preferences before startup.
  final ThemeMode initialThemeMode;

  /// Whether the user has already completed onboarding.
  final bool initialOnboardingComplete;

  @override
  State<CambricApp> createState() => _CambricAppState();
}

class _CambricAppState extends State<CambricApp> {
  late ThemeMode _themeMode;
  late bool _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _onboardingComplete = widget.initialOnboardingComplete;
  }

  Future<void> _onThemeModeChanged(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final name = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await widget.services.preferences.setString(
      AppPreferenceKeys.themeMode,
      name,
    );
  }

  void _onOnboardingComplete() {
    setState(() => _onboardingComplete = true);
  }

  void _onReplayOnboarding() {
    setState(() => _onboardingComplete = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.services.config.productName,
      theme: CaTheme.light(),
      darkTheme: CaTheme.dark(),
      themeMode: _themeMode,
      // Localizations — English (default), Arabic, French, German
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('en'),           // English — default
        Locale('ar'),           // Arabic (RTL)
        Locale('fr'),           // French
        Locale('de'),           // German
      ],
      home: _onboardingComplete
          ? AppShell(
              services: widget.services,
              themeMode: _themeMode,
              onThemeModeChanged: _onThemeModeChanged,
              onReplayOnboarding: _onReplayOnboarding,
            )
          : CaOnboardingScreen(
              services: widget.services,
              onComplete: _onOnboardingComplete,
            ),
    );
  }
}
