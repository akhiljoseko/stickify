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
    primary: Color(0xFF1A2A4F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2E3F66),
    onPrimaryContainer: Color(0xFFD5E3FC),
    secondary: Color(0xFF4A5B6E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE1E6),
    onSecondaryContainer: Color(0xFF4A5B6E),
    tertiary: Color(0xFF007A7A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF005A5A),
    onTertiaryContainer: Color(0xFFE0F2F1),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF5F7FA),
    onSurface: Color(0xFF1A2A4F),
    onSurfaceVariant: Color(0xFF4A5B6E),
    outline: Color(0xFF727781),
    outlineVariant: Color(0xFFC2C6D1),
    inverseSurface: Color(0xFF1E262F),
    onInverseSurface: Color(0xFFF5F7FA),
    inversePrimary: Color(0xFFA3C9FF),
  );

  // Custom Light Surface Level Colors
  static const Color lightSurfaceDim = Color(0xFFDCE1E9);
  static const Color lightSurfaceBright = Color(0xFFF5F7FA);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFEFF2F6);
  static const Color lightSurfaceContainer = Color(0xFFE5E9F0);
  static const Color lightSurfaceContainerHigh = Color(0xFFDBE0EA);
  static const Color lightSurfaceContainerHighest = Color(0xFFD0D6E2);

  // Dark color scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8E9BB4),
    onPrimary: Color(0xFF1A2A4F),
    primaryContainer: Color(0xFF2E3F66),
    onPrimaryContainer: Color(0xFFD5E3FC),
    secondary: Color(0xFFB0BEC5),
    onSecondary: Color(0xFF1E262F),
    secondaryContainer: Color(0xFF4A5B6E),
    onSecondaryContainer: Color(0xFFECEFF1),
    tertiary: Color(0xFF007A7A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF005234),
    onTertiaryContainer: Color(0xFF6FFBBE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1E262F),
    onSurface: Color(0xFFF5F7FA),
    onSurfaceVariant: Color(0xFFB0BEC5),
    outline: Color(0xFF78909C),
    outlineVariant: Color(0xFF4A5B6E),
    inverseSurface: Color(0xFFF5F7FA),
    onInverseSurface: Color(0xFF1E262F),
    inversePrimary: Color(0xFF1A2A4F),
  );

  // Custom Dark Surface Level Colors
  static const Color darkSurfaceDim = Color(0xFF141920);
  static const Color darkSurfaceBright = Color(0xFF252F39);
  static const Color darkSurfaceContainerLowest = Color(0xFF0F1318);
  static const Color darkSurfaceContainerLow = Color(0xFF192027);
  static const Color darkSurfaceContainer = Color(0xFF1E262F);
  static const Color darkSurfaceContainerHigh = Color(0xFF28323E);
  static const Color darkSurfaceContainerHighest = Color(0xFF333F4D);

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
          borderSide: const BorderSide(color: Color(0xFF1A2A4F), width: 2),
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
          borderSide: const BorderSide(color: Color(0xFF8E9BB4), width: 2),
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
