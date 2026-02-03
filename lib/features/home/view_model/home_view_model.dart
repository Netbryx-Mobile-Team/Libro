import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/repositories/book_repository.dart';
import 'package:libro/shared/providers/app_providers.dart';

// State to hold the list of books and pagination info
class HomeState {
  final List<BookModel> books;
  final bool isLoading;
  final DocumentSnapshot? lastDocument; // For Firestore pagination
  final bool hasMore;

  HomeState({
    this.books = const [],
    this.isLoading = false,
    this.lastDocument,
    this.hasMore = true,
  });

  HomeState copyWith({
    List<BookModel>? books,
    bool? isLoading,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return HomeState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final BookRepository _bookRepository;
  final int _pageSize = 10; // 10 books per page
String? location;
String? datePosted;      // e.g. "14-05-2025" or use DateTime
int views = 0;
int shares = 0;
  HomeViewModel(this._bookRepository) : super(HomeState()) {
    loadBooks(isRefresh: true);
  }

  Future<void> loadBooks({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (!isRefresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final startAfter = isRefresh ? null : state.lastDocument;

      // We fetch from 'books_sell' by default for Home, or you can merge lists.
      // Assuming we want to show 'Sell' items primarily on home.
      final newBooks = await _bookRepository.fetchPaginatedBooks(
        'books_sell',
        _pageSize,
        startAfter: startAfter,
      );

      // Since BookRepository returns List<BookModel>, we need to handle DocumentSnapshots internally in Repo
      // OR for simplicity in this architecture, we just rely on the list.
      // Note: To strictly implement "Page 1 of 10" style navigation (Next/Prev buttons),
      // we usually fetch by offset or keep track of pages locally.
      // Since Firestore is cursor-based, "Next/Prev" button logic is best handled by
      // keeping a history of 'lastDocuments' or just appending to a list for infinite scroll.
      // Here we implement the Append logic for infinite scroll style, adaptable to pages.

      if (isRefresh) {
        state = state.copyWith(
          books: newBooks,
          isLoading: false,
          hasMore: newBooks.length == _pageSize,
          // Note: Capturing lastDocument would require changing Repo return type to a Wrapper.
          // For now, we assume simple list reloading for the buttons.
        );
      } else {
        state = state.copyWith(
          books: [...state.books, ...newBooks],
          isLoading: false,
          hasMore: newBooks.length == _pageSize,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Handle error
    }
  }
}

// Provider
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  final repo = ref.watch(
    bookRepositoryProvider,
  ); // Assuming you created this in app_providers.dart
  return HomeViewModel(repo);
});
