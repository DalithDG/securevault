import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF7139C9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryPurple,
        secondary: const Color(0xFF9B72E8),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F7FC),
        foregroundColor: Color(0xFF211A2C),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F0FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFB18AFF),
        secondary: const Color(0xFF9B72E8),
        surface: const Color(0xFF211D2B),
      ),
      scaffoldBackgroundColor: const Color(0xFF15121C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF15121C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF292432),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB18AFF), width: 1.5),
        ),
      ),
    );
  }
}