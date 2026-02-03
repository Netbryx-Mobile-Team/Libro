import 'package:libro/exports.dart';
import 'package:libro/core/models/read_book_model.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleBookDetailScreen extends StatelessWidget {
  final Items book;

  const GoogleBookDetailScreen({super.key, required this.book});

  // Function to open URL
  Future<void> _launchBookUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No preview available for this book.")),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch book reader.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = book.volumeInfo;
    final String? imageUrl =
        info?.imageLinks?.thumbnail ?? info?.imageLinks?.smallThumbnail;

    return Scaffold(
      backgroundColor: whiteColor,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 10.h,
          bottom: 40.h, // Ziada bottom padding se button uper jayega
        ),
        decoration: BoxDecoration(
          color: whiteColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 55.h,
          child: ElevatedButton(
            onPressed: () => _launchBookUrl(context, info?.previewLink),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
            ),
            child: Text(
              "Read Now",
              style: AppStyles.headingSmall.copyWith(
                color: whiteColor,
                fontSize: 18.sp,
              ),
            ),
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            backgroundColor: AppColors.primaryColor,
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Colors.white54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.teal,
                padding: EdgeInsets.all(20.w),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            height: 300.h,
                          )
                        : Image.asset(
                            AppAssets.placeholderImage,
                            height: 200.h,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Details
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info?.title ?? "Unknown Title",
                    style: AppStyles.headingLarge.copyWith(fontSize: 24.sp),
                  ),
                  gapH8,
                  Text(
                    "By ${info?.authors?.join(", ") ?? "Unknown Author"}",
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  gapH8,
                  if (info?.publishedDate != null)
                    Text(
                      "Published: ${info?.publishedDate}",
                      style: AppStyles.bodySmall.copyWith(color: Colors.grey),
                    ),

                  gapH24,
                  Text("Description", style: AppStyles.headingMedium),
                  gapH12,
                  Text(
                    info?.description ?? "No description available.",
                    style: AppStyles.bodyMedium.copyWith(
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  gapH40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
