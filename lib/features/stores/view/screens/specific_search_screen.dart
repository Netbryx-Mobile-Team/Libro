// lib/features/stores/view/screens/store_specific_search_screen.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/filter_screen.dart';
import 'package:libro/features/search_and_filters/view_model/search_view_model.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

class StoreSpecificSearchScreen extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreSpecificSearchScreen({super.key, required this.store});

  @override
  ConsumerState<StoreSpecificSearchScreen> createState() =>
      _StoreSpecificSearchScreenState();
}

class _StoreSpecificSearchScreenState
    extends ConsumerState<StoreSpecificSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';

  Stream<QuerySnapshot> _getBooksStream() {
    return FirebaseFirestore.instance
        .collection('books_sell')
        .where('storeId', isEqualTo: widget.store.uid) // ✅ Fetch all books for this store
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

    // Watch for filter changes
    ref.watch(searchViewModelProvider);
    final searchState = ref.read(searchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search in ${widget.store.shopName}...",
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FilterScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBooksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No books found in this store"));
          }

          final books = snapshot.data!.docs
              .map((doc) =>
                  BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((book) {
                final matchesQuery = query.isEmpty ||
                    book.title.toLowerCase().contains(query) ||
                    (book.author?.toLowerCase().contains(query) ?? false);

                final matchesGenre = searchState.selectedGenres.isEmpty ||
                    book.genres.any((g) => searchState.selectedGenres.contains(g));

                final matchesType = searchState.selectedTypes.isEmpty ||
                    searchState.selectedTypes.contains(book.type ?? '');

                final matchesLocation = searchState.selectedLocations.isEmpty ||
                    (book.location != null &&
                        searchState.selectedLocations.contains(book.location));

                return matchesQuery &&
                    matchesGenre &&
                    matchesType &&
                    matchesLocation;
              })
              .toList();

          if (books.isEmpty) {
            return const Center(
                child: Text("No books match your search & filters"));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: ListTile(
                  leading: book.bookImagesBase64.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.memory(
                            base64Decode(book.bookImagesBase64.first),
                            width: 50.w,
                            height: 70.h,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.book),
                  title: Text(book.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text("${book.type ?? ''} • ${book.author ?? ''}"),
                  trailing: Text(
                    "Rs. ${book.price ?? '0'}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book)),
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
