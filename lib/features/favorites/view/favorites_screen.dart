// lib/features/favorites/view/screens/favorites_screen.dart

import 'dart:async';

import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/favorites/view_model/favorites_view_model.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<BookModel> _localList = [];
  bool _initialLoadDone = false;

  // Stagger duration for insert animations
  static const Duration _staggerDelay = Duration(milliseconds: 80);

  @override
  void dispose() {
    _localList.clear();
    super.dispose();
  }

  // Insert items with a small stagger for slide-in effect
  Future<void> _staggeredInsert(List<BookModel> newItems) async {
    for (var i = 0; i < newItems.length; i++) {
      _localList.insert(i, newItems[i]);
      _listKey.currentState?.insertItem(
        i,
        duration: const Duration(milliseconds: 350),
      );
      await Future.delayed(_staggerDelay);
    }
  }

  // Remove item with animation and inform backend
  Future<void> _removeAtIndex(
    int index, {
    required BuildContext context,
  }) async {
    if (index < 0 || index >= _localList.length) return;

    final removedItem = _localList.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedItem, index, animation),
      duration: const Duration(milliseconds: 300),
    );

    try {
      await ref
          .read(favoritesViewModelProvider.notifier)
          .toggleFavorite(removedItem.id);
      CustomSnackbar.show(
        context: context,
        message: "${removedItem.title} removed from favorites",
        backgroundColor: AppColors.errorRed,
      );
    } catch (e) {
      // If backend removal failed, you might want to re-insert the item.
      // For now show error snackbar.
      CustomSnackbar.show(
        context: context,
        message: "Failed to remove: $e",
        backgroundColor: AppColors.errorRed,
      );
    }
  }

  // When heart is tapped: animate removal locally and update backend
  Future<void> _onHeartTapped(BookModel book, BuildContext context) async {
    final index = _localList.indexWhere((b) => b.id == book.id);
    if (index == -1) return;
    await _removeAtIndex(index, context: context);
  }

  Widget _buildItem(BookModel book, int index, Animation<double> animation) {
    final storageService = ref.read(storageServiceProvider);
    final imageBase64 = book.bookImagesBase64.isNotEmpty
        ? book.bookImagesBase64.first
        : null;

    // Slide + Fade transition
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.vertical,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: animation,
          child: Card(
            margin: EdgeInsets.only(bottom: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: EdgeInsets.all(8.w),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 60.w,
                  height: 80.h,
                  child: imageBase64 != null
                      ? storageService.imageFromBase64String(imageBase64)
                      : Image.asset(
                          AppAssets.placeholderImage,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              title: Text(
                book.title,
                style: AppStyles.headingSmall,
                maxLines: 1,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.type, style: AppStyles.bodySmall),
                  gapH4,
                  Text(
                    book.price != null ? "PKR ${book.price}" : "Exchange",
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: w600,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.errorRed),
                onPressed: () => _onHeartTapped(book, context),
              ),
              onTap: () =>
                  navigation.push(context, BookDetailScreen(book: book)),
            ),
          ),
        ),
      ),
    );
  }

  // Helper when provider data changes
  void _handleProviderData(List<BookModel> data) {
    // If initial local list is empty and provider has data -> do staggered insert
    if (!_initialLoadDone && _localList.isEmpty && data.isNotEmpty) {
      _initialLoadDone = true;
      // Start staggered insert after a tiny delay to ensure AnimatedList is ready
      Future.microtask(() => _staggeredInsert(data));
      return;
    }

    // If provider becomes empty, clear the AnimatedList
    if (data.isEmpty && _localList.isNotEmpty) {
      // Remove all items with animation
      for (int i = _localList.length - 1; i >= 0; i--) {
        final removed = _localList.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildItem(removed, i, animation),
          duration: const Duration(milliseconds: 250),
        );
      }
      _initialLoadDone = false;
      return;
    }

    // If provider changed but local already populated, we keep local state in sync for user actions.
    // (We avoid full diffing for simplicity; user actions drive most changes.)
    // If provider has more items than local (e.g., new favorite added elsewhere), append them without animation:
    if (data.length > _localList.length) {
      final toAdd = data.sublist(_localList.length);
      for (var item in toAdd) {
        _localList.add(item);
        _listKey.currentState?.insertItem(
          _localList.length - 1,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesViewModelProvider);
    final storageService = ref.watch(storageServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Favorites", style: AppStyles.headingMedium),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: favoritesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (books) {
          // Sync provider data to local AnimatedList state (in a simple way)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleProviderData(books);
          });

          if (books.isEmpty && _localList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  gapH16,
                  Text(
                    "No favorites yet",
                    style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(AppDimens.kPadding),
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _localList.length,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index, animation) {
                final book = _localList[index];
                return Dismissible(
                  key: Key(book.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16.w),
                    color: AppColors.errorRed,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    // onDismissed, animate remove and update backend
                    _removeAtIndex(index, context: context);
                  },
                  confirmDismiss: (_) async {
                    // optionally you can show a confirm dialog; return true to proceed
                    return true;
                  },
                  child: _buildItem(book, index, animation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
