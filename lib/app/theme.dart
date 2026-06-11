import 'package:flutter/material.dart';

/// Design system theme declarations for Stickify based on docs/design.md.
class AppTheme {
  AppTheme._();

  // Typography definitions with fallbacks
  static const String _fontHanken = 'Hanken Grotesk';
  static const String _fontInter = 'Inter';
  static const String _fontMono = 'JetBrains Mono';

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontHanken,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontHanken,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontHanken,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontInter,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontInter,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontMono,
        fontFamilyFallback: const ['monospace'],
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 16 / 13,
        letterSpacing: 0.02 * 13,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontInter,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        color: textColor,
      ),
    );
  }

  // Light color scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF003461),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF004B87),
    onPrimaryContainer: Color(0xFF8ABCFF),
    secondary: Color(0xFF585F64),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE1E6),
    onSecondaryContainer: Color(0xFF5C6468),
    tertiary: Color(0xFF003C27),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF005539),
    onTertiaryContainer: Color(0xFF3DD197),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF8F9FF),
    onSurface: Color(0xFF0D1C2E),
    onSurfaceVariant: Color(0xFF424750),
    outline: Color(0xFF727781),
    outlineVariant: Color(0xFFC2C6D1),
    inverseSurface: Color(0xFF233144),
    onInverseSurface: Color(0xFFEAF1FF),
    inversePrimary: Color(0xFFA3C9FF),
  );

  // Custom Light Surface Level Colors
  static const Color lightSurfaceDim = Color(0xFFCCDBF3);
  static const Color lightSurfaceBright = Color(0xFFF8F9FF);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFEFF4FF);
  static const Color lightSurfaceContainer = Color(0xFFE6EEFF);
  static const Color lightSurfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color lightSurfaceContainerHighest = Color(0xFFD5E3FC);

  // Dark color scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA3C9FF),
    onPrimary: Color(0xFF003158),
    primaryContainer: Color(0xFF004880),
    onPrimaryContainer: Color(0xFFD3E4FF),
    secondary: Color(0xFFC0C7CC),
    onSecondary: Color(0xFF2A3135),
    secondaryContainer: Color(0xFF41484C),
    onSecondaryContainer: Color(0xFFDCE3E8),
    tertiary: Color(0xFF4EDEA3),
    onTertiary: Color(0xFF003822),
    tertiaryContainer: Color(0xFF005234),
    onTertiaryContainer: Color(0xFF6FFBBE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0D1C2E),
    onSurface: Color(0xFFEAF1FF),
    onSurfaceVariant: Color(0xFFC2C6D1),
    outline: Color(0xFF8C919D),
    outlineVariant: Color(0xFF424750),
    inverseSurface: Color(0xFFEAF1FF),
    onInverseSurface: Color(0xFF0D1C2E),
    inversePrimary: Color(0xFF003461),
  );

  // Custom Dark Surface Level Colors
  static const Color darkSurfaceDim = Color(0xFF0A121D);
  static const Color darkSurfaceBright = Color(0xFF1B293A);
  static const Color darkSurfaceContainerLowest = Color(0xFF070E17);
  static const Color darkSurfaceContainerLow = Color(0xFF0D1927);
  static const Color darkSurfaceContainer = Color(0xFF112134);
  static const Color darkSurfaceContainerHigh = Color(0xFF172A41);
  static const Color darkSurfaceContainerHighest = Color(0xFF1F3550);

  // Theme getters
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      textTheme: _buildTextTheme(lightColorScheme.onSurface),
      cardTheme: CardThemeData(
        color: lightSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceContainerLow,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF727781)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFC2C6D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF003461), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontInter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontInter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          side: BorderSide(color: lightColorScheme.primary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontInter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      textTheme: _buildTextTheme(darkColorScheme.onSurface),
      cardTheme: CardThemeData(
        color: darkSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF424750)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLow,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF8C919D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF424750)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFA3C9FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontInter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontInter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          side: BorderSide(color: darkColorScheme.primary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontInter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Extension helper to get custom Material 3 surface container colors
/// from [ColorScheme].
extension ContainerColors on ColorScheme {
  /// Dim surface color.
  Color get surfaceDim => brightness == Brightness.light
      ? AppTheme.lightSurfaceDim
      : AppTheme.darkSurfaceDim;

  /// Bright surface color.
  Color get surfaceBright => brightness == Brightness.light
      ? AppTheme.lightSurfaceBright
      : AppTheme.darkSurfaceBright;

  /// Lowest elevation container surface color.
  Color get containerLowest => brightness == Brightness.light
      ? AppTheme.lightSurfaceContainerLowest
      : AppTheme.darkSurfaceContainerLowest;

  /// Low elevation container surface color.
  Color get containerLow => brightness == Brightness.light
      ? AppTheme.lightSurfaceContainerLow
      : AppTheme.darkSurfaceContainerLow;

  /// Medium elevation container surface color.
  Color get container => brightness == Brightness.light
      ? AppTheme.lightSurfaceContainer
      : AppTheme.darkSurfaceContainer;

  /// High elevation container surface color.
  Color get containerHigh => brightness == Brightness.light
      ? AppTheme.lightSurfaceContainerHigh
      : AppTheme.darkSurfaceContainerHigh;

  /// Highest elevation container surface color.
  Color get containerHighest => brightness == Brightness.light
      ? AppTheme.lightSurfaceContainerHighest
      : AppTheme.darkSurfaceContainerHighest;
}
