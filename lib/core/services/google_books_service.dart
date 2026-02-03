import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/read_book_model.dart';

// Provider create kar rahe hen taake Home Screen pe use kar saken
final googleBooksProvider = FutureProvider<List<Items>>((ref) async {
  final service = GoogleBooksService();
  return service.fetchFreeBooks();
});

class GoogleBooksService {
  // Free ebooks query related to programming/fiction/general
  final String _baseUrl =
      "https://www.googleapis.com/books/v1/volumes?q=flutter&filter=free-ebooks&maxResults=10";

  Future<List<Items>> fetchFreeBooks() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final readBook = ReadBook.fromJson(data);
        return readBook.items ?? [];
      } else {
        throw Exception("Failed to load books");
      }
    } catch (e) {
      throw Exception("Error fetching books: $e");
    }
  }
}
