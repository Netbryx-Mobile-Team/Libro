import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/home/view/screens/book_detail_screen.dart';

class BookGridView extends ConsumerWidget {
  final List<BookModel> books;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const BookGridView({
    super.key,
    required this.books,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);

    return GridView.builder(
      padding: EdgeInsets.all(AppDimens.kPadding),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Adjust height ratio
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final String? base64Image = book.bookImagesBase64.isNotEmpty
            ? book.bookImagesBase64.first
            : null;

        return GestureDetector(
          onTap: () => navigation.push(context, BookDetailScreen(book: book)),
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: base64Image != null
                          ? storageService.imageFromBase64String(base64Image)
                          : Image.asset(
                              AppAssets.placeholderImage,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),

                // Details
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.headingSmall.copyWith(fontSize: 14.sp),
                      ),
                      gapH4,
                      Text(
                        book.condition,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                      gapH4,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              book.price != null
                                  ? "Rs. ${book.price}"
                                  : "Exchange",
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
