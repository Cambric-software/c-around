import 'package:flutter/material.dart';

/// C Around's palette.
///
/// The product is used outdoors, in bad light, by people with low vision and by
/// people who cannot hear an alert. That drives three rules:
///
///  * the page is either near-black or near-white, never mid-grey;
///  * the primary cyan clears 4.5:1 on both, and the amber is only ever used
///    for a warning that is also carried by an icon and a word;
///  * high contrast is a real second palette, not an opacity switch.
class CaColors {
  const CaColors._();

  /// Deep ink used for the app tile and dark surfaces.
  static const Color ink = Color(0xFF071018);
  static const Color inkSurface = Color(0xFF0E1A22);
  static const Color inkRaised = Color(0xFF16242E);
  static const Color inkBorder = Color(0xFF273944);

  static const Color paper = Color(0xFFF5F8F8);
  static const Color paperSurface = Color(0xFFFFFFFF);
  static const Color paperBorder = Color(0xFFD7E0E1);

  /// Primary. Dark enough for text on white, bright enough for dark surfaces.
  static const Color cyan = Color(0xFF0B7F74);
  static const Color cyanDark = Color(0xFF2FE3C8);
  static const Color cyanContainer = Color(0xFFD3F5EF);
  static const Color cyanContainerDark = Color(0xFF0B3330);

  /// Attention, never the only signal.
  static const Color amber = Color(0xFF8A5200);
  static const Color amberDark = Color(0xFFFFB74D);
  static const Color amberContainer = Color(0xFFFFE8C2);
  static const Color amberContainerDark = Color(0xFF3A2606);

  /// Emergency.
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerDark = Color(0xFFFF6B6B);
  static const Color dangerContainer = Color(0xFFFBDAD7);
  static const Color dangerContainerDark = Color(0xFF3D1210);

  static const Color success = Color(0xFF116B4B);
  static const Color successDark = Color(0xFF4ADE80);

  static const Color textPrimary = Color(0xFF0B1418);
  static const Color textSecondary = Color(0xFF4C5C63);
  static const Color textDarkPrimary = Color(0xFFF0F6F7);
  static const Color textDarkSecondary = Color(0xFFA9B8BE);
}

/// Builds the light, dark and high-contrast themes.
///
/// Text scaling is not baked into the theme: it is applied once in
/// [CaApp] through `MediaQuery.textScaler` so every screen, including dialogs
/// and snack bars, follows the user's choice.
class CaTheme {
  const CaTheme._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        highContrast: false,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        highContrast: false,
      );

  static ThemeData highContrastLight() => _build(
        brightness: Brightness.light,
        highContrast: true,
      );

  static ThemeData highContrastDark() => _build(
        brightness: Brightness.dark,
        highContrast: true,
      );

  static ThemeData _build({
    required Brightness brightness,
    required bool highContrast,
  }) {
    final isDark = brightness == Brightness.dark;

    final Color primary;
    final Color onPrimary;
    final Color primaryContainer;
    final Color onPrimaryContainer;
    final Color background;
    final Color surface;
    final Color surfaceRaised;
    final Color border;
    final Color text;
    final Color textSecondary;
    final Color error;
    final Color warning;

    if (highContrast && isDark) {
      primary = const Color(0xFF6FFFE9);
      onPrimary = Colors.black;
      primaryContainer = const Color(0xFF00332C);
      onPrimaryContainer = const Color(0xFFB8FFF2);
      background = Colors.black;
      surface = Colors.black;
      surfaceRaised = const Color(0xFF0A0A0A);
      border = Colors.white;
      text = Colors.white;
      textSecondary = const Color(0xFFE6E6E6);
      error = const Color(0xFFFF8A80);
      warning = const Color(0xFFFFE082);
    } else if (highContrast && !isDark) {
      primary = const Color(0xFF004D45);
      onPrimary = Colors.white;
      primaryContainer = const Color(0xFFC9FFF5);
      onPrimaryContainer = Colors.black;
      background = Colors.white;
      surface = Colors.white;
      surfaceRaised = const Color(0xFFF2F2F2);
      border = Colors.black;
      text = Colors.black;
      textSecondary = const Color(0xFF1A1A1A);
      error = const Color(0xFF8C0009);
      warning = const Color(0xFF5C3A00);
    } else if (isDark) {
      primary = CaColors.cyanDark;
      onPrimary = const Color(0xFF00201C);
      primaryContainer = CaColors.cyanContainerDark;
      onPrimaryContainer = CaColors.cyanDark;
      background = CaColors.ink;
      surface = CaColors.inkSurface;
      surfaceRaised = CaColors.inkRaised;
      border = CaColors.inkBorder;
      text = CaColors.textDarkPrimary;
      textSecondary = CaColors.textDarkSecondary;
      error = CaColors.dangerDark;
      warning = CaColors.amberDark;
    } else {
      primary = CaColors.cyan;
      onPrimary = Colors.white;
      primaryContainer = CaColors.cyanContainer;
      onPrimaryContainer = const Color(0xFF00312C);
      background = CaColors.paper;
      surface = CaColors.paperSurface;
      surfaceRaised = const Color(0xFFF0F4F4);
      border = CaColors.paperBorder;
      text = CaColors.textPrimary;
      textSecondary = CaColors.textSecondary;
      error = CaColors.danger;
      warning = CaColors.amber;
    }

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: warning,
      onSecondary: isDark ? Colors.black : Colors.white,
      secondaryContainer: isDark
          ? CaColors.amberContainerDark
          : CaColors.amberContainer,
      onSecondaryContainer: isDark ? CaColors.amberDark : CaColors.amber,
      tertiary: isDark ? const Color(0xFFB9A7FF) : const Color(0xFF4F3BA8),
      onTertiary: isDark ? Colors.black : Colors.white,
      error: error,
      onError: isDark ? Colors.black : Colors.white,
      errorContainer: isDark
          ? CaColors.dangerContainerDark
          : CaColors.dangerContainer,
      onErrorContainer: error,
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: background,
      surfaceContainerLow: surfaceRaised,
      surfaceContainer: surfaceRaised,
      surfaceContainerHigh: surfaceRaised,
      surfaceContainerHighest: surfaceRaised,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? const Color(0xFFF0F6F7) : CaColors.ink,
      onInverseSurface: isDark ? CaColors.ink : Colors.white,
      inversePrimary: isDark ? CaColors.cyan : CaColors.cyanDark,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: text,
      displayColor: text,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.1,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: border, width: highContrast ? 2 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.18),
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.18),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.labelMedium,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFF0F6F7) : CaColors.ink,
        contentTextStyle: TextStyle(
          color: isDark ? CaColors.ink : Colors.white,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : surfaceRaised,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
