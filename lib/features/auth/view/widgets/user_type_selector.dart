// lib/features/auth/view/widgets/user_type_selector.dart

import 'package:flutter_animate/flutter_animate.dart';
import 'package:libro/exports.dart';

import '../../view_model/signup_view_model.dart';

class UserTypeSelector extends ConsumerWidget {
  const UserTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selected user type from Signup ViewModel
    final selectedType = ref.watch(signupViewModelProvider).userType;
    final notifier = ref.read(signupViewModelProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSelectorButton(
          context: context,
          label: "Vendor",
          type: 'vendor',
          isSelected: selectedType == 'vendor',
          onTap: () => notifier.setUserType('vendor'),
        ),
        gapW24,
        _buildSelectorButton(
          context: context,
          label: "Reader",
          type: 'bookReader',
          isSelected: selectedType == 'bookReader',
          onTap: () => notifier.setUserType('bookReader'),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildSelectorButton({
    required BuildContext context,
    required String label,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeInOut,
        width: 120.w,
        height: 45.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : whiteColor,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: w600,
              color: isSelected ? whiteColor : blackColor,
            ),
          ),
        ),
      ),
    );
  }
}
