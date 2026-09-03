import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography System for Propel
/// To change the font family across the entire application, change primaryFont() below.
class AppTypography {
  /// Primary font configuration
  static String? get fontFamily => GoogleFonts.montserrat().fontFamily;

  static TextTheme lightTextTheme(TextTheme base) {
    return GoogleFonts.montserratTextTheme(base).copyWith(
      displayLarge: GoogleFonts.montserrat(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.montserrat(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.montserrat(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.montserrat(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.montserrat(color: AppColors.lightTextPrimary),
      bodyMedium: GoogleFonts.montserrat(color: AppColors.lightTextSecondary),
    );
  }

  static TextTheme darkTextTheme(TextTheme base) {
    return GoogleFonts.montserratTextTheme(base).copyWith(
      displayLarge: GoogleFonts.montserrat(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.montserrat(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.montserrat(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.montserrat(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.montserrat(color: AppColors.darkTextPrimary),
      bodyMedium: GoogleFonts.montserrat(color: AppColors.darkTextSecondary),
    );
  }

  // Helper text styles
  static TextStyle heading(BuildContext context, {double fontSize = 22, FontWeight fontWeight = FontWeight.bold}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  static TextStyle body(BuildContext context, {double fontSize = 14, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      color: color ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
    );
  }
}
