// lib/core/repositories/book_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/services/firestore_service.dart';

abstract class BaseBookRepository {
  Future<String> uploadBook(BookModel book);
  Future<List<BookModel>> fetchPaginatedBooks(
    String collection,
    int limit, {
    DocumentSnapshot? startAfter,
  });
  Stream<List<BookModel>> streamCollection(String collection);
  // Add functions for filtering/searching later
}

class BookRepository implements BaseBookRepository {
  final FirestoreService _firestoreService;
  final String _sellCollection = 'books_sell';
  final String _rentCollection = 'books_rent';
  final String _exchangeCollection = 'books_exchange';

  BookRepository(this._firestoreService);

  // --- Upload Logic (Used by Upload ViewModels) ---

  @override
  Future<String> uploadBook(BookModel book) async {
    final String collection;
    if (book.price != null && book.exchangeBookTitle == null) {
      // It is either a Sell or Rent upload
      collection = book.price!.contains('week')
          ? _rentCollection
          : _sellCollection;
    } else if (book.exchangeBookTitle != null) {
      // It is an Exchange upload
      collection = _exchangeCollection;
    } else {
      throw Exception("Invalid book model: Cannot determine collection type.");
    }

    return await _firestoreService.addDocument(
      collection: collection,
      data: book.toMap(),
    );
  }

  // --- Fetching Logic (Used by Home ViewModels) ---

  // Fetches a stream of all documents from a specific collection
  @override
  Stream<List<BookModel>> streamCollection(String collection) {
    return _firestoreService
        .streamCollection(
          collection: collection,
          queryBuilder: (query) =>
              query.orderBy('uploadDate', descending: true),
        )
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BookModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  // Fetches data for the pagination requirement ("10 books per page")
  @override
  Future<List<BookModel>> fetchPaginatedBooks(
    String collection,
    int limit, {
    DocumentSnapshot? startAfter,
  }) async {
    final snapshot = await _firestoreService.getPaginatedCollection(
      collection: collection,
      limit: limit,
      startAfterDocument: startAfter,
      queryBuilder: (query) => query.orderBy('uploadDate', descending: true),
    );

    return snapshot.docs
        .map(
          (doc) =>
              BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }
}
