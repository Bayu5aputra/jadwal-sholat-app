import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = TextTheme(
      displaySmall: GoogleFonts.dmSerifDisplay(
        fontSize: 34,
        height: 1.1,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 26,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 15,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.peach,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(140, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.black, width: 1.8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
          shadowColor: Colors.transparent,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: textTheme.bodyMedium,
      ),
    );
  }
}
