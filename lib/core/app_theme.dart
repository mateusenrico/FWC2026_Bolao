import 'package:flutter/material.dart';

class FwcColors {
  const FwcColors._();

  static const black = Color(0xFF060606);
  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFE80012);
  static const deepRed = Color(0xFF8F0710);
  static const purple = Color(0xFF6B00FF);
  static const indigo = Color(0xFF1D2786);
  static const blue = Color(0xFF276BFF);
  static const sky = Color(0xFF35A7FF);
  static const teal = Color(0xFF00D8C8);
  static const green = Color(0xFF00C85A);
  static const lime = Color(0xFFB9F700);
  static const magenta = Color(0xFFFF0B6D);
  static const coral = Color(0xFFFF684A);
  static const gold = Color(0xFFC99B28);
}

ThemeData buildBolaoTheme() {
  const colors = ColorScheme.dark(
    primary: FwcColors.red,
    onPrimary: FwcColors.white,
    primaryContainer: Color(0xFF5F0008),
    onPrimaryContainer: Color(0xFFFFDAD7),
    secondary: FwcColors.teal,
    onSecondary: FwcColors.black,
    secondaryContainer: Color(0xFF004D46),
    onSecondaryContainer: Color(0xFFC6FFF7),
    tertiary: Color(0xFF9B5CFF),
    onTertiary: FwcColors.white,
    tertiaryContainer: Color(0xFF3B0A88),
    onTertiaryContainer: Color(0xFFECDCFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD7),
    surface: Color(0xFF070810),
    onSurface: Color(0xFFF4F7FB),
    surfaceContainerLowest: Color(0xFF05060B),
    surfaceContainerLow: Color(0xFF0D101A),
    surfaceContainer: Color(0xFF121624),
    surfaceContainerHigh: Color(0xFF1A2030),
    surfaceContainerHighest: Color(0xFF242B3C),
    onSurfaceVariant: Color(0xFFC7CEDC),
    outline: Color(0xFF8B94A7),
    outlineVariant: Color(0xFF3C465C),
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: Color(0xFF3C465C)),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    canvasColor: colors.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 10),
      shape: shape,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      selectedColor: colors.primary,
      checkmarkColor: colors.onPrimary,
      labelStyle: TextStyle(
        color: colors.onSurface,
        fontWeight: FontWeight.w800,
      ),
      secondaryLabelStyle: TextStyle(
        color: colors.onPrimary,
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(color: colors.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FwcColors.red, width: 2),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FwcColors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
  );
}
