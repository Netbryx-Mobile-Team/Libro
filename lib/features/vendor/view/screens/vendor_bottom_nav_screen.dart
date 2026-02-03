import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;

import 'package:libro/exports.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/features/chat/view/screens/chat_list_screen.dart';
import 'package:libro/features/profile/view/screens/profile_screen.dart';
import 'package:libro/features/vendor/view/screens/vendor_home_screen.dart';
import 'package:libro/features/payment/address_info_screen.dart'; // CheckoutInfoScreen
import 'package:libro/features/chat/view_model/chat_view_model.dart';

final vendorUnreadChatsCountProvider = StreamProvider<int>((ref) {
  final chatVM = ref.watch(chatViewModelProvider);
  return chatVM.vendorUnreadCount();
});

class VendorBottomNavScreen extends ConsumerStatefulWidget {
  const VendorBottomNavScreen({super.key});

  @override
  ConsumerState<VendorBottomNavScreen> createState() => _VendorBottomNavScreenState();
}

class _VendorBottomNavScreenState extends ConsumerState<VendorBottomNavScreen> {
  int _selectedIndex = 0;

  // Screens list – now includes dedicated Orders screen
  final List<Widget> _screens = [
    const VendorHomeScreen(),      // 0: Dashboard
    const ChatListScreen(),        // 1: Chats
    const OrdersScreen(),          // 2: Orders (new dedicated screen)
    const ProfileScreen(),         // 3: Profile
  ];

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(vendorUnreadChatsCountProvider);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: whiteColor,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10.sp),
        iconSize: 22.sp,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: unreadAsync.when(
                data: (count) => count > 0
                    ? Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              showBadge: unreadAsync.when(
                data: (count) => count > 0,
                loading: () => false,
                error: (_, __) => false,
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: AppColors.errorRed,
                padding: EdgeInsets.all(4),
              ),
              position: badges.BadgePosition.topEnd(top: -6, end: -6),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//   Dedicated Orders Screen (shows only orders list)
// ────────────────────────────────────────────────

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _ordersStream = FirebaseFirestore.instance
        .collection('order')
        .where('vendorId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimens.kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Orders", style: AppStyles.headingSmall),
            SizedBox(height: 12.h),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No orders yet."));
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final orderData = orders[index].data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          final book = BookModel(
                            id: orderData['bookId'] ?? '',
                            title: orderData['bookTitle'] ?? 'Unknown',
                            sellerUid: orderData['vendorId'] ?? '', // corrected field name
                            ownerName: orderData['ownerName'] ?? '',
                            author: '',
                            description: '',
                            condition: '',
                            type: '',
                            genres: [],
                            contactPhone: '',
                            address: '',
                            bookImagesBase64: [],
                            uploadDate: DateTime.now(),
                            status: '',
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutInfoScreen(
                                book: book,
                                fullName: orderData['fullName'] ?? '',
                                address: orderData['address'] ?? '',
                                cnic: orderData['cnic'] ?? '',
                                contact: orderData['contact'] ?? '',
                                totalAmount: (orderData['totalAmount'] ?? 0).toDouble(),
                                onWorkingOnOrderPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('order')
                                      .doc(orders[index].id)
                                      .update({'orderStatus': 'working'});
                                  CustomSnackbar.show(
                                    context: context,
                                    message: "Order status updated to Working on Order",
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderData['bookTitle'] ?? 'Unknown',
                                    style: AppStyles.bodyMedium,
                                  ),
                                  Text(
                                    orderData['fullName'] ?? '',
                                    style: AppStyles.bodySmall,
                                  ),
                                ],
                              ),
                              Text(
                                orderData['orderStatus'] ?? 'Placed',
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}