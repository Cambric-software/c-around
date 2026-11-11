import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/screens/onboarding/ca_onboarding_screen.dart';
import 'app_services.dart';
import 'app_shell.dart';
import 'ca_theme.dart';

abstract class AppPreferenceKeys {
  static const String themeMode  = 'theme_mode';
  static const String onboardingComplete = 'onboarding_complete';
  static const String language   = 'app_language';
}

ThemeMode themeModeFromName(String? name) {
  switch (name) {
    case 'light':  return ThemeMode.light;
    case 'dark':   return ThemeMode.dark;
    default:       return ThemeMode.system;
  }
}

class CambricApp extends StatefulWidget {
  const CambricApp({
    super.key,
    required this.services,
    this.initialThemeMode = ThemeMode.system,
    this.initialOnboardingComplete = false,
    this.initialLocale,
  });

  final AppServices services;
  final ThemeMode initialThemeMode;
  final bool initialOnboardingComplete;
  final Locale? initialLocale;

  @override
  State<CambricApp> createState() => _CambricAppState();
}

class _CambricAppState extends State<CambricApp> {
  late ThemeMode _themeMode;
  late bool      _onboardingComplete;
  Locale?        _locale;
  bool           _ready = false;   // true once initialize() finishes

  static const List<Locale> _supported = <Locale>[
    Locale('en'), Locale('ar'), Locale('fr'), Locale('de'),
  ];

  @override
  void initState() {
    super.initState();
    _themeMode          = widget.initialThemeMode;
    _onboardingComplete = widget.initialOnboardingComplete;
    _locale             = widget.initialLocale;

    if (widget.services.isFullyInitialized) {
      _ready = true;
    } else {
      // Listen to the notifier — no polling, no pending timers.
      void onReady() {
        if (widget.services.isFullyInitialized && mounted) {
          setState(() => _ready = true);
          widget.services.initializedNotifier.removeListener(onReady);
        }
      }
      widget.services.initializedNotifier.addListener(onReady);
    }
  }

  Future<void> _onThemeModeChanged(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final name = switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
    };
    await widget.services.preferences.setString(AppPreferenceKeys.themeMode, name);
  }

  Future<void> _onLocaleChanged(Locale locale) async {
    setState(() => _locale = locale);
    await widget.services.preferences.setString(AppPreferenceKeys.language, locale.languageCode);
  }

  void _onOnboardingComplete() => setState(() => _onboardingComplete = true);
  void _onReplayOnboarding()   => setState(() => _onboardingComplete = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.services.config.productName,
      theme:      CaTheme.light(),
      darkTheme:  CaTheme.dark(),
      themeMode:  _themeMode,
      locale:     _locale,
      supportedLocales: _supported,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Show a branded splash screen while services are starting.
    if (!_ready) {
      return const _SplashScreen();
    }

    if (_onboardingComplete) {
      return AppShell(
        services:           widget.services,
        themeMode:          _themeMode,
        onThemeModeChanged: _onThemeModeChanged,
        onReplayOnboarding: _onReplayOnboarding,
        onLocaleChanged:    _onLocaleChanged,
      );
    }

    return CaOnboardingScreen(
      services:   widget.services,
      onComplete: _onOnboardingComplete,
    );
  }
}

/// Shown while AppServices.initialize() runs after runApp().
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.visibility_rounded,
                size: 52,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'C Around',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The world, explained.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
