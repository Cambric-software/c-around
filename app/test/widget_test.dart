import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cambric_app/app/app.dart';
import 'package:cambric_app/app/app_services.dart';
import 'package:cambric_app/core/config/cambric_config.dart';

const CambricConfig _config = CambricConfig(
  productId: 'test-product',
  productName: 'Test App',
  subtitle: 'A test product',
  version: '1.0.0',
  templateVersion: '1.0.0',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('splash screen shown while services loading', (tester) async {
    final svc = await AppServices.forTest(_config);
    await tester.pumpWidget(CambricApp(services: svc, initialOnboardingComplete: true));
    // Don't pump — first frame only
    expect(find.text('C Around'), findsOneWidget);
    expect(find.text('The world, explained.'), findsOneWidget);
    // Cancel pending timers by pumping with a small duration
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('splash on first launch too', (tester) async {
    final svc = await AppServices.forTest(_config);
    await tester.pumpWidget(CambricApp(services: svc, initialOnboardingComplete: false));
    expect(find.text('C Around'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('theme mode is set correctly', (tester) async {
    final svc = await AppServices.forTest(_config);
    await tester.pumpWidget(
      CambricApp(
        services: svc,
        initialOnboardingComplete: true,
        initialThemeMode: ThemeMode.dark,
      ),
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 1));
  });
}
