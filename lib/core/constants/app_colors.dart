import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors from design
  static const Color primaryDark = Color(0xFF05110B);
  static const Color primaryOlive = Color(0xFF3A420E);
  static const Color primaryGreen = Color(0xFFA1E433);
  static const Color primaryRed = Color(0xFF4B0202);

  // Derived Colors
  static const Color background = Color(0xFF05110B);
  static const Color cardBackground = Color(0xFF0D1F14);
  static const Color cardBackgroundLight = Color(0xFF1A2E1F);
  static const Color inputBackground = Color(0xFF1A2E1F);
  static const Color inputBorder = Color(0xFF3A420E);
  static const Color border = Color(0xFF3A420E);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF6B6B6B);
  static const Color textGreen = Color(0xFFA1E433);

  // Button Colors
  static const Color buttonPrimary = Color(0xFFA1E433);
  static const Color buttonDisabled = Color(0xFF3A420E);
  static const Color buttonText = Color(0xFF05110B);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFF4B0202);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Calendar Colors
  static const Color attendanceHigh = Color(0xFF4CAF50); // > 60%
  static const Color attendanceMedium = Color(0xFFFFD700); // 20-60%
  static const Color attendanceLow = Color(0xFF4B0202); // < 20%

  // Gradient Colors
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2E1F),
      Color(0xFF0D1F14),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC8F560),
      Color(0xFFA1E433),
    ],
  );

  static const LinearGradient selectedCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3A420E),
      Color(0xFF1A2E1F),
    ],
  );
}
