import 'package:flutter/material.dart';

class AppColors {
  // Premium Fintech palette — deep navy with vibrant teal/emerald accents
  static const Color primary = Color(0xFF0A1628);       // Deep Navy
  static const Color primaryDark = Color(0xFF060E1A);
  static const Color accent = Color(0xFF00D09C);         // Vibrant Emerald/Teal
  static const Color accentLight = Color(0xFF00E6AC);
  static const Color accentSecondary = Color(0xFF5B6EF5); // Soft Indigo
  static const Color background = Color(0xFFF0F4F8);     // Cool Grey BG
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF7F9FC);
  static const Color textPrimary = Color(0xFF0F1B2D);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color textTertiary = Color(0xFF9EAAB8);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF00D09C);
  static const Color pending = Color(0xFFF59E0B);
  static const Color border = Color(0xFFE3E9F0);
  static const Color actionButton = Color(0xFF5B6EF5);   // Indigo Action
  static const Color cardGradientStart = Color(0xFF0A1628);
  static const Color cardGradientEnd = Color(0xFF1A2D4A);
  static const Color shimmer = Color(0xFFE8EFF7);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF1A2D4A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D09C), Color(0xFF00B88C)],
  );

  static const LinearGradient indigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
  );
}
