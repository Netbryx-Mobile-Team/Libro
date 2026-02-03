import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/chat/view/screens/chat_screen.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';
import 'package:libro/features/payment/invoice.dart';
import 'package:libro/features/stores/view/screens/specific_search_screen.dart';
import 'package:libro/features/subscription/view/screens/jazzcash_payment_screen.dart';
import 'package:libro/features/vendor/view/screens/vendor_search.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final StoreModel store;
  final BookModel? book;

  const StoreDetailScreen({super.key, required this.store, required this.book});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final storageService = ref.watch(storageServiceProvider);
    final currentUser = ref.watch(authStateChangesProvider).value;
    final List<String> images =
        widget.store.shopImagesBase64.isNotEmpty ? widget.store.shopImagesBase64 : [];

    return Scaffold(
      backgroundColor: whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 250.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.black,
                    elevation: 0,
                    leading: Padding(
                      padding: EdgeInsets.only(left: 16.w, top: 8.h),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: blackColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: [
                      // Search in store button
                      Padding(
                        padding: EdgeInsets.only(right: 12.w, top: 8.h),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: blackColor),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VendorStoreSearchScreenForVendor(storeId: widget.store.uid),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Ask about a book button
                      Padding(
                        padding: EdgeInsets.only(right: 16.w, top: 8.h),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          child: IconButton(
                            icon: const Icon(Icons.question_answer, color: blackColor),
                            onPressed: () {
                              _showAskAboutBookDialog(context, widget.store);
                            },
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: Colors.black,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            images.isNotEmpty
                                ? PageView.builder(
                                    itemCount: images.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      return Image(
                                        image: storageService
                                            .imageFromBase64String(images[index])
                                            .image,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    AppAssets.storeImagePlaceholder,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                            if (images.length > 1)
                              Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    images.length,
                                    (index) => Container(
                                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == index
                                            ? AppColors.primaryColor
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16.h),
                          Text(
                            widget.store.shopName,
                            style: AppStyles.headingMedium.copyWith(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          gapH8,
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              gapW8,
                              Expanded(
                                child: Text(
                                  widget.store.shopAddress,
                                  style: AppStyles.bodyMedium.copyWith(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          gapH16,
                          Text("Shop Description", style: AppStyles.headingSmall),
                          gapH8,
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              widget.store.shopDescription.isNotEmpty
                                  ? widget.store.shopDescription
                                  : "All books available. Best price dealing.",
                              style: AppStyles.bodyMedium.copyWith(
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                          gapH20,
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.person,
                                  color: whiteColor,
                                  size: 24,
                                ),
                              ),
                              gapW12,
                              Text(
                                widget.store.ownerName,
                                style: AppStyles.headingSmall.copyWith(fontSize: 16.sp),
                              ),
                            ],
                          ),
                          gapH24,
                          const Divider(),
                          gapH16,
                          Text("Books available here", style: AppStyles.headingSmall),
                          gapH16,
                        ],
                      ),
                    ),
                  ),
                  // ---------------- STREAMBUILDER ----------------
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('books_sell')
                        .where('storeId', isEqualTo: widget.store.uid) // ✅ Fixed query
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        print("No books found for store: ${widget.store.uid}"); // Debug
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 40.h),
                              child: Text(
                                "No books listed yet.",
                                style: AppStyles.bodySmall,
                              ),
                            ),
                          ),
                        );
                      }

                      // Debug: print all fetched docs
                      print("Books fetched for store: ${widget.store.uid}");
                      snapshot.data!.docs.forEach((doc) {
                        print(doc.data());
                      });

                      final books = snapshot.data!.docs
                          .map((doc) => BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                          .toList();

                      print("Total books converted to model: ${books.length}"); // Debug

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildSmallBookRow(context, books[index]),
                          childCount: books.length,
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ ASK ABOUT BOOK ------------------
  void _showAskAboutBookDialog(BuildContext context, StoreModel store) {
    final TextEditingController bookController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to ask about a book")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Ask about a book"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ask ${store.shopName} if they have this book",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bookController,
                  decoration: const InputDecoration(
                    labelText: "Book title / Author / ISBN",
                    border: OutlineInputBorder(),
                    hintText: "e.g. Harry Potter and the Philosopher's Stone",
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: "Additional message (optional)",
                    border: OutlineInputBorder(),
                    hintText: "Any specific edition, condition, etc...",
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final bookName = bookController.text.trim();
                if (bookName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter book name")),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                await _sendAvailabilityInquiry(
                  context,
                  store,
                  currentUser.uid,
                  currentUser.displayName ?? "Customer",
                  bookName,
                  messageController.text.trim(),
                );
              },
              child: const Text("Send Inquiry"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendAvailabilityInquiry(
    BuildContext context,
    StoreModel store,
    String customerUid,
    String customerName,
    String bookName,
    String additionalMessage,
  ) async {
    try {
      final ids = [customerUid, store.uid]..sort();
      final chatId = ids.join('_');
      final messageText = additionalMessage.isEmpty
          ? "Hi, do you have '$bookName' in stock?"
          : "Hi, do you have '$bookName' in stock?\n\n$additionalMessage";

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': customerUid,
        'senderName': customerName,
        'receiverId': store.uid,
        'receiverName': store.ownerName,
        'text': messageText,
        'type': 'availability_inquiry',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [customerUid, store.uid],
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageBy': customerUid,
        'storeId': store.uid,
        'storeName': store.shopName,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your inquiry has been sent! Vendor will reply soon."),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending inquiry: $e")),
      );
    }
  }

  // ------------------ BOOK ROW ------------------
  Widget _buildSmallBookRow(BuildContext context, BookModel book) {
    final storageService = ref.watch(storageServiceProvider);

    return GestureDetector(
      onTap: () => _showBookOptionsDialog(context, book, storageService),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.book, color: Colors.teal, size: 20.sp),
            ),
            gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.headingSmall.copyWith(fontSize: 14.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "${book.type} • ${book.author}",
                    style: AppStyles.bodySmall.copyWith(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              "Rs. ${book.price}",
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                fontSize: 14.sp,
              ),
            ),
            gapW8,
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ------------------ BOOK OPTIONS ------------------
  void _showBookOptionsDialog(
    BuildContext context,
    BookModel book,
    StorageService storageService,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  style: AppStyles.headingMedium.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "What would you like to do?",
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please login first")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: '',
                                otherUserId: book.sellerUid,
                                otherUserName: book.ownerName,
                                otherUserImage: null,
                                initialMessage:
                                    "Hi, I am interested in your book '${book.title}'",
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                        label: Text("Ask", style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          String rawPrice = book.price?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
                          double amount = double.tryParse(rawPrice) ?? 0.0;
                          if (amount > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceScreen(
            book: book,
          ),
        ),
      );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invalid price")),
                            );
                          }
                        },
                        icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        label: Text("Buy Now", style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}