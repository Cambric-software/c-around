import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_services.dart';
import 'core/config/cambric_config.dart';

const String kConfigAsset = 'lib/core/config/cambric_config.json';

Future<void> main() async {
  // Catch ALL errors — never let the app crash silently.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Show the app immediately with a loading screen.
      // This is the first thing that runs — no platform channels yet.
      late final AppServices services;
      late final ThemeMode initialThemeMode;
      late final bool initialOnboardingComplete;
      late final Locale? initialLocale;

      try {
        final config = await CambricConfig.loadBundled(kConfigAsset);
        services = AppServices(config: config);

        final prefs = services.preferences;
        final themeName = await prefs.getString(AppPreferenceKeys.themeMode);
        final onboardingDone =
            await prefs.getBool(AppPreferenceKeys.onboardingComplete) ?? false;
        final langCode = await prefs.getString(AppPreferenceKeys.language);

        initialThemeMode = themeModeFromName(themeName);
        initialOnboardingComplete = onboardingDone;
        initialLocale = (langCode != null && langCode.isNotEmpty)
            ? Locale(langCode)
            : null;
      } catch (e, st) {
        // Config or prefs failed — show a bare error screen.
        runApp(_ErrorApp(message: e.toString()));
        debugPrint('STARTUP ERROR: $e\n$st');
        return;
      }

      // runApp with the real app — splash shows immediately.
      runApp(
        CambricApp(
          services: services,
          initialThemeMode: initialThemeMode,
          initialOnboardingComplete: initialOnboardingComplete,
          initialLocale: initialLocale,
        ),
      );

      // Initialize all platform services AFTER runApp.
      try {
        await services.initialize();
      } catch (e, st) {
        debugPrint('INITIALIZE ERROR: $e\n$st');
        // App is still running with splash — services.initializedNotifier
        // was never set to true so splash stays. That's acceptable.
      }
    },
    (Object error, StackTrace stack) {
      debugPrint('UNCAUGHT ERROR: $error\n$stack');
    },
  );
}

/// Shown if something fails before runApp — a bare fallback that cannot crash.
class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'C Around failed to start',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please screenshot this and report it.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
