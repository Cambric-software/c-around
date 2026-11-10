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

  testWidgets('app shell renders navigation tabs', (tester) async {
    final svc = await AppServices.forTest(_config);
    await tester.pumpWidget(
      CambricApp(
        services: svc,
        initialOnboardingComplete: true,
      ),
    );
    await tester.pump();

    // The shell shows the bottom nav — these labels are always visible.
    expect(find.text('Around'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('first launch shows onboarding', (tester) async {
    final svc = await AppServices.forTest(_config);
    await tester.pumpWidget(
      CambricApp(
        services: svc,
        initialOnboardingComplete: false,
      ),
    );
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('theme mode is respected', (tester) async {
    final svc = await AppServices.forTest(_config);
    await tester.pumpWidget(
      CambricApp(
        services: svc,
        initialOnboardingComplete: true,
        initialThemeMode: ThemeMode.dark,
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
