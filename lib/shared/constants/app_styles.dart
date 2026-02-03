// lib/shared/constants/app_styles.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

// Common FontWeight variables for cleaner code
const FontWeight w300 = FontWeight.w300;
const FontWeight w400 = FontWeight.w400;
const FontWeight w500 = FontWeight.w500;
const FontWeight w600 = FontWeight.w600;
const FontWeight w700 = FontWeight.w700;
const FontWeight w900 = FontWeight.w900;

class AppStyles {
  // Display/Heading Styles
  static TextStyle headingLarge = TextStyle(
    fontSize: 28.sp,
    fontWeight: w700,
    color: AppColors.black,
  );

  static TextStyle headingMedium = TextStyle(
    fontSize: 22.sp,
    fontWeight: w600,
    color: AppColors.black,
  );

  static TextStyle headingSmall = TextStyle(
    fontSize: 18.sp,
    fontWeight: w600,
    color: AppColors.black,
  );

  // Body Text Styles
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16.sp,
    fontWeight: w500,
    color: AppColors.black,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: w400,
    color: AppColors.black,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12.sp,
    fontWeight: w400,
    color: AppColors.greyText,
  );

  // Custom function for flexible style application
  static TextStyle custom(double size, FontWeight weight, Color color) {
    return TextStyle(fontSize: size.sp, fontWeight: weight, color: color);
  }
}
