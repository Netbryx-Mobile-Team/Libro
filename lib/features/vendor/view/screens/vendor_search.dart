import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/filter_screen.dart';
import 'package:libro/features/search_and_filters/view_model/search_view_model.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

class VendorStoreSearchScreenForVendor extends ConsumerStatefulWidget {
  final String storeId;

  const VendorStoreSearchScreenForVendor({super.key, required this.storeId});

  @override
  ConsumerState<VendorStoreSearchScreenForVendor> createState() =>
      _VendorStoreSearchScreenForVendorState();
}

class _VendorStoreSearchScreenForVendorState
    extends ConsumerState<VendorStoreSearchScreenForVendor> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';

  Stream<QuerySnapshot> _getBooks() {
    // Vendor Store Search
    return FirebaseFirestore.instance
        .collection('books_sell')
        .where('storeId', isEqualTo: widget.storeId)
        .orderBy('uploadDate', descending: true)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        query = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final searchState = ref.watch(searchViewModelProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppStyles.bodyMedium.copyWith(color: whiteColor),
          decoration: const InputDecoration(
            hintText: "Search books in this store...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: whiteColor),
            onPressed: () {
              navigation.push(context, const FilterScreen());
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text("Error loading books"));
          }

          final allBooks = snapshot.data!.docs
              .map((doc) =>
                  BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // Apply search query and filters
          final filteredBooks = allBooks.where((b) {
            final matchesQuery = query.isEmpty ||
                b.title.toLowerCase().contains(query) ||
                (b.author?.toLowerCase().contains(query) ?? false);

            final matchesGenre = searchState.selectedGenres.isEmpty ||
                b.genres.any((g) => searchState.selectedGenres.contains(g));

            final matchesType = searchState.selectedTypes.isEmpty ||
                searchState.selectedTypes.contains(b.type ?? '');

            final matchesLocation = searchState.selectedLocations.isEmpty ||
                (b.location != null &&
                    searchState.selectedLocations.contains(b.location));

            return matchesQuery && matchesGenre && matchesType && matchesLocation;
          }).toList();

          if (filteredBooks.isEmpty) {
            return const Center(child: Text("No books found."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppDimens.kPadding),
            itemCount: filteredBooks.length,
            separatorBuilder: (_, __) => gapH12,
            itemBuilder: (context, index) {
              final book = filteredBooks[index];
              final image = book.bookImagesBase64.isNotEmpty
                  ? storage.imageFromBase64String(book.bookImagesBase64.first)
                  : null;

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
                    child: image ?? const Icon(Icons.book, color: AppColors.primaryColor),
                  ),
                  title: Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    book.genres.isNotEmpty
                        ? "Genre: ${book.genres.join(", ")}"
                        : "No genre",
                  ),
                  trailing: Text(
                    "Rs. ${book.price ?? 0}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  onTap: () => navigation.push(
                    context,
                    BookDetailScreen(book: book),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
