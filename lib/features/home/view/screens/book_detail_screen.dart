import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/features/payment/invoice.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../exports.dart';
import '../../../chat/view/screens/chat_screen.dart';
import '../../../favorites/view_model/favorites_view_model.dart';
import '../../../subscription/view/screens/jazzcash_payment_screen.dart';
import 'package:libro/shared/providers/firebase_providers.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // NEW
import 'package:libro/core/models/book_model.dart';

Future<String> _getOwnerName(dynamic widget) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.book.sellerUid)
      .get();

  if (!doc.exists) return "Unknown Owner";

  return doc.data()?['name'] ?? "Unknown Owner";
}

class BookDetailScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool? localFav;
String _formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}

  bool get isVendorSale {
    final priceStr = widget.book.price;
    if (priceStr == null || priceStr.isEmpty) return false;
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return (double.tryParse(cleaned) ?? 0) > 0;
  }

  bool get isOwner {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == widget.book.sellerUid;
  }

  @override
  Widget build(BuildContext context) {
    final storageService = ref.watch(storageServiceProvider);
    final currentUser = ref.watch(authStateChangesProvider).value;
    final favoritesState = ref.watch(favoritesViewModelProvider);

    final bool isFav = localFav ??
        favoritesState.maybeWhen(
          data: (list) => list.any((b) => b.id == widget.book.id),
          orElse: () => false,
        );

    final mainImage = widget.book.bookImagesBase64.isNotEmpty
        ? widget.book.bookImagesBase64.first
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 48.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: isOwner
              ? _buildOwnerControls(context)
              : _buildBuyerControls(context, currentUser, isFav),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320.h,
              child: mainImage != null
                  ? Image(
                      image: storageService
                          .imageFromBase64String(mainImage)
                          .image,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(AppAssets.placeholderImage),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 88.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                /// TITLE
                Text(
                  widget.book.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 12.h),

                /// LOCATION + DATE
// In your book card or detail screen
Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                       widget.book.location ?? 'Not provided',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                   const Spacer(),
Text(
  widget.book.uploadDate != null
      ? _formatDate(widget.book.uploadDate!)
      : "Unknown date",
  style: const TextStyle(fontSize: 13, color: Colors.grey),
),

                    ],
                  ),

                SizedBox(height: 24.h),

                /// DETAILS BOX
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Details",
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: [
                          _detailChip(
                              "Condition", widget.book.condition ?? "Used"),
                          _detailChip(
                              "Genre", widget.book.type ?? "Fiction"),
                          
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                /// DESCRIPTION BOX
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF26A69A).withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        widget.book.description.isEmpty
                            ? "No description provided..."
                            : widget.book.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                      SizedBox(height: 16.h),

      /// OWNER NAME
      FutureBuilder<String>(
        future: _getOwnerName(widget),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text(
              "Loading owner...",
              style: TextStyle(color: Colors.grey),
            );
          }

          return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    /// OWNER HEADING
    Text(
      "Owner",
      style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
    ),

    SizedBox(height: 6.h),

    /// OWNER NAME ROW
    Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: 18,
          color: Color(0xFF26A69A),
        ),
        const SizedBox(width: 6),
        Text(
          "${snapshot.data}",
          style: TextStyle(
            fontSize: 14.sp,        // normal size
            fontWeight: FontWeight.bold, // bold name
            color: Colors.black87,
          ),
        ),
      ],
    ),
  ],
);

        },
      ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// DETAIL CHIP
  Widget _detailChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF26A69A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF26A69A)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12.5.sp),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                color: Color(0xFF26A69A),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  /// OWNER CONTROLS
  Widget _buildOwnerControls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 34.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              "Your Ad",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 11.5.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Go to My Ads to manage/delete this.")),
          ),
          child: Container(
            height: 34.h,
            width: 34.h,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(Icons.delete_outline,
                color: Colors.red, size: 18),
          ),
        ),
      ],
    );
  }

  /// BUYER CONTROLS
  Widget _buildBuyerControls(
      BuildContext context, User? currentUser, bool isFav) {
    return Row(
      children: [
        SizedBox(
          height: 36.h,
          child: OutlinedButton(
            onPressed: () => _handleChatOrQA(context, currentUser),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF26A69A), width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              backgroundColor: const Color(0xFF26A69A).withOpacity(0.08),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: const Color(0xFF26A69A), size: 15.sp),
                SizedBox(width: 6.w),
                Text(
                  isVendorSale ? "Ask" : "Chat",
                  style: TextStyle(
                    color: const Color(0xFF26A69A),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: ElevatedButton(
            onPressed: currentUser == null
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please login first")),
                    )
                : () {
                    if (isVendorSale) {
                      _handleBuyNow(context, currentUser);
                    } else {
                      _handleExchangeRequest(context, currentUser);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              minimumSize: Size(double.infinity, 36.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
            ),
            child: Text(
              isVendorSale ? "Buy Now" : "Request Exchange",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        InkWell(
          onTap: currentUser == null
              ? null
              : () {
                  setState(() {
                    localFav = !isFav;
                  });
                  ref
                      .read(favoritesViewModelProvider.notifier)
                      .toggleFavorite(widget.book.id);
                },
          child: Container(
            height: 36.h,
            width: 36.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.grey,
              size: 19.sp,
            ),
          ),
        ),
      ],
    );
  }

/// BUY NOW → PAYMENT → RATING
/// BUY NOW → PAYMENT → RATING
void _handleBuyNow(BuildContext context, User? currentUser) {
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login first")),
    );
    return;
  }

  // Navigate to Invoice first
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InvoiceScreen(
        book: widget.book,
      ),
    ),
  );
}



  Future<void> _handleExchangeRequest(
      BuildContext context, User? currentUser) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('sellerUid', isEqualTo: currentUser.uid)
        .get();

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("No Books Found"),
          content: const Text(
              "You need to upload a book first to make an exchange request."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Select Book to Exchange"),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.docs.length,
            itemBuilder: (ctx, index) {
              final userBook = snapshot.docs[index].data();
              final title = userBook['title']?.toString() ?? 'Unknown Book';

              return ListTile(
                leading: const Icon(Icons.book, color: Color(0xFF26A69A)),
                title: Text(title),
                subtitle: Text(userBook['condition']?.toString() ?? 'Used'),
                onTap: () {
                  Navigator.pop(c);

                  final message =
                      "Hi, I would like to exchange your book '${widget.book.title}' "
                      "with my '$title'. Is it available?";

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: '',
                        otherUserId: widget.book.sellerUid,
                        otherUserName: "Reader",
                        otherUserImage: null,
                        initialMessage: message,
                      ),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Offer sent via chat!")),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
        ],
      ),
    );
  }

 void _handleChatOrQA(BuildContext context, User? currentUser) {
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login to chat")),
    );
    return;
  }

  if (isVendorSale) {
    // Open chat directly with predefined messages
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: '',
          otherUserId: widget.book.sellerUid,
          otherUserName: "Reader",
          bookTitle: widget.book.title, initialMessage: '', // Pass the book title
        ),
      ),
    );
  } else {
    // Normal chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: '',
          otherUserId: widget.book.sellerUid,
          otherUserName: "Reader",
          bookTitle: widget.book.title, initialMessage: '', // Optional for buyer chat
        ),
      ),
    );
  }
}

  void _showVendorQABottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text("Ask Seller",
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildQAItem(context, "Is this book available?", "Yes, this item is in stock."),
              _buildQAItem(context, "What is the condition?",
                  "Condition: ${widget.book.condition ?? 'Used'}"),
              _buildQAItem(context, "Is price negotiable?", "No, fixed price."),
              _buildQAItem(context, "Delivery time?", "2-3 Business Days."),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQAItem(BuildContext context, String q, String a) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(q, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(q),
                content: Text(a),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK")),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// -----------------------------
// NEW: StoreRatingScreen
class StoreRatingScreen extends StatefulWidget {
  final String storeId;
  final VoidCallback onRatingSubmitted;

  const StoreRatingScreen({
    super.key,
    required this.storeId,
    required this.onRatingSubmitted, required BookModel book,
  });

  @override
  State<StoreRatingScreen> createState() => _StoreRatingScreenState();
}

class _StoreRatingScreenState extends State<StoreRatingScreen> {
  double _rating = 5.0; // default rating
  bool _isSubmitting = false; // prevent double click

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate the Store"),
        backgroundColor: const Color(0xFF26A69A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Please rate the store",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    _rating >= starIndex ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = starIndex.toDouble();
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Rating", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final storeRef = FirebaseFirestore.instance.collection('stores').doc(widget.storeId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(storeRef);
        final data = snapshot.data() ?? {};

        double totalRating = (data['totalRating'] ?? 0).toDouble();
        int ratingCount = (data['ratingCount'] ?? 0);

        totalRating += _rating;
        ratingCount += 1;

        transaction.set(storeRef, {
          'totalRating': totalRating,
          'ratingCount': ratingCount,
          'averageRating': totalRating / ratingCount,
        }, SetOptions(merge: true));
      });

      // After successful submission, trigger payment screen
      widget.onRatingSubmitted();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit rating: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}