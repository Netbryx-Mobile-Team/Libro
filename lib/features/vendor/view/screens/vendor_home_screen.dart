import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/notifications/view/screens/notifications_screen.dart';
import 'package:libro/features/payment/address_info_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/search_screen.dart';
import 'package:libro/features/subscription/view/screens/subscription_plan_screen.dart';
import 'package:libro/features/vendor/view/screens/add_store_screen.dart';
import 'package:libro/features/vendor/view/screens/vendor_search.dart' as VendorSearch;
import 'package:libro/features/vendor/view/screens/your_store_detail_screen.dart';
import 'package:libro/features/vendor/view/widgets/vendor_app_drawer.dart';
import 'package:libro/features/vendor/view_model/vendor_view_model.dart';
import 'package:libro/features/notifications/view_model/notification_view_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/features/payment/invoice.dart';
import 'view_all_stores_screen.dart';

class VendorHomeScreen extends ConsumerStatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  ConsumerState<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends ConsumerState<VendorHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCheckingCredits = false;

  int _unreadChatCount = 0;
  final Set<String> _shownInquiryIds = {};
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewInquiries();
      _loadUnreadChatCount();
    });
  }

  // ================= CHAT + INQUIRY =================

  Future<void> _loadUnreadChatCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: uid)
          .where('vendorSeen', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() => _unreadChatCount = query.docs.length);
      }
    } catch (e) {
      debugPrint("Error loading unread chat count: $e");
    }
  }

  Future<void> _checkForNewInquiries() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: uid)
          .orderBy('lastMessageTime', descending: true)
          .limit(15)
          .get();

      for (var doc in query.docs) {
        final chatId = doc.id;
        if (_shownInquiryIds.contains(chatId)) continue;

        final data = doc.data();
        final lastMessageBy = data['lastMessageBy'] as String?;
        final lastMessage = data['lastMessage'] as String? ?? "New message";

        if (lastMessageBy != null && lastMessageBy != uid) {
          _shownInquiryIds.add(chatId);
          _showInquiryPopup(lastMessage, chatId);
        }
      }
    } catch (e) {
      debugPrint("Inquiry check error: $e");
    }

    _listenForNewInquiries();
  }

  void _listenForNewInquiries() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.modified &&
            change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final chatId = change.doc.id;
        final lastMessageBy = data['lastMessageBy'] as String?;
        final lastMessage = data['lastMessage'] as String? ?? "New message";

        if (lastMessageBy != null &&
            lastMessageBy != uid &&
            !_shownInquiryIds.contains(chatId)) {
          _shownInquiryIds.add(chatId);
          _showInquiryPopup(lastMessage, chatId);
        }
      }
    });
  }

  void _showInquiryPopup(String message, String chatId) {
    if (!mounted) return;

    final replyController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("New Customer Inquiry"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.trim()),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              decoration: const InputDecoration(
                labelText: "Quick reply (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _markChatAsSeen(chatId);
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final text = replyController.text.trim();
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              if (text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .add({
                  'message': text,
                  'senderId': uid,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
                  'lastMessage': text,
                  'lastMessageBy': uid,
                  'lastMessageTime': FieldValue.serverTimestamp(),
                  'vendorSeen': true,
                  'userSeen': false,
                });
              } else {
                await _markChatAsSeen(chatId);
              }

              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Send Reply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _markChatAsSeen(String chatId) async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'vendorSeen': true,
      });
      await _loadUnreadChatCount();
    } catch (e) {
      debugPrint("Mark as seen failed: $e");
    }
  }

  // ================= DASHBOARD =================
final TextEditingController _searchController = TextEditingController();
String _selectedCity = "All"; // default

  Future<void> _refreshDashboard() async {
    ref.invalidate(vendorViewModelProvider);
    ref.invalidate(allStoresStreamProvider);
    await _loadUnreadChatCount();
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _handleCreateStoreClick() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isCheckingCredits = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final int credits = userDoc.data()?['storeCredits'] ?? 0;

      if (!mounted) return;

      if (credits > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStoreScreen()),
        );
      } else {
        _showSubscriptionDialog();
      }
    } catch (e) {
      CustomSnackbar.show(context: context, message: "Error checking plan.");
    } finally {
      if (mounted) setState(() => _isCheckingCredits = false);
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Subscription Required"),
        content: const Text(
          "To create a new store, you need to subscribe to our Basic Plan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPlanScreen()),
              );
            },
            child: const Text("View Plans", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorViewModelProvider);
    final allStoresAsync = ref.watch(allStoresStreamProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: whiteColor,
      drawer: const VendorAppDrawer(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppAssets.vectorBackground1,
              height: 300.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, ref),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refreshDashboard,
                      color: AppColors.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(AppDimens.kPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            gapH12,
                            Text("Store Management", style: AppStyles.headingSmall),
                            gapH16,
                            Row(
                              children: [
                                _buildActionCard(
                                  title: "Your Store",
                                  icon: Icons.store_mall_directory,
                                  color: vendorState.myStore != null
                                      ? AppColors.primaryColor
                                      : Colors.grey.shade400,
                                  onTap: () {
                                    if (vendorState.myStore != null) {
                                      navigation.push(
                                        context,
                                        VendorSearch.VendorStoreSearchScreenForVendor(
                                          storeId: vendorState.myStore!.uid,
                                        ),
                                      );
                                    } else {
                                      CustomSnackbar.show(
                                        context: context,
                                        message: "Please create a store first",
                                        backgroundColor: Colors.grey,
                                      );
                                    }
                                  },
                                ),
                                gapW16,
                                _buildActionCard(
                                  title: _isCheckingCredits ? "Checking..." : "Create Store",
                                  icon: Icons.add_business,
                                  color: const Color(0xFFFFA000),
                                  isLoading: _isCheckingCredits,
                                  onTap: () {
                                    if (vendorState.myStore == null) {
                                      _handleCreateStoreClick();
                                    } else {
                                      CustomSnackbar.show(
                                        context: context,
                                        message: "You already have a store!",
                                        backgroundColor: Colors.orange,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                           gapH32,
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text("Market Overview", style: AppStyles.headingSmall),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
 builder: (_) => ViewAllStoresScreen(
      searchController: _searchController,
      selectedCity: _selectedCity,
    ),
          ),
        );
      },
      child: const Text("View All"),
    ),
  ],
),
gapH16,
allStoresAsync.when(
  loading: () => const Center(
      child: CircularProgressIndicator(color: AppColors.primaryColor)),
  error: (e, s) => Center(child: Text("Error: $e")),
  data: (stores) {
    if (stores.isEmpty) {
      return const Center(child: Text("No stores available yet."));
    }

    // ✅ LIMIT APPLIED HERE
    final limitedStores = stores.take(10).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: limitedStores.length,
      separatorBuilder: (_, __) => gapH16,
      itemBuilder: (context, index) {
        final store = limitedStores[index];
        return _buildStoreTile(context, store);
      },
    );
  },
),
 gapH40,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= ONLY ADDITION =================
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddStoreScreen()),
                );
              },
              child: const Text(
                "Demo Add Store",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // =================================================
        ],
      ),
    );
  }

  // HEADER, ACTION CARD, STORE TILE
  // (unchanged from your original)

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding, vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(color: whiteColor, shape: BoxShape.circle),
                  child: const Icon(Icons.menu, color: AppColors.primaryColor),
                ),
              ),
              Text(
                "Vendor Dashboard",
                style: AppStyles.headingMedium.copyWith(color: whiteColor),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => navigation.push(context, const NotificationsScreen()),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 40.w,
                          width: 40.w,
                          decoration: BoxDecoration(color: whiteColor, shape: BoxShape.circle),
                          child: const Icon(Icons.notifications_none, color: AppColors.primaryColor),
                        ),
                        if (unreadNotifCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                              child: Center(
                                child: Text(
                                  unreadNotifCount > 9 ? "9+" : unreadNotifCount.toString(),
                                  style: TextStyle(color: whiteColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                ],
              ),
            ],
          ),
          gapH16,
          Column(
            children: [
              Image.asset(AppAssets.booksImg1, height: 45.h, fit: BoxFit.contain, color: whiteColor),
              gapH4,
              Image.asset(AppAssets.libroText, height: 40.h, color: whiteColor),
            ],
          ),
          gapH20,
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(icon, size: 36.w, color: whiteColor),
              gapH8,
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(color: whiteColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreTile(BuildContext context, StoreModel store) {
    return GestureDetector(
      onTap: () {
        navigation.push(context, YourStoreDetailScreen(store: store));
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              height: 50.w,
              width: 50.w,
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8.r)),
              child: const Icon(Icons.store, color: AppColors.primaryColor),
            ),
            gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.shopName,
                    style: AppStyles.headingSmall.copyWith(fontSize: 16.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    store.shopAddress,
                    style: AppStyles.bodySmall.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
