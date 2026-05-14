import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/exports.dart';

class AllBooksScreen extends ConsumerStatefulWidget {
  final String storeId;
  final TextEditingController searchController;
  final String selectedGenre;

  const AllBooksScreen({
    super.key,
    required this.storeId,
    required this.searchController,
    required this.selectedGenre,
  });

  @override
  ConsumerState<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends ConsumerState<AllBooksScreen> {
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

  Stream<QuerySnapshot> _getAllBooks() {
    return FirebaseFirestore.instance
        .collection('books_sell')
        .where('storeId', isEqualTo: widget.storeId)
        .orderBy('uploadDate', descending: true)
        .snapshots(); // NO limit
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Books"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAllBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading books: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No books available."));
          }

          final books = snapshot.data!.docs
              .map((doc) => BookModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .where((book) {
            final matchesSearch = book.title
                .toLowerCase()
                .contains(widget.searchController.text.toLowerCase());
            final matchesGenre = widget.selectedGenre == "All" ||
                book.genres
                    .map((e) => e.toLowerCase())
                    .contains(widget.selectedGenre.toLowerCase());
            return matchesSearch && matchesGenre;
          }).toList();

          if (books.isEmpty) {
            return const Center(child: Text("No matching books."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: books.length,
            separatorBuilder: (_, __) => gapH12,
            itemBuilder: (context, index) {
              final book = books[index];
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
                          const Icon(Icons.book, color: AppColors.primaryColor),
                    ),
                  ),
                  title: Text(book.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Genre: ${book.genres.join(", ")}"),
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
    );
  }
}
