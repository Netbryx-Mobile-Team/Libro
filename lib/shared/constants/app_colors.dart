// lib/shared/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary App Colors (Based on UI)
  static const Color primaryColor = Color(0xFF11787E); // Dark Teal/Cyan
  static const Color primaryLight = Color(0xFF12BBA5); // Lighter Teal
  static const Color accentColor = Color(
    0xFF2E865F,
  ); // Used in some gradients/buttons

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static Color greyBackground = Colors.grey.shade50;
  static const Color strokeColor = Color(0xFFE0E0E0);
  static const Color errorRed = Colors.redAccent;

  // Text Colors
  static const Color greyText = Color(0xff7A7A7A);
  static const Color lightGreenText = Color(0xFF4CAF50);

  // Status/Interactive Colors
  static const Color successGreen = Colors.green;

  // Gradients (Based on UI)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF12BBA5), Color(0xFF125F65), Color(0xFF0F969C)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// Quick Access Variables
const Color whiteColor = AppColors.white;
const Color blackColor = AppColors.black;
const Color tealColor = AppColors.primaryColor;
