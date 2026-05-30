import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_extensions.dart';

class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF9DB093);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      primary: const Color(0xFF52634A),
      secondary: const Color(0xFF476368),
      tertiary: const Color(0xFF8D4D36),
      surface: isDark ? const Color(0xFF1A1C1B) : const Color(0xFFF9F9F7),
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final appColors = isDark ? AppColors.dark : AppColors.light;
    final headlineFont = GoogleFonts.quicksandTextTheme();
    final bodyFont = GoogleFonts.sourceSans3TextTheme();

    return ThemeData(
      extensions: [appColors],
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme).copyWith(
        displayLarge: headlineFont.displayLarge?.copyWith(color: colorScheme.onSurface),
        displayMedium: headlineFont.displayMedium?.copyWith(color: colorScheme.onSurface),
        displaySmall: headlineFont.displaySmall?.copyWith(color: colorScheme.onSurface),
        headlineLarge: headlineFont.headlineLarge?.copyWith(color: colorScheme.onSurface),
        headlineMedium: headlineFont.headlineMedium?.copyWith(color: colorScheme.onSurface),
        headlineSmall: headlineFont.headlineSmall?.copyWith(color: colorScheme.onSurface),
        titleLarge: headlineFont.titleLarge?.copyWith(color: colorScheme.onSurface),
        titleMedium: bodyFont.titleMedium?.copyWith(color: colorScheme.onSurface),
        titleSmall: bodyFont.titleSmall?.copyWith(color: colorScheme.onSurface),
        bodyLarge: bodyFont.bodyLarge?.copyWith(color: colorScheme.onSurface),
        bodyMedium: bodyFont.bodyMedium?.copyWith(color: colorScheme.onSurface),
        bodySmall: bodyFont.bodySmall?.copyWith(color: colorScheme.onSurface),
        labelLarge: bodyFont.labelLarge?.copyWith(color: colorScheme.onSurface),
        labelMedium: bodyFont.labelMedium?.copyWith(color: colorScheme.onSurface),
        labelSmall: bodyFont.labelSmall?.copyWith(color: colorScheme.onSurface),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
        ),
        color: colorScheme.surface.withOpacity(0.7),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
