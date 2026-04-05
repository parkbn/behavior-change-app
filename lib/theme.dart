import 'package:flutter/material.dart';

/// HealthFlexx green theme — matches the web chat UI colors.
const kPrimaryGreen = Color(0xFF2D6A4F);
const kDarkGreen = Color(0xFF1B4332);
const kBotBubble = Color(0xFFE8F5E9);
const kErrorRed = Color(0xFFD32F2F);

ThemeData healthFlexTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryGreen,
      primary: kPrimaryGreen,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kPrimaryGreen),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
  );
}
