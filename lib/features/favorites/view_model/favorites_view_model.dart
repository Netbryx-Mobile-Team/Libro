import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/exports.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

// State Notifier to manage Favorites List
class FavoritesViewModel extends StateNotifier<AsyncValue<List<BookModel>>> {
  final String? userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FavoritesViewModel(this.userId) : super(const AsyncValue.loading()) {
    if (userId != null) {
      _fetchFavorites();
    }
  }

  // Fetch Favorites
  Future<void> _fetchFavorites() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      if (snapshot.docs.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      List<BookModel> favoriteBooks = [];

      // Fetch full book details for each favorite ID
      for (var doc in snapshot.docs) {
        final bookId = doc.id;
        // Check both collections (Rent/Sell) - Simplified logic assuming we search all
        // In a real app, storing the 'collectionType' in favorites is better.
        // Here we attempt to find the book in 'books_sell' first, then others.
        // For optimization, we will check 'books_sell' primarily.
        final bookDoc = await _firestore
            .collection('books_sell')
            .doc(bookId)
            .get();

        if (bookDoc.exists) {
          favoriteBooks.add(BookModel.fromMap(bookDoc.data()!, bookDoc.id));
        } else {
          // Try rent collection if not found in sell
          final rentDoc = await _firestore
              .collection('books_rent')
              .doc(bookId)
              .get();
          if (rentDoc.exists) {
            favoriteBooks.add(BookModel.fromMap(rentDoc.data()!, rentDoc.id));
          }
        }
      }
      state = AsyncValue.data(favoriteBooks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Toggle Favorite
  Future<void> toggleFavorite(String bookId) async {
    if (userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(bookId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete(); // Remove
    } else {
      await docRef.set({'addedAt': FieldValue.serverTimestamp()}); // Add
    }
    // Refresh list
    _fetchFavorites();
  }

  // Check if book is favorite (Helper for UI)
  bool isFavorite(String bookId) {
    return state.value?.any((book) => book.id == bookId) ?? false;
  }
}

// Provider
final favoritesViewModelProvider =
    StateNotifierProvider.autoDispose<
      FavoritesViewModel,
      AsyncValue<List<BookModel>>
    >((ref) {
      final user = ref.watch(authStateChangesProvider).value;
      return FavoritesViewModel(user?.uid);
    });
