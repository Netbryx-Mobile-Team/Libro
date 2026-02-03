import 'package:libro/exports.dart';
import 'package:libro/features/auth/view/screens/login_screen.dart';
import 'package:libro/features/chat/view/screens/chat_list_screen.dart';
import 'package:libro/features/profile/view/screens/profile_screen.dart';
import 'package:libro/features/upload/view/screens/upload_main_screen.dart';
// Or wherever your Vendor Home main wrapper is
import 'package:libro/shared/providers/app_providers.dart';

class VendorAppDrawer extends ConsumerWidget {
  const VendorAppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.70, // 70% Width (Narrow)
      child: Drawer(
        backgroundColor: whiteColor,
        child: Column(
          children: [
            // --- HEADER (Matches Reader Theme) ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 50.h, bottom: 20.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35.r,
                    backgroundColor: whiteColor,
                    child: Image.asset(AppAssets.logoIcon, height: 40.h),
                  ),
                  gapH12,
                  Text(
                    "LIBRO VENDOR",
                    style: AppStyles.headingMedium.copyWith(
                      color: whiteColor,
                      letterSpacing: 2,
                      fontSize: 20.sp,
                    ),
                  ),
                  Text(
                    "Manage your Store",
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),

            // --- MENU ITEMS ---
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: "Dashboard",
                    onTap: () => Navigator.pop(context),
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: "Messages",
                    onTap: () {
                      Navigator.pop(context);
                      navigation.push(context, const ChatListScreen());
                    },
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.add_circle_outline,
                    title: "Add New Book",
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to Upload Screen (Sell Tab)
                      navigation.push(
                        context,
                        const UploadMainScreen(initialTabIndex: 0),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.vpn_key_outlined,
                    title: "Rent Requests",
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to Rent Tab
                      navigation.push(
                        context,
                        const UploadMainScreen(initialTabIndex: 1),
                      );
                    },
                  ),

                  const Divider(),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: "Vendor Profile",
                    onTap: () {
                      Navigator.pop(context);
                      navigation.push(context, const ProfileScreen());
                    },
                  ),

                  const Divider(),

                  // --- LOGOUT BUTTON ---
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.errorRed,
                    ),
                    title: Text(
                      "Logout",
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      // 1. Perform Firebase SignOut
                      await ref.read(authRepositoryProvider).signOut();

                      if (context.mounted) {
                        // 2. FORCE NAVIGATION to Login Screen
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor, size: 22.sp),
      title: Text(title, style: AppStyles.bodyMedium.copyWith(fontSize: 14.sp)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
    );
  }
}
