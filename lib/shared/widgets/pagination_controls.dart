// lib/shared/widgets/pagination_controls.dart

import '../../exports.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPreviousPage,
    this.onNextPage,
  });

  // Check if navigation is allowed
  bool get canGoPrevious => currentPage > 1;
  bool get canGoNext => currentPage < totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Previous Page Button
        GestureDetector(
          onTap: canGoPrevious ? onPreviousPage : null,
          child: Icon(
            Icons.arrow_back_ios,
            size: 16.w,
            color: canGoPrevious ? blackColor : Colors.grey.shade400,
          ),
        ),

        gapW8,

        // 2. Page Counter (e.g., Page 1 of 10)
        Text(
          'Page $currentPage of $totalPages',
          style: AppStyles.bodySmall.copyWith(
            fontWeight: w600,
            fontSize: 13.sp,
            color: blackColor,
          ),
        ),

        gapW8,

        // 3. Next Page Button
        GestureDetector(
          onTap: canGoNext ? onNextPage : null,
          child: Icon(
            Icons.arrow_forward_ios,
            size: 16.w,
            color: canGoNext ? blackColor : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
