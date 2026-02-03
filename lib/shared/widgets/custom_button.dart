// lib/shared/widgets/custom_button.dart

import 'package:flutter_animate/flutter_animate.dart';
import 'package:libro/exports.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double radius;
  final TextStyle? textStyle;
  final Color backgroundColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 55,
    this.radius = 10,
    this.textStyle,
    this.backgroundColor = AppColors.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Disable button if loading or onPressed is null
    final bool isButtonDisabled = isLoading || onPressed == null;

    return Container(
      width: double.infinity,
      height: height.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius.r),
        // Gradient animation for a modern feel
        gradient: isButtonDisabled ? null : AppColors.primaryGradient,
        color: isButtonDisabled ? Colors.grey.shade400 : backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(radius.r),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: whiteColor,
                      strokeWidth: 3.0,
                    ),
                  )
                : Text(
                        text,
                        style:
                            textStyle ??
                            AppStyles.bodyLarge.copyWith(
                              color: whiteColor,
                              fontWeight: w600,
                              fontSize: 16.sp,
                            ),
                      )
                      // FIX: Using Scale Effect with double values for uniform scale
                      .animate(target: isButtonDisabled ? 0 : 1)
                      .scaleXY(
                        duration: 200.ms,
                        begin: 0.98,
                        end: 1.0,
                      ), // scaleXY is safer for precise double use
          ),
        ),
      ),
    );
  }
}
