import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0F172A);      // Deep Slate Blue
  static const Color accentCyan = Color(0xFF06B6D4);       // Vibrant Cyan
  static const Color successGreen = Color(0xFF10B981);     // Emerald Pass
  static const Color dangerRed = Color(0xFFEF4444);        // Crimson Fail
  static const Color warningOrange = Color(0xFFF59E0B);    // Amber Review
  static const Color cardDark = Color(0xFF1E293B);         // Slate Card
  static const Color surfaceDark = Color(0xFF090D16);      // Background Dark

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentCyan,
        surface: cardDark,
        error: dangerRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
