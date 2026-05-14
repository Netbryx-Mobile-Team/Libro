import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/exports.dart';
import 'view_all_stores_screen.dart';
import 'filter_screen.dart';

class SearchStoresScreen extends ConsumerStatefulWidget {
  const SearchStoresScreen({super.key});

  @override
  ConsumerState<SearchStoresScreen> createState() =>
      _SearchStoresScreenState();
}

class _SearchStoresScreenState extends ConsumerState<SearchStoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCity = "All"; // Selected city from filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}), // update list on typing
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
                  setState(() {
                    _selectedCity = city; // update selected city
                  });
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
      body: ViewAllStoresScreen(
        searchController: _searchController,
        selectedCity: _selectedCity,
      ),
    );
  }
}
