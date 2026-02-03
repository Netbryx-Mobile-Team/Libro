// Import for File
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/favorites/view/favorites_screen.dart';
import 'package:libro/features/home/view/screens/bottom_navbar_screen.dart';
import 'package:libro/features/profile/view/screens/my_ads_screen.dart';
import 'package:libro/features/profile/view_model/profile_view_model.dart';
import 'package:libro/features/upload/view/screens/upload_main_screen.dart';
import 'package:libro/features/vendor/view/screens/vendor_bottom_nav_screen.dart'; // Import Vendor Nav
import 'package:libro/shared/providers/firebase_providers.dart';
import 'package:libro/shared/constants/app_dimens.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userStreamProvider);
    final profileState = ref.watch(profileViewModelProvider);
    final notifier = ref.read(profileViewModelProvider.notifier);
    final storageService = ref.watch(storageServiceProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (user) {
          if (user == null) {
            return const Center(child: Text("User not logged in"));
          }

          if (!profileState.isEditing) {
            _nameController.text = user.name;
            _phoneController.text = user.phone ?? "";
            _shopNameController.text = user.shopName ?? "";
            _shopAddressController.text = user.shopAddress ?? "";
          }

          final isVendor = user.userType == 'vendor';

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100.h),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 170.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF26A69A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(30.r),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: whiteColor,
                                ),
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    if (isVendor) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const VendorBottomNavScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    } else {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const BottomNavbarScreen(
                                                initialIndex: 0,
                                              ),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                              ),
                              Text(
                                "Profile",
                                style: AppStyles.headingLarge.copyWith(
                                  color: whiteColor,
                                  letterSpacing: 1.2,
                                  fontSize: 25.sp,
                                ),
                              ),
                              IconButton(
                                onPressed: notifier.toggleEditMode,
                                icon: Icon(
                                  profileState.isEditing
                                      ? Icons.close
                                      : Icons.edit,
                                  color: whiteColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40.h,
                      child: GestureDetector(
                        onTap: profileState.isEditing
                            ? notifier.pickImage
                            : null,
                        child: Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(color: whiteColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: profileState.selectedImage != null
                                ? Image.file(
                                    profileState.selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : (user.profileImageBase64 != null &&
                                        user.profileImageBase64!.isNotEmpty)
                                    ? storageService.imageFromBase64String(
                                        user.profileImageBase64!,
                                      )
                                    : Image.asset(
                                        AppAssets.userProfilePlaceholder,
                                        fit: BoxFit.cover,
                                      ),
                          ),
                        ),
                      ),
                    ),
                    if (profileState.isEditing)
                      Positioned(
                        bottom: -35.h,
                        right: 135.w,
                        child: CircleAvatar(
                          radius: 14.r,
                          backgroundColor: AppColors.primaryColor,
                          child: const Icon(
                            Icons.camera_alt,
                            color: whiteColor,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                gapH32,
                gapH12,
                if (profileState.isEditing)
                  Padding(
                    padding: EdgeInsets.all(AppDimens.kPadding),
                    child: Column(
                      children: [
                        _buildEditField("Full Name", _nameController),
                        gapH16,
                        _buildEditField("Phone", _phoneController),
                        if (isVendor) ...[
                          gapH16,
                          _buildEditField("Shop Name", _shopNameController),
                          gapH16,
                          _buildEditField(
                            "Shop Address",
                            _shopAddressController,
                          ),
                        ],
                        gapH32,
                        CustomButton(
                          text: "Save Changes",
                          isLoading: profileState.isLoading,
                          onPressed: () async {
                            await notifier.updateProfile(
                              uid: user.uid,
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              shopName: isVendor
                                  ? _shopNameController.text.trim()
                                  : null,
                              shopAddress: isVendor
                                  ? _shopAddressController.text.trim()
                                  : null,
                            );
                            if (context.mounted) {
                              FocusScope.of(context).unfocus();
                              CustomSnackbar.show(
                                context: context,
                                message: "Profile Updated!",
                                backgroundColor: AppColors.successGreen,
                              );
                            }
                          },
                        ),
                        SizedBox(height: 50.h),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        Text(
                          user.name,
                          style: AppStyles.headingMedium.copyWith(
                            fontSize: 22.sp,
                          ),
                        ),
                        if (isVendor)
                          Text(
                            user.shopName ?? "Vendor",
                            style: AppStyles.bodySmall.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        gapH24,
                        _buildMenuTile(
                          icon: AppAssets.logoIcon,
                          isAsset: true,
                          title: "My Ads",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyAdsScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 6.h),
                        _buildMenuTile(
                          iconData: Icons.favorite,
                          iconColor: Colors.red,
                          title: "My Favorites",
                          onTap: () =>
                              navigation.push(context, const FavoritesScreen()),
                        ),
                        SizedBox(height: 30.h),
                        SizedBox(
                          width: 200.w,
                          child: CustomButton(
                            text: "Log out",
                            backgroundColor: const Color(0xFFD50000),
                            radius: 30,
                            height: 45,
                            onPressed: () async {
                              await notifier.logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        gapH8,
        CustomTextField(controller: controller, hintText: label),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 45.h, // Reduced height
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r), // Slightly smaller
          ),
          elevation: 2,
          shadowColor: AppColors.primaryColor.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: AppStyles.headingSmall.copyWith(
            color: whiteColor,
            fontSize: 16.sp, // Smaller text
            letterSpacing: 0.4,
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 1.5,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    String? icon,
    IconData? iconData,
    Color? iconColor,
    bool isAsset = false,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isAsset && icon != null)
              Image.asset(icon, height: 35.h, width: 35.h, fit: BoxFit.contain)
            else
              Icon(
                iconData,
                size: 26.sp,
                color: iconColor ?? AppColors.primaryColor,
              ),
            gapW12,
            Text(
              title,
              style: AppStyles.headingSmall.copyWith(
                fontSize: 16.sp,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 18.sp, color: blackColor),
          ],
        ),
      ),
    );
  }
}
