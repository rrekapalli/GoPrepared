import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const double _scale = 0.92;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    ).copyWith(surfaceTint: Colors.transparent);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28 * _scale,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22 * _scale,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          height: 1.25,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 18 * _scale,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.inter(fontSize: 18 * _scale, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(fontSize: 15 * _scale, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(fontSize: 15 * _scale),
        bodyMedium: GoogleFonts.inter(fontSize: 14 * _scale, color: Colors.black87),
        bodySmall: GoogleFonts.inter(fontSize: 12 * _scale, color: Colors.black54),
        labelLarge: GoogleFonts.inter(fontSize: 13 * _scale, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.inter(fontSize: 11 * _scale, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(fontSize: 10 * _scale, letterSpacing: 0.8),
      ),
    );
  }
}
