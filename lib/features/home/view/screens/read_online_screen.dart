import 'package:libro/core/models/read_book_model.dart';
import 'package:libro/core/services/google_books_service.dart';
import 'package:libro/features/home/view/screens/google_book_detail_screen.dart';
import 'package:libro/exports.dart';

class ReadOnlineViewAllScreen extends ConsumerStatefulWidget {
  const ReadOnlineViewAllScreen({super.key});

  @override
  ConsumerState<ReadOnlineViewAllScreen> createState() =>
      _ReadOnlineViewAllScreenState();
}

class _ReadOnlineViewAllScreenState
    extends ConsumerState<ReadOnlineViewAllScreen> {
  // 1. FIXED: Items per page set to 20
  final int _itemsPerPage = 20;
  int _currentPage = 1;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _getTotalPages(int totalItems) {
    if (totalItems == 0) return 1;
    return (totalItems / _itemsPerPage).ceil();
  }

  List<Items> _getCurrentPageBooks(List<Items> filteredBooks) {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (startIndex >= filteredBooks.length) return [];
    if (endIndex > filteredBooks.length) {
      endIndex = filteredBooks.length;
    }

    return filteredBooks.sublist(startIndex, endIndex);
  }

  void _changePage(int newPage, int totalPages) {
    if (newPage > 0 && newPage <= totalPages) {
      setState(() {
        _currentPage = newPage;
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(googleBooksProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false, // Default back button OFF
        toolbarHeight: 110, // Height increased for 2 rows
        titleSpacing: 10, // Adjust padding
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ROW 1: Back Button + Search Bar ---
            Row(
              children: [
                // Custom Back Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(width: 10),

                // Search Field
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _currentPage = 1;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Search title...",
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.teal,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 4,
                        ), // Center text vertically
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- ROW 2: Title Centered ---
            const Text(
              "Read Online Books",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: booksAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.teal)),
        error: (error, stack) => Center(child: Text("Error: $error")),
        data: (allBooks) {
          // Filtering Logic
          final filteredBooks = allBooks.where((book) {
            final title = book.volumeInfo?.title?.toLowerCase() ?? "";
            final authors =
                book.volumeInfo?.authors?.join(" ").toLowerCase() ?? "";
            return title.contains(_searchQuery) ||
                authors.contains(_searchQuery);
          }).toList();

          if (filteredBooks.isEmpty) {
            return const Center(child: Text("No books found."));
          }

          final totalPages = _getTotalPages(filteredBooks.length);
          final currentBooks = _getCurrentPageBooks(filteredBooks);

          return RefreshIndicator(
            color: Colors.teal,
            onRefresh: () async {
              return ref.refresh(googleBooksProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              // Add +1 for Footer
              itemCount: currentBooks.length + 1,
              itemBuilder: (context, index) {
                if (index == currentBooks.length) {
                  return _buildPaginationFooter(totalPages);
                }
                final book = currentBooks[index];
                return _buildBookRowCard(book);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookRowCard(Items book) {
    final info = book.volumeInfo;
    final String title = info?.title ?? "No Title";
    final String authors = info?.authors != null && info!.authors!.isNotEmpty
        ? info.authors!.join(", ")
        : "Unknown Author";
    final String publishedDate = info?.publishedDate ?? "Unknown Date";
    final String? imageUrl =
        info?.imageLinks?.thumbnail ?? info?.imageLinks?.smallThumbnail;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleBookDetailScreen(book: book),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE on LEFT
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 90,
                  height: 130,
                  color: Colors.grey[200],
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.book, color: Colors.grey),
                        )
                      : const Icon(Icons.book, color: Colors.grey),
                ),
              ),

              const SizedBox(width: 12),

              // INFO on RIGHT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Author: $authors",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Published: $publishedDate",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GoogleBookDetailScreen(book: book),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "READ",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _changePage(_currentPage - 1, totalPages)
                : null,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: _currentPage > 1 ? Colors.teal : Colors.grey,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            "Page $_currentPage of $totalPages",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => _changePage(_currentPage + 1, totalPages)
                : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: _currentPage < totalPages ? Colors.teal : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
