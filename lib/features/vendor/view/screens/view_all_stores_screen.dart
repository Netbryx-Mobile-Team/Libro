import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/vendor/view_model/vendor_view_model.dart';
import 'your_store_detail_screen.dart';
import 'filter_screen.dart';

class ViewAllStoresScreen extends ConsumerStatefulWidget {
  const ViewAllStoresScreen({super.key, required TextEditingController searchController, required String selectedCity});

  @override
  ConsumerState<ViewAllStoresScreen> createState() =>
      _ViewAllStoresScreenState();
}

class _ViewAllStoresScreenState extends ConsumerState<ViewAllStoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCity = "All";

  @override
  Widget build(BuildContext context) {
    final allStoresAsync = ref.watch(allStoresStreamProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search store...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(vertical: 0.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () async {
                final city = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FilterScreen()),
                );
                if (city != null) {
                  setState(() => _selectedCity = city);
                }
              },
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.filter_list,
                    color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
      body: allStoresAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (stores) {
          // Filter stores based on search text + selected city
          final filteredStores = stores.where((store) {
            final matchesSearch = store.shopName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
            final matchesCity = _selectedCity == "All" ||
                store.shopAddress.toLowerCase().contains(_selectedCity.toLowerCase());
            return matchesSearch && matchesCity;
          }).toList();

          if (filteredStores.isEmpty) {
            return const Center(child: Text("No matching stores."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: filteredStores.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final store = filteredStores[index];
              return GestureDetector(
                onTap: () {
                  navigation.push(context, YourStoreDetailScreen(store: store));
                },
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 50.w,
                        width: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.shopName,
                              style: AppStyles.headingSmall
                                  .copyWith(fontSize: 16.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              store.shopAddress,
                              style: AppStyles.bodySmall
                                  .copyWith(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
