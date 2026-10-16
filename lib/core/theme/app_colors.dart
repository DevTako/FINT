import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Theme Colors (Azul HSL Tailored)
  static const Color primaryLight = Color(0xFF1E3A5F);
  static const Color primaryAccent = Color(0xFF2A5CAA);
  static const Color primaryDark = Color(0xFF4A8BDB);

  // Background & Surface Colors
  static const Color bgLight = Color(0xFFF5F6F8);
  static const Color bgDark = Color(0xFF121212);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1B1B1F);
  static const Color cardDark = Color(0xFF24242A);

  // Status & Financial Indicators
  static const Color income = Color(0xFF10B981); // Emerald
  static const Color expense = Color(0xFFEF4444); // Coral Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Electric Blue

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF2A5CAA), Color(0xFF4A8BDB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
