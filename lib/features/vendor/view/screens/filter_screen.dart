import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/exports.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  String selectedCity = "All";

  final List<String> cities = [
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
  Widget build(BuildContext context) {
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
                setState(() {
                  selectedCity = "All";
                });
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
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: AppStyles.headingSmall
                        .copyWith(fontSize: 18.sp, color: Colors.black87),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: cities.map((city) {
                      final isSelected = selectedCity == city;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCity = city),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? AppColors.primaryColor : whiteColor,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            city,
                            style: AppStyles.bodyMedium.copyWith(
                              color: isSelected ? whiteColor : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 40.h),
                  CustomButton(
                    text: "Apply Filters",
                    onPressed: () {
                      Navigator.pop(context, selectedCity); // send back selected city
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
