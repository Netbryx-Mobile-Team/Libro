import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/vendor/view/screens/AllBooksScreen.dart';
import 'package:libro/features/vendor/view/screens/add_book_to_store_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/filter_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedGenre = "All"; // Example filter

  // ------------------ STREAM FOR STORE BOOKS WITH LIMIT 10 ------------------
  Stream<QuerySnapshot> _getStoreBooks() {
    return FirebaseFirestore.instance
        .collection('books_sell')
        .where('storeId', isEqualTo: widget.store.uid)
        .orderBy('uploadDate', descending: true)
        .limit(10) // ✅ Limit to 10 books
        .snapshots();
  }

  // ------------------ SAFE BASE64 DECODER ------------------
  Image? _imageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      if (base64String.contains(',')) base64String = base64String.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      print("Error decoding base64 image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddBookToStoreScreen(storeId: widget.store.uid)),
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
            // --- SEARCH BAR + FILTER BUTTON ---
            Padding(
              padding: EdgeInsets.all(AppDimens.kPadding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search books...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primaryColor),
                        contentPadding: EdgeInsets.symmetric(vertical: 0.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FilterScreen()),
                      );
                      if (result != null) {
                        setState(() => _selectedGenre = result);
                      }
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.filter_list,
                          color: AppColors.primaryColor),
                    ),
                  ),
                ],
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
                            : Image.asset(AppAssets.storeImagePlaceholder,
                                fit: BoxFit.contain),
                      ),
                    ),
                    gapH20,

                    // Store name & address
                    Text(widget.store.shopName,
                        style: AppStyles.headingLarge.copyWith(fontSize: 24.sp)),
                    gapH8,
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        gapW4,
                        Expanded(
                          child: Text(widget.store.shopAddress,
                              style:
                                  AppStyles.bodySmall.copyWith(fontSize: 12.sp)),
                        ),
                      ],
                    ),
                    gapH16,

                    // Shop description
                    Text("Shop Description",
                        style: AppStyles.headingMedium
                            .copyWith(fontWeight: FontWeight.bold, fontSize: 18.sp)),
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
                    Text("Books in Store",
                        style: AppStyles.headingMedium.copyWith(fontSize: 18.sp)),
                    gapH16,

                    StreamBuilder<QuerySnapshot>(
                      stream: _getStoreBooks(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                          return const Center(child: Text("No books added yet."));
                        }

                        final books = snapshot.data!.docs
                            .map((doc) => BookModel.fromMap(
                                doc.data() as Map<String, dynamic>, doc.id))
                            .where((book) {
                          final matchesSearch = book.title
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase());
                          final matchesGenre = _selectedGenre == "All" ||
                              book.genres
                                  .map((e) => e.toLowerCase())
                                  .contains(_selectedGenre.toLowerCase());
                          return matchesSearch && matchesGenre;
                        }).toList();

                        if (books.isEmpty) {
                          return const Center(child: Text("No matching books."));
                        }

                        final topBooks = books.take(10).toList();

                        return Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topBooks.length,
                              separatorBuilder: (_, __) => gapH12,
                              itemBuilder: (context, index) {
                                final book = topBooks[index];
                                final bookImage = _imageFromBase64(
                                    book.bookImagesBase64.isNotEmpty
                                        ? book.bookImagesBase64.first
                                        : null);
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r)),
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
                                    title: Text(book.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
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
                            ),

                            // ✅ View All Button
                            if (books.length > 10)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25.r)),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24.w, vertical: 12.h),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AllBooksScreen(
                                            storeId: widget.store.uid,
                                            searchController: _searchController,
                                            selectedGenre: _selectedGenre,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text("View All Books"),
                                  ),
                                ),
                              ),
                          ],
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
