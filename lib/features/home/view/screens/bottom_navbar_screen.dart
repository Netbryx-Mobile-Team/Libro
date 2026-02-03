import 'package:firebase_auth/firebase_auth.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/chat/view_model/chat_view_model.dart';
import 'package:libro/features/home/view/screens/home_screen.dart';
import 'package:libro/features/chat/view/screens/chat_list_screen.dart';
import 'package:libro/features/profile/view/screens/profile_screen.dart';
import 'package:libro/features/upload/view/screens/upload_main_screen.dart';
import 'package:libro/features/stores/view/screens/view_stores_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final unreadMessageCountProvider = StreamProvider<int>((ref) {
  final chatVM = ref.watch(chatViewModelProvider);
  return chatVM.vendorUnreadCount(); // adjust if needed for user
});

class BottomNavbarScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const BottomNavbarScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<BottomNavbarScreen> createState() => _BottomNavbarScreenState();
}

class _BottomNavbarScreenState extends ConsumerState<BottomNavbarScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _persistentScreens = [
    const HomeScreen(),
    const ViewStoresScreen(book: null,),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCountAsync = ref.watch(unreadMessageCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return Scaffold(
      backgroundColor: whiteColor,
      extendBody: true,
      body: Stack(
        children: [
          Offstage(
            offstage: _selectedIndex == 2,
            child: IndexedStack(
              index: _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex,
              children: _persistentScreens,
            ),
          ),
          if (_selectedIndex == 2) const UploadMainScreen(),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 52.w, // kept slightly smaller FAB
        width: 52.w,
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          backgroundColor: AppColors.primaryColor,
          elevation: 4,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            color: whiteColor,
            size: 26.sp, // reduced icon size
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          height: 40.h, // reduced height
          color: whiteColor,
          shape: const CircularNotchedRectangle(),
          notchMargin: 4.0,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_filled,
                    label: "Home",
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.store_mall_directory_outlined,
                    label: "Stores",
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _buildNavItem(
                    index: 3,
                    icon: Icons.chat_bubble_outline,
                    label: "Inbox",
                    badgeCount: unreadCount,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    label: "Profile",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
                  size: 22.sp, // reduced icon size
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14.w,
                        minHeight: 14.w,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h), // reduced spacing
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
                fontSize: 7.5.sp, // smaller text
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
