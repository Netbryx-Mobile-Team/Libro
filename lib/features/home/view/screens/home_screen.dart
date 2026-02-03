import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/services/google_books_service.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';
import 'package:libro/features/home/view/screens/google_book_detail_screen.dart';
import 'package:libro/features/home/view/screens/read_online_screen.dart';
import 'package:libro/features/home/view/screens/top_selling_view_all_screen.dart';
import 'package:libro/features/home/view/screens/exchange_view_all_screen.dart';
import 'package:libro/features/home/view/screens/rent_view_all_screen.dart';
import 'package:libro/features/notifications/view/screens/notifications_screen.dart';
import 'package:libro/features/notifications/view_model/notification_view_model.dart';
import 'package:libro/features/search_and_filters/view/screens/search_screen.dart';
import 'package:libro/features/upload/view/screens/upload_main_screen.dart';
import 'package:libro/shared/providers/firebase_providers.dart';
import 'package:libro/shared/widgets/app_drawer.dart';

/// Stream provider for books by transaction type, safe with auth
final booksStreamProvider = StreamProvider.family<List<BookModel>, String>(
  (ref, transactionType) {
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );

    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('books')
        .where('transactionType', isEqualTo: transactionType)
        .orderBy('uploadDate', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                try {
                  return BookModel.fromMap(doc.data(), doc.id);
                } catch (e) {
                  debugPrint('BookModel parsing error: $e');
                  return null;
                }
              })
              .whereType<BookModel>()
              .toList(),
        );
  },
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // Track which replies have been shown to prevent duplicates
  final Set<String> _shownReplyIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUnreadVendorReplies();
    });
  }

  Future<void> _checkForUnreadVendorReplies() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: uid)
          .where('userSeen', isEqualTo: false)
          .get();

      debugPrint("User initial check → found ${query.docs.length} unread replies");

      for (var doc in query.docs) {
        final chatId = doc.id;
        if (_shownReplyIds.contains(chatId)) continue;

        final data = doc.data();
        final lastMessageBy = data['lastMessageBy'] as String?;
        final lastMessage = data['lastMessage'] as String?;
        final inquiryMessage = data['inquiryMessage'] as String? ?? "";
        final storeName = data['storeName'] as String? ?? "Store";

        if (lastMessageBy != null &&
            lastMessageBy != uid &&
            lastMessage != null &&
            lastMessage.isNotEmpty) {
          _shownReplyIds.add(chatId);
          _showVendorReplyPopup(chatId, storeName, inquiryMessage, lastMessage);
        }
      }
    } catch (e) {
      debugPrint("Error checking unread replies: $e");
    }

    _listenForVendorReplies();
  }

  void _listenForVendorReplies() {
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
        final lastMessage = data['lastMessage'] as String?;
        final userSeen = data['userSeen'] as bool? ?? true;
        final inquiryMessage = data['inquiryMessage'] as String? ?? "";
        final storeName = data['storeName'] as String? ?? "Store";

        if (lastMessageBy != null &&
            lastMessageBy != uid &&
            userSeen == false &&
            !_shownReplyIds.contains(chatId) &&
            lastMessage != null &&
            lastMessage.isNotEmpty) {
          _shownReplyIds.add(chatId);
          _showVendorReplyPopup(chatId, storeName, inquiryMessage, lastMessage);
        }
      }
    });
  }

  void _showVendorReplyPopup(
    String chatId,
    String storeName,
    String inquiry,
    String reply,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text("Reply from $storeName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //const Text("Your Inquiry:", style: TextStyle(fontWeight: FontWeight.w600)),
            //const SizedBox(height: 6),
            //Text(inquiry.trim()),
            //const SizedBox(height: 16),
            const Text("Store Reply:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(reply.trim(), style: const TextStyle(color: Colors.teal)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .update({'userSeen': true});
              } catch (e) {
                debugPrint("Failed to mark as seen: $e");
              }
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text("OK"),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: whiteColor,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppAssets.vectorBackground1,
              height: 280.h,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: 200.h,
                  pinned: false,
                  floating: false,
                  automaticallyImplyLeading: false,   // ← only this line was added
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      children: [
                        SizedBox(height: 12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                                child: Container(
                                  height: 36.w,
                                  width: 36.w,
                                  decoration: const BoxDecoration(
                                    color: whiteColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => navigation.push(
                                    context,
                                    const VendorStoreSearchScreen(),
                                  ),
                                  child: Container(
                                    height: 42.h,
                                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(22.r),
                                        bottomRight: Radius.circular(22.r),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Search books...",
                                          style: AppStyles.bodyMedium.copyWith(
                                            color: AppColors.greyText,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.search,
                                          color: AppColors.primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              GestureDetector(
                                onTap: () => navigation.push(
                                  context,
                                  const NotificationsScreen(),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      height: 36.w,
                                      width: 36.w,
                                      decoration: const BoxDecoration(
                                        color: whiteColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    if (unreadNotifCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: const BoxDecoration(
                                            color: AppColors.errorRed,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unreadNotifCount > 9
                                                ? "9+"
                                                : unreadNotifCount.toString(),
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Image.asset(AppAssets.booksImg1, height: 40.h, color: whiteColor),
                        SizedBox(height: 4.h),
                        Image.asset(AppAssets.libroText, height: 36.h, color: whiteColor),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28.r),
                        topRight: Radius.circular(28.r),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBrowseSection(),
                          SizedBox(height: 20.h),
                          _buildSectionWithBooks("Top Selling", 'Sell'),
                          SizedBox(height: 20.h),
                          _buildReadOnlineSection(),
                          SizedBox(height: 20.h),
                          _buildSectionWithBooks("Exchange", 'Exchange'),
                          SizedBox(height: 20.h),
                          _buildSectionWithBooks("Rent", 'Rent'),
                          SizedBox(height: 80.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.store_outlined, Icons.store_rounded, 'Stores'),
          GestureDetector(
            onTap: () => _onItemTapped(2),
            child: Container(
              width: 52.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 26.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Inbox'),
          _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 24.sp,
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5.sp,
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Browse Section ──
  Widget _buildBrowseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
          child: Text(
            "Browse",
            style: AppStyles.headingMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
          child: Row(
            children: [
              _buildBrowseItem(
                AppAssets.readIcon,
                "Read",
                const Color(0xFFB2DFDB),
                () => navigation.push(context, const ReadOnlineViewAllScreen()),
              ),
              SizedBox(width: 17.w),
              _buildBrowseItem(
                AppAssets.buyIcon,
                "Buy",
                const Color(0xFFB2DFDB),
                () => navigation.push(context, const TopSellingViewAllScreen()),
              ),
              SizedBox(width: 17.w),
              _buildBrowseItem(
                AppAssets.sellIcon,
                "Sell",
                const Color(0xFFB2DFDB),
                () => navigation.push(
                  context,
                  const UploadMainScreen(initialTabIndex: 0),
                ),
              ),
              SizedBox(width: 17.w),
              _buildBrowseItem(
                AppAssets.rentIcon,
                "Rent",
                const Color(0xFFB2DFDB),
                () => navigation.push(
                  context,
                  const UploadMainScreen(initialTabIndex: 1),
                ),
              ),
              SizedBox(width: 17.w),
              _buildBrowseItem(
                AppAssets.exchangeIcon,
                "Exchange",
                const Color(0xFFB2DFDB),
                () => navigation.push(
                  context,
                  const UploadMainScreen(initialTabIndex: 2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseItem(String icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56.w,
            width: 56.w,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Image.asset(icon, fit: BoxFit.contain),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Read Online Section ──
  Widget _buildReadOnlineSection() {
    final apiBooksAsync = ref.watch(googleBooksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Read Online",
                style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => navigation.push(context, const ReadOnlineViewAllScreen()),
                child: Text(
                  "See all",
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 210.h,
          child: apiBooksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Failed to load: $err")),
            data: (books) => ListView.separated(
              key: const PageStorageKey('google_books_list'),
              padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final book = books[index];
                final img = book.volumeInfo?.imageLinks?.thumbnail ??
                    book.volumeInfo?.imageLinks?.smallThumbnail;

                return _buildCompactCard(
                  title: book.volumeInfo?.title ?? "",
                  subtitle: "Free Ebook",
                  imageWidget: img != null
                      ? Image.network(img, fit: BoxFit.cover)
                      : Image.asset(AppAssets.placeholderImage, fit: BoxFit.cover),
                  onTap: () => navigation.push(
                    context,
                    GoogleBookDetailScreen(book: book),
                  ),
                  maxTitleLines: 2,
                  showGenre: false,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Section with Firebase Books ──
  Widget _buildSectionWithBooks(String title, String type) {
    final booksAsync = ref.watch(booksStreamProvider(type));
    final storage = ref.watch(storageServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () {
                  if (type == 'Sell') {
                    navigation.push(context, const TopSellingViewAllScreen());
                  } else if (type == 'Exchange') {
                    navigation.push(context, const ExchangeViewAllScreen());
                  } else {
                    navigation.push(context, const RentViewAllScreen());
                  }
                },
                child: Text(
                  "See all",
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 210.h,
          child: booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
            data: (books) => ListView.separated(
              key: PageStorageKey('horizontal_$type'),
              padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) => _buildCompactFirebaseCard(
                book: books[index],
                storage: storage,
                type: type,
                key: ValueKey(books[index].id),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFirebaseCard({
    required BookModel book,
    required StorageService storage,
    required String type,
    required Key key,
  }) {
    Uint8List? imageBytes;
    final base64Image = book.bookImagesBase64.isNotEmpty ? book.bookImagesBase64.first : null;

    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64Image);
      } catch (e) {
        debugPrint("Base64 decode error: $e");
      }
    }

    Widget bookImage = imageBytes != null
        ? Image.memory(imageBytes, fit: BoxFit.cover)
        : const ImagePlaceholder();

    String baseSubtitle =
        type == 'Exchange' ? "With : ${book.exchangeBookTitle ?? 'Any'}" : "Rs. ${book.price ?? 0}";
    String condition = book.condition ?? "Used";
    final subtitle = "$baseSubtitle | $condition";

    return _buildCompactCard(
      key: key,
      title: book.title ?? "No Title",
      subtitle: subtitle,
      imageWidget: bookImage,
      genre: book.type,
      genreColor: Colors.teal.shade400,
      onTap: () => navigation.push(context, BookDetailScreen(book: book)),
      maxTitleLines: 1,
      showGenre: true,
    );
  }

  Widget _buildCompactCard({
    Key? key,
    required String title,
    required String subtitle,
    required Widget imageWidget,
    String? genre,
    Color? genreColor,
    required VoidCallback onTap,
    int maxTitleLines = 1,
    bool showGenre = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        key: key,
        width: 120.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 112.w,
              height: 158.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: imageWidget,
              ),
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: 112.w,
              child: Text(
                title,
                maxLines: maxTitleLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontSize: 13.sp,
                  height: 1.18,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: 112.w,
              child: Text(
                subtitle,
                maxLines: showGenre ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.teal.shade600,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
            ),
            if (showGenre && genre != null) ...[
              SizedBox(height: 6.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: genreColor,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Text(
                      genre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Placeholder for missing images ──
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_png/test_book_cover.png.jpeg',
      fit: BoxFit.cover,
    );
  }
}