import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Green & Blue palette from Tailwind)
  static const Color brandGreen50 = Color(0xFFF0FDF4);
  static const Color brandGreen100 = Color(0xFFDCFCE7);
  static const Color brandGreen200 = Color(0xFFBBF7D0);
  static const Color brandGreen300 = Color(0xFF86EFAC);
  static const Color brandGreen400 = Color(0xFF4ADE80);
  static const Color brandGreen500 = Color(0xFF22C55E);
  static const Color brandGreen600 = Color(0xFF16A34A);
  static const Color brandGreen700 = Color(0xFF15803D);
  static const Color brandGreen800 = Color(0xFF166534);
  static const Color brandGreen900 = Color(0xFF14532D);

  static const Color brandBlue50 = Color(0xFFEFF6FF);
  static const Color brandBlue100 = Color(0xFFDBEAFE);
  static const Color brandBlue200 = Color(0xFFBFDBFE);
  static const Color brandBlue300 = Color(0xFF93C5FD);
  static const Color brandBlue400 = Color(0xFF60A5FA);
  static const Color brandBlue500 = Color(0xFF3B82F6);
  static const Color brandBlue600 = Color(0xFF2563EB);
  static const Color brandBlue700 = Color(0xFF1D4ED8);
  static const Color brandBlue800 = Color(0xFF1E40AF);
  static const Color brandBlue900 = Color(0xFF1E3A8A);

  // Slate Neutral Colors
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Functional Colors
  static const Color success = brandGreen600;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = brandBlue600;

  // Light Mode Defaults
  static const Color lightBackground = slate50;
  static const Color lightCardBg = Colors.white;
  static const Color lightTextPrimary = slate800;
  static const Color lightTextSecondary = slate500;
  static const Color lightBorder = slate200;

  // Dark Mode Defaults
  static const Color darkBackground = slate900;
  static const Color darkCardBg = slate800;
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = slate400;
  static const Color darkBorder = slate700;
}
