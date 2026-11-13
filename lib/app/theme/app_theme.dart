import 'package:flutter/material.dart';

class AppPalette {
  static const background = Color(0xFFF7F1E8);
  static const surface = Color(0xFFFFFDF9);
  static const champagne = Color(0xFFEAD9BD);
  static const gold = Color(0xFFB68A55);
  static const maroon = Color(0xFF741B35);
  static const darkMaroon = Color(0xFF4D1023);
  static const ink = Color(0xFF302522);
  static const secondary = Color(0xFF82736C);
  static const border = Color(0xFFE3D7CC);
  static const error = Color(0xFF9B2C3D);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.maroon,
      brightness: Brightness.light,
      primary: AppPalette.maroon,
      secondary: AppPalette.gold,
      surface: AppPalette.surface,
      error: AppPalette.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.background,
      fontFamily: 'serif',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, height: 1.12, fontWeight: FontWeight.w500, color: AppPalette.ink),
        headlineMedium: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w500, color: AppPalette.ink),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.ink),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: AppPalette.ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: AppPalette.secondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        hintStyle: const TextStyle(color: AppPalette.secondary, fontSize: 14, fontFamily: 'sans-serif'),
        labelStyle: const TextStyle(color: AppPalette.secondary, fontSize: 14, fontFamily: 'sans-serif'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppPalette.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppPalette.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppPalette.gold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppPalette.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppPalette.error, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.maroon,
          foregroundColor: AppPalette.champagne,
          disabledBackgroundColor: AppPalette.maroon.withValues(alpha: .55),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontFamily: 'sans-serif', fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppPalette.maroon, textStyle: const TextStyle(fontFamily: 'sans-serif', fontWeight: FontWeight.w600)),
      ),
    );
  }
}
