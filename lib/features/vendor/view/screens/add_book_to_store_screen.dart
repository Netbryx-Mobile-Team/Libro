import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libro/exports.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

class AddBookToStoreScreen extends ConsumerStatefulWidget {
  final String storeId;
  const AddBookToStoreScreen({super.key, required this.storeId});

  @override
  ConsumerState<AddBookToStoreScreen> createState() =>
      _AddBookToStoreScreenState();
}

class _AddBookToStoreScreenState extends ConsumerState<AddBookToStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _genreController = TextEditingController();
  final _priceController = TextEditingController();

  // State Variables
  String _condition = 'New';
  List<Uint8List> _selectedImagesBytes = []; // Store bytes directly
  bool _isLoading = false;

  // Image Picker Logic
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      imageQuality: 50,
    );

    if (images != null && images.isNotEmpty) {
      final List<Uint8List> bytesList = [];
      for (var img in images) {
        final bytes = await img.readAsBytes();
        bytesList.add(bytes);
      }

      setState(() {
        _selectedImagesBytes.addAll(bytesList); // Add to existing list
      });
    }
  }

  // Submit Logic
  Future<void> _submitBook() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImagesBytes.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please add at least one image for the book",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authRepositoryProvider).getCurrentUser();
      if (currentUser == null) throw "User not logged in";

      // Convert all images to Base64
      final List<String> base64Images =
          _selectedImagesBytes.map((b) => base64Encode(b)).toList();

      final bookData = {
        'title': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'genre': _genreController.text.trim(),
        'type': _genreController.text.trim(),
        'price': _priceController.text.trim(),
        'condition': _condition,
        'bookImagesBase64': base64Images,
        'image': base64Images.first, // For preview in list/grid
        'sellerUid': currentUser.uid,
        'sellerName': currentUser.displayName ?? 'Vendor',
        'storeId': widget.storeId,
        'uploadDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'available',
      };

      // Save to Store's private collection
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('books')
          .add(bookData);

      // Save to Public Market
      await FirebaseFirestore.instance.collection('books_sell').add(bookData);

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Book Listed Successfully!",
          backgroundColor: AppColors.successGreen,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Error: $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Remove image from list
  void _removeImage(int index) {
    setState(() => _selectedImagesBytes.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        title: const Text("Add New Book"),
        centerTitle: true,
        backgroundColor: whiteColor,
        elevation: 0,
        foregroundColor: blackColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE PICKER ---
              SizedBox(
                height: 160.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImagesBytes.length + 1,
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    if (index == _selectedImagesBytes.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120.w,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.primaryColor),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 30.sp, color: Colors.grey),
                                gapH8,
                                Text("Add Image", style: AppStyles.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Stack(
                        children: [
                          Container(
                            width: 120.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              image: DecorationImage(
                                image: MemoryImage(_selectedImagesBytes[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 20.sp, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              gapH24,

              // --- FIELDS ---
              CustomTextField(
                controller: _nameController,
                hintText: "Book Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              gapH16,
              CustomTextField(
                controller: _descController,
                hintText: "Description (e.g. Edition, Author)",
                maxLines: 3,
              ),
              gapH16,
              CustomTextField(
                controller: _genreController,
                hintText: "Genre (e.g. Fiction, Sci-Fi)",
              ),
              gapH16,
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      hintText: "Price (Rs)",
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  gapW16,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _condition,
                      items: ['New', 'Used', 'Like New']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _condition = v!),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                      ),
                    ),
                  ),
                ],
              ),
              gapH40,
              CustomButton(
                text: "Add to Inventory",
                isLoading: _isLoading,
                onPressed: _submitBook,
              ),
              gapH40,
            ],
          ),
        ),
      ),
    );
  }
}
