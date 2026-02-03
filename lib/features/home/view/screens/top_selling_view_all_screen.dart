import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/filter_screen.dart';
import 'package:libro/features/search_and_filters/view_model/search_view_model.dart';
import 'package:libro/features/subscription/view/screens/jazzcash_payment_screen.dart';

/// ── Providers ──
final allSellingBooksProvider = StreamProvider<List<BookModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('books')
      .where('transactionType', isEqualTo: 'Sell')
      .orderBy('uploadDate', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) {
              try {
                return BookModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                debugPrint("BookModel parse error: $e");
                return null;
              }
            })
            .whereType<BookModel>()
            .toList(),
      );
});

final topSellingRecommendedProvider = StreamProvider<List<BookModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('books')
      .limit(10)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) {
              try {
                return BookModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                debugPrint("BookModel parse error: $e");
                return null;
              }
            })
            .whereType<BookModel>()
            .toList(),
      );
});

/// ── Screen ──
class TopSellingViewAllScreen extends ConsumerStatefulWidget {
  const TopSellingViewAllScreen({super.key});

  @override
  ConsumerState<TopSellingViewAllScreen> createState() =>
      _TopSellingViewAllScreenState();
}


class _TopSellingViewAllScreenState
    extends ConsumerState<TopSellingViewAllScreen> {
  final int _itemsPerPage = 20;
  int _currentPage = 1;
  String _searchQuery = "";

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(searchViewModelProvider.notifier).resetFilters();
  });
    _searchController.addListener(() {
      final newQuery = _searchController.text.toLowerCase().trim();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
          _currentPage = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ── Filter books based on search query and filters ──
  List<BookModel> _filterBooks(List<BookModel> books) {
    final searchState = ref.watch(searchViewModelProvider);

    return books.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery) ||
          (book.author?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesGenre = searchState.selectedGenres.isEmpty ||
          book.genres.any((g) => searchState.selectedGenres.contains(g));

      final matchesType = searchState.selectedTypes.isEmpty ||
          searchState.selectedTypes.contains(book.type ?? '');

      final matchesLocation = searchState.selectedLocations.isEmpty ||
          (book.location != null &&
              searchState.selectedLocations.contains(book.location));

      return matchesSearch && matchesGenre && matchesType && matchesLocation;
    }).toList();
  }

  /// ── Pagination helper ──
  List<BookModel> _getCurrentPageBooks(List<BookModel> filtered) {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _changePage(int newPage, int totalPages) {
    if (newPage >= 1 && newPage <= totalPages) {
      setState(() => _currentPage = newPage);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendedAsync = ref.watch(topSellingRecommendedProvider);
    final allBooksAsync = ref.watch(allSellingBooksProvider);
    final storage = ref.watch(storageServiceProvider);

    // Rebuild when filters change
    ref.watch(searchViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.teal,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search...",
                      prefixIcon: Icon(Icons.search, color: Colors.teal),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FilterScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allSellingBooksProvider);
          ref.invalidate(topSellingRecommendedProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Recommended Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text("You may also like", style: AppStyles.headingSmall),
              ),
              SizedBox(
                height: 220,
                child: recommendedAsync.when(
                  data: (books) => books.isEmpty
                      ? _buildEmptyRecommendation()
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: books.length,
                          itemBuilder: (context, index) =>
                              _buildRecommendationCard(
                                  context, books[index], storage),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                ),
              ),
              const SizedBox(height: 24),

              // ── All Books / Buy Now ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Buy Now", style: AppStyles.headingSmall),
              ),
              const SizedBox(height: 8),
              allBooksAsync.when(
                data: (allBooks) {
                  final filtered = _filterBooks(allBooks);
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: Text("No books found matching your filters")),
                    );
                  }
                  final totalPages = (filtered.length / _itemsPerPage).ceil();
                  final currentBooks = _getCurrentPageBooks(filtered);

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: currentBooks.length,
                        itemBuilder: (context, index) =>
                            _buildListBookCard(context, currentBooks[index], storage),
                      ),
                      if (totalPages > 1) ...[
                        const SizedBox(height: 16),
                        _buildPaginationFooter(totalPages),
                        const SizedBox(height: 40),
                      ]
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ── Helpers ──
  Widget _buildEmptyRecommendation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          "Upload books to see recommendations!",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, BookModel book, StorageService storage) {
    final imageWidget = book.bookImagesBase64.isNotEmpty
        ? storage.imageFromBase64String(book.bookImagesBase64.first)
        : Image.asset(AppAssets.placeholderImage, fit: BoxFit.cover);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(fit: BoxFit.cover, child: imageWidget),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      book.type ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBookCard(
      BuildContext context, BookModel book, StorageService storage) {
    final imageWidget = book.bookImagesBase64.isNotEmpty
        ? storage.imageFromBase64String(book.bookImagesBase64.first)
        : Image.asset(AppAssets.placeholderImage, fit: BoxFit.cover);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 120,
                child: FittedBox(fit: BoxFit.cover, child: imageWidget),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      book.type ?? 'Unknown',
                      style: TextStyle(fontSize: 12, color: Colors.teal[800]),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        book.location ?? 'Not provided',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rs.${book.price ?? '0'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String rawPrice =
                    book.price?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
                double amount = double.tryParse(rawPrice) ?? 0.0;
                if (amount > 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JazzCashPaymentScreen(
                        amount: amount,
                        productName: book.title,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid price")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Buy", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _changePage(_currentPage - 1, totalPages)
                : null,
            icon: Icon(
              Icons.arrow_back_ios,
              color: _currentPage > 1 ? Colors.teal : Colors.grey,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            "Page $_currentPage of $totalPages",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => _changePage(_currentPage + 1, totalPages)
                : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              color: _currentPage < totalPages ? Colors.teal : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
