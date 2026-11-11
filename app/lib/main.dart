import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_services.dart';
import 'core/config/cambric_config.dart';

const String kConfigAsset = 'lib/core/config/cambric_config.json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load config — no platform channels involved, safe before runApp.
  final config = await CambricConfig.loadBundled(kConfigAsset);

  // Create the service graph — constructors only, no platform channels yet.
  final services = AppServices(config: config);

  // Read stored preferences — SharedPreferences is safe before runApp.
  final prefs = services.preferences;
  final themeName = await prefs.getString(AppPreferenceKeys.themeMode);
  final onboardingDone = await prefs.getBool(AppPreferenceKeys.onboardingComplete) ?? false;
  final langCode = await prefs.getString(AppPreferenceKeys.language);

  final initialLocale = (langCode != null && langCode.isNotEmpty)
      ? Locale(langCode)
      : null;

  // Run the app FIRST — platform channels are ready after this.
  runApp(
    CambricApp(
      services: services,
      initialThemeMode: themeModeFromName(themeName),
      initialOnboardingComplete: onboardingDone,
      initialLocale: initialLocale,
    ),
  );

  // NOW initialize all platform-channel services, after runApp.
  // Any crash here shows as a diagnostics error, not an app crash.
  await services.initialize();
}
