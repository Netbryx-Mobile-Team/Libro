// lib/shared/widgets/custom_text_field.dart

import 'package:libro/exports.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final double? height;
  final int maxLines;
  final double radius;
  final BorderSide borderSide;
  final double horizontalPadding;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled; // New property added

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.height,
    this.maxLines = 1,
    this.radius = 10.0,
    // Ensure AppColors.strokeColor is defined as const in your colors file,
    // otherwise use Color(0xFFE0E0E0) here directly.
    this.borderSide = const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
    this.horizontalPadding = 16.0,
    this.inputFormatters,
    this.enabled, // Initialize
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled, // Pass to TextFormField

      style: AppStyles.bodyMedium.copyWith(color: blackColor),
      cursorColor: AppColors.primaryColor,

      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          vertical: (height ?? 50.h) / 2 - 8.h,
          horizontal: horizontalPadding.w,
        ),
        hintText: hintText,
        hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.greyText),

        prefixIcon: prefixIcon != null
            ? Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: prefixIcon,
              )
            : null,
        suffixIcon: suffixIcon,

        filled: true,
        // Change color if disabled to give a "Read Only" look
        fillColor: (enabled == false) ? Colors.grey.shade100 : whiteColor,

        // Border Styling
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: borderSide,
        ),
        disabledBorder: OutlineInputBorder(
          // Style for disabled state
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
      ),
    );
  }
}
