// lib/shared/constants/app_dimens.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// SCREEN UTILS HELPERS (h for height, w for width, sp for font size)
final class AppDimens {
  // Standard Padding/Margin
  static double kPadding = 16.w;
  static double kCardMargin = 8.w;

  // Gap Constants for spacing (vertical and horizontal)
  // Usage: gapH12, gapW8
  static final Widget gapH4 = SizedBox(height: 4.h);
  static final Widget gapH8 = SizedBox(height: 8.h);
  static final Widget gapH12 = SizedBox(height: 12.h);
  static final Widget gapH16 = SizedBox(height: 16.h);
  static final Widget gapH20 = SizedBox(height: 20.h);
  static final Widget gapH24 = SizedBox(height: 24.h);
  static final Widget gapH32 = SizedBox(height: 32.h);
  static final Widget gapH40 = SizedBox(height: 40.h);
  static final Widget gapH48 = SizedBox(height: 48.h);
  static final Widget gapH64 = SizedBox(height: 64.h);

  static final Widget gapW4 = SizedBox(width: 4.w);
  static final Widget gapW8 = SizedBox(width: 8.w);
  static final Widget gapW12 = SizedBox(width: 12.w);
  static final Widget gapW16 = SizedBox(width: 16.w);
  static final Widget gapW24 = SizedBox(width: 24.w);
}

// Quick Access Variables (for cleaner UI code)
final gapH4 = AppDimens.gapH4;
final gapH8 = AppDimens.gapH8;
final gapH12 = AppDimens.gapH12;
final gapH16 = AppDimens.gapH16;
final gapH20 = AppDimens.gapH20;
final gapH24 = AppDimens.gapH24;
final gapH32 = AppDimens.gapH32;
final gapH40 = AppDimens.gapH40;
final gapH48 = AppDimens.gapH48;
final gapH64 = AppDimens.gapH64;

final gapW4 = AppDimens.gapW4;
final gapW8 = AppDimens.gapW8;
final gapW12 = AppDimens.gapW12;
final gapW16 = AppDimens.gapW16;
final gapW24 = AppDimens.gapW24;
