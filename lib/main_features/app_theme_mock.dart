import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Pastel Palette
  static const Color primaryPink = Color(0xFFFFD1DC);
  static const Color secondaryPink = Color(0xFFFFB7C5);
  static const Color softBlue = Color(0xFFB4E4FF);
  static const Color softGreen = Color(0xFFD0F0C0);
  static const Color softPurple = Color(0xFFE0BBE4);
  static const Color softYellow = Color(0xFFFFF9C4);
  static const Color softOrange = Color(0xFFFFE0B2);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF8F8F8F);

  // Admin Palette (More sophisticated pastels)
  static const Color adminPrimary = Color(0xFF9575CD); // Deep Purple pastel
  static const Color adminSecondary = Color(0xFF4FC3F7); // Nice Blue
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPink,
        primary: AppColors.primaryPink,
        secondary: AppColors.softBlue,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: AppColors.textMain,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
        ),
      ),
    );
  }

  static ThemeData get adminTheme {
    return lightTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.adminPrimary,
        primary: AppColors.adminPrimary,
        secondary: AppColors.adminSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
