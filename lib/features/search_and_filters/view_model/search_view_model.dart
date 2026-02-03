import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/models/book_model.dart';

// State Class
class SearchState {
  final String query;
  final Set<String> selectedLocations;
  final Set<String> selectedGenres;
  final Set<String> selectedTypes;
  final List<BookModel> results;
  final bool isLoading;

  SearchState({
    this.query = '',
    this.selectedLocations = const {},
    this.selectedGenres = const {},
    this.selectedTypes = const {},
    this.results = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    String? query,
    Set<String>? selectedLocations,
    Set<String>? selectedGenres,
    Set<String>? selectedTypes,
    List<BookModel>? results,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedLocations: selectedLocations ?? this.selectedLocations,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ViewModel
class SearchViewModel extends StateNotifier<SearchState> {
  SearchViewModel() : super(SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
    performSearch();
  }

  void toggleLocation(String location) {
    final newSet = Set<String>.from(state.selectedLocations);
    newSet.contains(location) ? newSet.remove(location) : newSet.add(location);
    state = state.copyWith(selectedLocations: newSet);
    performSearch();
  }

  void toggleGenre(String genre) {
    final newSet = Set<String>.from(state.selectedGenres);
    newSet.contains(genre) ? newSet.remove(genre) : newSet.add(genre);
    state = state.copyWith(selectedGenres: newSet);
    performSearch();
  }

  void toggleType(String type) {
    final newSet = Set<String>.from(state.selectedTypes);
    newSet.contains(type) ? newSet.remove(type) : newSet.add(type);
    state = state.copyWith(selectedTypes: newSet);
    performSearch();
  }

  void resetFilters() {
    state = state.copyWith(
      selectedLocations: {},
      selectedGenres: {},
      selectedTypes: {},
      query: '',
      results: [],
    );
  }

  Future<void> performSearch() async {
    state = state.copyWith(isLoading: true);

    try {
      // ✅ Fetch all (safe & reliable)
      final snapshot = await FirebaseFirestore.instance
          .collection('books_sell')
          .get();

      final lowerQuery = state.query.trim().toLowerCase();

      List<BookModel> books = snapshot.docs
          .map(
            (doc) =>
                BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          // 🔑 CASE-INSENSITIVE SEARCH
          .where((book) {
            if (lowerQuery.isEmpty) return true;
            return book.title.toLowerCase().contains(lowerQuery);
          })
          .toList();

      // Filters (unchanged)
      if (state.selectedLocations.isNotEmpty) {
        books = books
            .where((b) => state.selectedLocations.contains(b.address))
            .toList();
      }

      if (state.selectedGenres.isNotEmpty) {
        books = books
            .where(
              (b) => b.genres.any(
                (g) => state.selectedGenres.contains(g),
              ),
            )
            .toList();
      }

      if (state.selectedTypes.isNotEmpty) {
        books =
            books.where((b) => state.selectedTypes.contains(b.type)).toList();
      }

      state = state.copyWith(results: books, isLoading: false);
    } catch (e) {
      print("Search Error: $e");
      state = state.copyWith(isLoading: false, results: []);
    }
  }
}

final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, SearchState>((ref) {
  return SearchViewModel();
});
