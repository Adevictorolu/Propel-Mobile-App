import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.brandGreen600,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandGreen600,
        secondary: AppColors.brandBlue600,
        surface: AppColors.lightCardBg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme:
          GoogleFonts.montserratTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(
            color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(
            color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(
            color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(
            color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: AppColors.lightTextPrimary),
        bodyMedium: const TextStyle(color: AppColors.lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: AppColors.slate700),
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: AppColors.slate800,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCardBg,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.brandGreen100,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return const IconThemeData(size: 20);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandBlue500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate700,
          side: const BorderSide(color: AppColors.slate300, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.brandGreen600,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandGreen500,
        secondary: AppColors.brandBlue400,
        surface: AppColors.darkCardBg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme:
          GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
            color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(
            color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(
            color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(
            color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.slate300),
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.brandGreen800,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return const IconThemeData(size: 20);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate700,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandBlue400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate300,
          side: const BorderSide(color: AppColors.slate600, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
