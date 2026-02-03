import 'package:libro/exports.dart';
import 'package:libro/features/search_and_filters/view_model/search_view_model.dart';

class FilterScreen extends ConsumerWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchViewModelProvider);
    final notifier = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Header
          Container(
            padding: EdgeInsets.only(
              top: 40.h,
              left: 16.w,
              right: 16.w,
              bottom: 20.h,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF00897B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: whiteColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  "Filters",
                  style: AppStyles.headingMedium.copyWith(color: whiteColor),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                notifier.resetFilters();
              },
              child: Text(
                "Clear all",
                style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.kPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Location"),
                  gapH12,
                  _buildChipGroup(
                    ["Karachi", "Lahore", "Islamabad"],
                    searchState.selectedLocations,
                    notifier.toggleLocation,
                  ),
                  gapH24,

                  _buildSectionTitle("Genre"),
                  gapH12,
                  _buildChipGroup(
                    [
                      "Horror",
                      "Adventure",
                      "Sci fi",
                      "Wrestling",
                      "Education",
                      "Comedy",
                      "Romance",
                      "Action",
                      "Thriller",
                    ],
                    searchState.selectedGenres,
                    notifier.toggleGenre,
                  ),
                  gapH24,

                  _buildSectionTitle("Type"),
                  gapH12,
                  _buildChipGroup(
                    ["Fiction", "Non-Fiction"],
                    searchState.selectedTypes,
                    notifier.toggleType,
                  ),
                  gapH40,

                  CustomButton(
                    text: "Apply Filters",
                    onPressed: () {
                      // Optional: you can trigger something here if you want
                      // But since filtering is client-side, closing is enough
                      Navigator.pop(context);
                    },
                  ),
                  gapH20,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppStyles.headingSmall.copyWith(
        fontSize: 18.sp,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChipGroup(
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF26A69A) : whiteColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.primaryColor,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              option,
              style: AppStyles.bodyMedium.copyWith(
                color: isSelected ? whiteColor : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}