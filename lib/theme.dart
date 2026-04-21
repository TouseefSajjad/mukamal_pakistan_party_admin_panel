import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color background = Color(0xFFF5F5F5);
  static const Color dangerRed = Color(0xFFD32F2F);

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primaryGreen,

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
    ),

    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: accentPink,
      error: dangerRed,
    ),

    // ✅ FIXED
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
    ),
  );
}