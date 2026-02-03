// lib/features/upload/view/widgets/upload_image_picker.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/shared/constants/app_colors.dart';
import 'package:libro/shared/constants/app_styles.dart';

class UploadImagePicker extends StatelessWidget {
  final List<File> selectedImages;
  final VoidCallback onPickImages;

  // FIX: Changed from Function(int) to Function(File) to match ViewModel
  final Function(File) onRemoveImage;

  const UploadImagePicker({
    super.key,
    required this.selectedImages,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Picker Box
        GestureDetector(
          onTap: onPickImages,
          child: Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primaryColor,
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: selectedImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 8.h),
                      Text("Tap to add images", style: AppStyles.bodySmall),
                    ],
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(8.w),
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      final image = selectedImages[index];
                      return Stack(
                        children: [
                          Container(
                            width: 100.w,
                            margin: EdgeInsets.only(right: 8.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              image: DecorationImage(
                                image: FileImage(image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Remove Button
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => onRemoveImage(
                                image,
                              ), // FIX: Passing File, not Index
                              child: CircleAvatar(
                                radius: 10.r,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
