import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final rw6jYohNVBeVZFxAjEUHqSbjor6i8pNm4h = Provider(
  (ref) => RecommendationService(),
);

// Provider to fetch recommended books
final recommendedBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  final service = ref.watch(rw6jYohNVBeVZFxAjEUHqSbjor6i8pNm4h);
  final user = FirebaseAuth.instance.currentUser;

  // Agar user login nahi hai, to Top Selling ya Recent books dikha do (Optional)
  if (user == null) return [];

  // 1. Get User Genres History
  final genres = await service.getUserPreferredGenres(user.uid);

  if (genres.isEmpty) {
    // Agar koi history nahi, to khali list return karo
    return [];
  }

  // 2. Get Books matching those genres
  return service.getRecommendedBooks(genres);
});

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NEW FUNCTION: Call this when user opens a book ---
  Future<void> logBookView(String userId, BookModel book) async {
    try {
      // Hum user ki 'clicks' collection mein genre save karenge
      // Ek user ke pass multiple genres ho sakte hain
      final userClicksCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('clicks');

      // Add Main Type (e.g., Fiction)
      await userClicksCollection.add({
        'genre': book.type,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Agar genres list bhi hai (e.g., Horror, Sci-Fi) to wo bhi save karein
      for (var genre in book.genres) {
        await userClicksCollection.add({
          'genre': genre,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error logging view: $e");
    }
  }

  // Fetch preferred genres based on user clicks
  Future<List<String>> getUserPreferredGenres(String userId) async {
    try {
      final userClicksCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('clicks')
          .orderBy('timestamp', descending: true) // Latest clicks first
          .limit(20); // Sirf last 20 clicks dekho taake interest fresh rahe

      final querySnapshot = await userClicksCollection.get();

      List<String> genres = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('genre')) {
          genres.add(data['genre']);
        }
      }
      return genres.toSet().toList(); // Remove duplicates
    } catch (e) {
      print("Error fetching genres: $e");
      return [];
    }
  }

  // Fetch recommended books based on genres
  Future<List<BookModel>> getRecommendedBooks(
    List<String> preferredGenres,
  ) async {
    try {
      // Saari books leao (Real app mein ise optimize karna padega, abhi ke liye theek hai)
      final querySnapshot = await _firestore
          .collection('books_sell')
          .orderBy(
            'uploadDate',
            descending: true,
          ) // Descending Order (Latest First)
          .get();

      List<BookModel> recommendedBooks = [];

      for (var doc in querySnapshot.docs) {
        final bookData = doc.data();
        final book = BookModel.fromMap(bookData, doc.id);

        // Check 1: Kya Book ka Type user ko pasand hai?
        bool matchFound = preferredGenres.contains(book.type);

        // Check 2: Kya Book ka koi Genre user ko pasand hai?
        if (!matchFound) {
          for (var g in book.genres) {
            if (preferredGenres.contains(g)) {
              matchFound = true;
              break;
            }
          }
        }

        if (matchFound) {
          recommendedBooks.add(book);
        }
      }
      return recommendedBooks;
    } catch (e) {
      print("Error fetching recommendations: $e");
      return [];
    }
  }
}
