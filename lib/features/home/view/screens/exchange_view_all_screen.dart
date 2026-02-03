import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/features/chat/view/screens/chat_screen.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';
import 'package:libro/features/search_and_filters/view/screens/filter_screen.dart';
import 'package:libro/features/search_and_filters/view_model/search_view_model.dart';
import 'package:libro/exports.dart';

// --- PROVIDER ---
final exchangeBooksStreamProvider = StreamProvider<List<BookModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('books')
      .where('transactionType', isEqualTo: 'Exchange')
      .orderBy('uploadDate', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) {
              try {
                return BookModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((e) => e != null)
            .cast<BookModel>()
            .toList(),
      );
});

class ExchangeViewAllScreen extends ConsumerStatefulWidget {
  const ExchangeViewAllScreen({super.key});

  @override
  ConsumerState<ExchangeViewAllScreen> createState() =>
      _ExchangeViewAllScreenState();
}

class _ExchangeViewAllScreenState
    extends ConsumerState<ExchangeViewAllScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";

  final int _itemsPerPage = 20;
  int _currentPage = 1;
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(searchViewModelProvider.notifier).resetFilters();
  });
}

  // --- FILTER & SEARCH LOGIC ---
  List<BookModel> _processBooks(
    List<BookModel> allBooks,
    SearchState searchState,
  ) {
    return allBooks.where((book) {
      final matchesSearch =
          book.title.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesLocation =
          searchState.selectedLocations.isEmpty ||
          searchState.selectedLocations.contains(book.location);

      final matchesGenre =
          searchState.selectedGenres.isEmpty ||
          searchState.selectedGenres.contains(book.genres);

      final matchesType =
          searchState.selectedTypes.isEmpty ||
          searchState.selectedTypes.contains(book.type);

      bool matchesChip = true;
      if (_selectedFilter != "All") {
        matchesChip = book.type == _selectedFilter;
      }

      return matchesSearch &&
          matchesLocation &&
          matchesGenre &&
          matchesType &&
          matchesChip;
    }).toList();
  }

  int _getTotalPages(int totalItems) {
    if (totalItems == 0) return 1;
    return (totalItems / _itemsPerPage).ceil();
  }

  List<BookModel> _getCurrentPageBooks(List<BookModel> filteredBooks) {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (startIndex >= filteredBooks.length) return [];
    if (endIndex > filteredBooks.length) endIndex = filteredBooks.length;
    return filteredBooks.sublist(startIndex, endIndex);
  }

  void _changePage(int newPage, int totalPages) {
    if (newPage > 0 && newPage <= totalPages) {
      setState(() => _currentPage = newPage);
    }
  }

  // --- EXCHANGE ACTION ---
  Future<void> _handleExchangeAction(BookModel targetBook) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('sellerUid', isEqualTo: currentUser.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("No Books Found"),
          content: const Text(
            "You need to upload a book first to make an exchange request.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Select Book to Exchange"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (ctx, index) {
              final userBook = snapshot.docs[index].data();
              return ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: Text(userBook['title'] ?? 'Unknown'),
                subtitle: Text(userBook['condition'] ?? 'Used'),
                onTap: () {
                  Navigator.pop(c);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: '',
                        otherUserId: targetBook.sellerUid,
                        otherUserName: targetBook.ownerName,
                        otherUserImage: null,
                        initialMessage:
                            "Hi, I would like to exchange your book '${targetBook.title}' with my '${userBook['title']}'. Is it available?",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exchangeBooksAsync = ref.watch(exchangeBooksStreamProvider);
    final storage = ref.watch(storageServiceProvider);
    final searchState = ref.watch(searchViewModelProvider);

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
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white),
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
                    onChanged: (val) =>
                        setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: "Search Exchange...",
                      prefixIcon:
                          Icon(Icons.search, color: Colors.teal),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.only(top: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const FilterScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children:
                  ["All", "Fiction", "Non-Fiction", "Academic"]
                      .map((filter) {
                return _buildFilterChip(
                  filter,
                  isActive: _selectedFilter == filter,
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                      _currentPage = 1;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: exchangeBooksAsync.when(
              data: (books) {
                final filteredBooks =
                    _processBooks(books, searchState);

                if (filteredBooks.isEmpty) {
                  return const Center(
                      child: Text("No books found."));
                }

                final totalPages =
                    _getTotalPages(filteredBooks.length);
                final currentBooks =
                    _getCurrentPageBooks(filteredBooks);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentBooks.length,
                        itemBuilder: (context, index) =>
                            _buildExchangeCard(
                                currentBooks[index],
                                storage),
                      ),
                    ),
                    _buildPaginationFooter(totalPages),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () =>
                    _changePage(_currentPage - 1, totalPages)
                : null,
            icon: Icon(Icons.arrow_back_ios,
                color: _currentPage > 1
                    ? Colors.teal
                    : Colors.grey),
          ),
          Text("Page $_currentPage of $totalPages",
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () =>
                    _changePage(_currentPage + 1, totalPages)
                : null,
            icon: Icon(Icons.arrow_forward_ios,
                color: _currentPage < totalPages
                    ? Colors.teal
                    : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard(
      BookModel book, StorageService storage) {
    final imageWidget = book.bookImagesBase64.isNotEmpty
        ? storage.imageFromBase64String(
            book.bookImagesBase64.first)
        : Image.asset(AppAssets.placeholderImage,
            fit: BoxFit.cover);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book)),
      ),
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4)
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 90,
                height: double.infinity,
                child: FittedBox(
                    fit: BoxFit.cover, child: imageWidget),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(book.location ?? 'Not provided',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(book.type,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal[800])),
                  const Spacer(),
                  Text(
                    "Exchange with:\n${book.exchangeBookTitle ?? 'Any'}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () =>
                        _handleExchangeAction(book),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                    ),
                    child: const Text("Exchange",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.black87)),
      ),
    );
  }
}