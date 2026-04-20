// lib/core/theme/app_theme.dart
//
// Defines the visual theme for Noor's Attire.
// Colors inspired by traditional Pashtun embroidery:
//   - Deep burgundy red (primary)
//   - Gold/saffron (accent)
//   - Cream/ivory (background)
//   - Dark charcoal (text)

import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF8B1A1A); // Deep burgundy red
  static const Color accent = Color(0xFFD4A017); // Saffron gold
  static const Color background = Color(0xFFFAF8F3); // Warm ivory
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1C1C1C);
  static const Color textGrey = Color(0xFF757575);
  static const Color border = Color(0xFFE0D9CC);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF2E7D32);

  // ── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        background: background,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,

      // ── Typography ────────────────────────────────────────────────────────
      fontFamily: 'Georgia', // Elegant serif for body text
      textTheme: const TextTheme(
        // Display: used for hero titles
        displayLarge: TextStyle(
          fontFamily: 'Playfair',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: textDark,
          height: 1.2,
        ),
        // Headline: section titles
        headlineLarge: TextStyle(
          fontFamily: 'Playfair',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Playfair',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        // Title: card titles, product names
        titleLarge: TextStyle(
          fontFamily: 'Playfair',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        // Body: descriptions, paragraphs
        bodyLarge: TextStyle(fontSize: 16, color: textDark, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: textGrey, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: textGrey),
        // Label: buttons, tags
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),

      // ── App Bar ───────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Playfair',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      // FIX: Material 3 requires CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
