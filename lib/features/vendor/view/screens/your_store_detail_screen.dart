import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/vendor/view/screens/add_book_to_store_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/search_screen.dart';
import 'package:libro/features/vendor/view/screens/vendor_search.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

class YourStoreDetailScreen extends ConsumerStatefulWidget {
  final StoreModel store;

  const YourStoreDetailScreen({super.key, required this.store});

  @override
  ConsumerState<YourStoreDetailScreen> createState() =>
      _YourStoreDetailScreenState();
}

class _YourStoreDetailScreenState
    extends ConsumerState<YourStoreDetailScreen> {

  // ------------------ STREAM FOR STORE BOOKS ------------------
  Stream<QuerySnapshot> _getStoreBooks() {
    return FirebaseFirestore.instance
        .collection('books_sell') // Make sure this matches your vendor upload
        .where('storeId', isEqualTo: widget.store.uid)
        .orderBy('uploadDate', descending: true)
        .snapshots();
  }

  // ------------------ SAFE BASE64 DECODER ------------------
  Image? _imageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1]; // remove data:image/... prefix
      }
      final bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      print("Error decoding base64 image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final currentUser = ref.watch(authRepositoryProvider).getCurrentUser();
    final isMyStore = currentUser?.uid == widget.store.uid;

    final imageBase64 = widget.store.shopImagesBase64.isNotEmpty
        ? widget.store.shopImagesBase64.first
        : null;

    return Scaffold(
      backgroundColor: whiteColor,
      floatingActionButton: isMyStore
          ? FloatingActionButton.extended(
              onPressed: () {
                navigation.push(
                  context,
                  AddBookToStoreScreen(storeId: widget.store.uid),
                );
              },
              label: const Text("Add Book"),
              icon: const Icon(Icons.add),
              backgroundColor: AppColors.primaryColor,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // --- SEARCH BAR ---
            Padding(
              padding: EdgeInsets.all(AppDimens.kPadding),
              child: GestureDetector(
                onTap: () {
                  navigation.push(
                    context,
                    VendorStoreSearchScreenForVendor(storeId: widget.store.uid),
                  );
                },
                child: Container(
                  height: 45.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: AppColors.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Search books...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- STORE DETAILS ---
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store image
                    SizedBox(
                      height: 280.h,
                      width: double.infinity,
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: imageBase64 != null
                            ? _imageFromBase64(imageBase64)
                            : Image.asset(
                                AppAssets.storeImagePlaceholder,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    gapH20,

                    // Store name & address
                    Text(
                      widget.store.shopName,
                      style: AppStyles.headingLarge.copyWith(fontSize: 24.sp),
                    ),
                    gapH8,
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        gapW4,
                        Expanded(
                          child: Text(
                            widget.store.shopAddress,
                            style: AppStyles.bodySmall.copyWith(fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                    gapH16,

                    // Shop description
                    Text(
                      "Shop Description",
                      style: AppStyles.headingMedium.copyWith(
                          fontWeight: FontWeight.bold, fontSize: 18.sp),
                    ),
                    gapH8,
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.teal, width: 1.5),
                      ),
                      child: Text(
                        widget.store.shopDescription.isNotEmpty
                            ? widget.store.shopDescription
                            : "All books available (courses, novels, stories, languages)\nBest price with best dealing",
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    gapH24,

                    // Books list
                    Text(
                      "Books in Store",
                      style: AppStyles.headingMedium.copyWith(fontSize: 18.sp),
                    ),
                    gapH16,
                    StreamBuilder<QuerySnapshot>(
                      stream: _getStoreBooks(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error loading books: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("No books added yet."));
                        }

                        final books = snapshot.data!.docs
                            .map((doc) => BookModel.fromMap(
                                doc.data() as Map<String, dynamic>, doc.id))
                            .toList();

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: books.length,
                          separatorBuilder: (_, __) => gapH12,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            final bookImage = _imageFromBase64(
                              book.bookImagesBase64.isNotEmpty
                                  ? book.bookImagesBase64.first
                                  : null,
                            );

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(10.w),
                                leading: Container(
                                  width: 50.w,
                                  height: 70.w,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: bookImage ??
                                        const Icon(Icons.book,
                                            color: AppColors.primaryColor),
                                  ),
                                ),
                                title: Text(
                                  book.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle:
                                    Text("Genre: ${book.genres.join(", ")}"),
                                trailing: Text(
                                  "Rs. ${book.price ?? 'N/A'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    gapH40,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
