import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0B0D14);
  static const Color surface = Color(0xFF151925);
  static const Color surfaceLight = Color(0xFF202638);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF22D3EE);
  static const Color accent = Color(0xFFFBBF24);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFA8B0C2);
  static const Color divider = Color(0xFF2B3142);
  static const Color error = Color(0xFFFB7185);
  static const Color success = Color(0xFF34D399);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
