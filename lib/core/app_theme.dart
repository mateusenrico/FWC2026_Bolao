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
  const colors = ColorScheme.light(
    primary: FwcColors.red,
    onPrimary: FwcColors.white,
    primaryContainer: Color(0xFFFFDAD7),
    onPrimaryContainer: Color(0xFF410003),
    secondary: FwcColors.teal,
    onSecondary: FwcColors.black,
    secondaryContainer: Color(0xFFC6FFF7),
    onSecondaryContainer: Color(0xFF00201D),
    tertiary: FwcColors.purple,
    onTertiary: FwcColors.white,
    tertiaryContainer: Color(0xFFECDCFF),
    onTertiaryContainer: Color(0xFF23005C),
    error: FwcColors.deepRed,
    onError: FwcColors.white,
    errorContainer: Color(0xFFFFDAD7),
    onErrorContainer: Color(0xFF410003),
    surface: Color(0xFFFCFCFE),
    onSurface: FwcColors.black,
    surfaceContainerLowest: FwcColors.white,
    surfaceContainerLow: Color(0xFFF7F7FA),
    surfaceContainer: Color(0xFFF1F2F6),
    surfaceContainerHigh: Color(0xFFE9EBF0),
    surfaceContainerHighest: Color(0xFFE1E4EA),
    onSurfaceVariant: Color(0xFF4A4F5C),
    outline: Color(0xFF737886),
    outlineVariant: Color(0xFFC4C7D0),
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: Color(0xFFC4C7D0)),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainerLowest,
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
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      side: BorderSide(color: colors.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC4C7D0)),
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
        foregroundColor: FwcColors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
  );
}
