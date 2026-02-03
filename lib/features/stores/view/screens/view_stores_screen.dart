import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/home/view/screens/bottom_navbar_screen.dart';
import 'package:libro/features/stores/view/screens/store_detail_screen.dart';

class ViewStoresScreen extends ConsumerStatefulWidget {
  final BookModel? book; // ✅ allow null

  const ViewStoresScreen({super.key, this.book}); // optional, can be null

  @override
  ConsumerState<ViewStoresScreen> createState() => _ViewStoresScreenState();
}


class _ViewStoresScreenState extends ConsumerState<ViewStoresScreen> {
  // --- STATE VARIABLES ---
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = "";
  String _selectedCity = "All";

  // Pagination State
  final int _itemsPerPage = 10;
  int _currentPage = 1;

  final List<String> _cities = [
    "All",
    "Karachi",
    "Lahore",
    "Islamabad",
    "Rawalpindi",
    "Faisalabad",
    "Multan",
    "Peshawar",
    "Quetta",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOGIC HELPERS ---

  void _onFilterChanged() {
    setState(() {
      _currentPage = 1; // Reset to page 1 when filters change
    });
  }

  int _getTotalPages(int totalItems) {
    if (totalItems == 0) return 1;
    return (totalItems / _itemsPerPage).ceil();
  }

  List<StoreModel> _getCurrentPageStores(List<StoreModel> filteredStores) {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (startIndex >= filteredStores.length) return [];
    if (endIndex > filteredStores.length) {
      endIndex = filteredStores.length;
    }

    return filteredStores.sublist(startIndex, endIndex);
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

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: whiteColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppDimens.kPadding),
          height: 400.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Location", style: AppStyles.headingMedium),
              gapH16,
              Expanded(
                child: ListView.separated(
                  itemCount: _cities.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      title: Text(
                        city,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: _selectedCity == city
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedCity == city
                              ? AppColors.primaryColor
                              : blackColor,
                        ),
                      ),
                      trailing: _selectedCity == city
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCity = city;
                        });
                        _onFilterChanged();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = ref.watch(storageServiceProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        children: [
          // ---------------- CUSTOM HEADER ----------------
          Container(
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF26A69A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                child: Column(
                  children: [
                    // Top Row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BottomNavbarScreen(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                          child: CircleAvatar(
                            backgroundColor: whiteColor,
                            radius: 18.r,
                            child: Icon(
                              Icons.arrow_back,
                              color: blackColor,
                              size: 20.sp,
                            ),
                          ),
                        ),
                        gapW12,
                        Expanded(
                          child: Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val.toLowerCase();
                                      });
                                      _onFilterChanged();
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Search stores...",
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.only(
                                        bottom: 10.h,
                                      ),
                                      hintStyle: AppStyles.bodyMedium.copyWith(
                                        color: Colors.grey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.search,
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        gapW12,
                        GestureDetector(
                          onTap: _showLocationFilter,
                          child: CircleAvatar(
                            backgroundColor: whiteColor,
                            radius: 18.r,
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.primaryColor,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    gapH20,
                    Text(
                      "Bookstore",
                      style: AppStyles.headingLarge.copyWith(
                        color: whiteColor,
                        letterSpacing: 1.2,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCity != "All") ...[
                      gapH4,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter_list,
                              size: 12,
                              color: Colors.white,
                            ),
                            gapW4,
                            Text(
                              "Location: $_selectedCity",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ---------------- STORE LIST & PAGINATION ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stores')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No stores found"));
                }

                // 1. Process All Data
                final allStores = snapshot.data!.docs.map((doc) {
                  return StoreModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                // 2. Apply Filters
                final filteredStores = allStores.where((store) {
                  final matchesSearch = store.shopName.toLowerCase().contains(
                    _searchQuery,
                  );
                  bool matchesLocation = true;
                  if (_selectedCity != "All") {
                    matchesLocation = store.shopAddress.toLowerCase().contains(
                      _selectedCity.toLowerCase(),
                    );
                  }
                  return matchesSearch && matchesLocation;
                }).toList();

                if (filteredStores.isEmpty) {
                  return Center(
                    child: Text(
                      "No stores found in $_selectedCity",
                      style: AppStyles.bodyMedium,
                    ),
                  );
                }

                // 3. Apply Pagination
                final totalPages = _getTotalPages(filteredStores.length);
                final currentStores = _getCurrentPageStores(filteredStores);

                return ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.kPadding,
                    vertical: 16.h,
                  ),
                  // Add +1 for the pagination footer
                  itemCount: currentStores.length + 1,
                  separatorBuilder: (c, i) => gapH16,
                  itemBuilder: (context, index) {
                    // Check if we are at the end to show footer
                    if (index == currentStores.length) {
                      return _buildPaginationFooter(totalPages);
                    }

                    return _buildStoreCard(
                      context,
                      currentStores[index],
                      storageService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildStoreCard(
  BuildContext context,
  StoreModel store,
  StorageService storage,
) {
  final String? base64Image = store.shopImagesBase64.isNotEmpty
      ? store.shopImagesBase64.first
      : null;

  return GestureDetector(
    onTap: () {
      navigation.push(context, StoreDetailScreen(store: store, book: null,));
    },
    child: Container(
      height: 115.h, // Adjusted height to fit details
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- Store Image ---
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
            ),
            child: SizedBox(
              width: 100.w,
              height: double.infinity,
              child: base64Image != null
                  ? Image(
                      image: storage.imageFromBase64String(base64Image).image,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      AppAssets.storeImagePlaceholder,
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // --- Details Section ---
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    store.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.headingSmall.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Owner Name
                  Text(
                    "Owner: ${store.ownerName}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12.sp,
                        color: Colors.grey,
                      ),
                      gapW4,
                      Expanded(
                        child: Text(
                          store.shopAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodySmall.copyWith(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Rating & Visit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- Average Rating from Firestore ---
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('stores')
                            .doc(store.uid) // <-- FIXED HERE
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "⭐ --/5",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          }

                          final data = snapshot.data!.data() as Map<String, dynamic>?;

                          double avgRating = 0.0;
                          if (data != null && data['averageRating'] != null) {
                            avgRating = (data['averageRating'] as num).toDouble();
                          }

                          return Text(
                            "⭐ ${avgRating.toStringAsFixed(1)}/5",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        },
                      ),

                      // --- Visit Button ---
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          "Visit",
                          style: TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPaginationFooter(int totalPages) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _changePage(_currentPage - 1, totalPages)
                : null,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 16.sp,
              color: _currentPage > 1 ? Colors.teal : Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          gapW12,
          Text(
            "Page $_currentPage of $totalPages",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          gapW12,
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => _changePage(_currentPage + 1, totalPages)
                : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: _currentPage < totalPages ? Colors.teal : Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
