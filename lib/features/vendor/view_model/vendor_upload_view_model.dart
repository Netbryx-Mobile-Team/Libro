import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorUploadViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads book with image (using bytes → most reliable method 2025+)
  Future<void> uploadBook({
    required String storeId,
    required String title,
    required String description,
    required String price,
    required String condition,
    required String type,
    required String transactionType,
    String? exchangePreference,
    required String location,
    required XFile? pickedImage,          // ← we work with XFile directly
    required String sellerName,
    required String sellerUid,
    required BuildContext context,
    String collection = 'books',
  }) async {
    try {
      String? imageUrl;

      // Handle image upload
      if (pickedImage != null) {
        Uint8List? imageBytes;

        try {
          imageBytes = await pickedImage.readAsBytes();
        } catch (e) {
          debugPrint('Failed to read image bytes: $e');
          throw Exception('Could not read selected image');
        }

        if (imageBytes.isEmpty) {
          throw Exception('Image file is empty or corrupted');
        }

        debugPrint('Image read successfully — size: ${imageBytes.length} bytes');

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('books/$storeId/$fileName');

        final uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          imageUrl = await snapshot.ref.getDownloadURL();
          debugPrint('Image uploaded successfully: $imageUrl');
        } else {
          throw Exception('Image upload failed: ${snapshot.state}');
        }
      }

      // Save book data to Firestore
      await _firestore.collection(collection).add({
        'storeId': storeId,
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'type': type,
        'transactionType': transactionType,
        'exchangePreference': exchangePreference,
        'location': location,
        'imageUrl': imageUrl ?? '',
        'sellerName': sellerName,
        'sellerUid': sellerUid,
        'createdAt': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Upload error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload book: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick image using gallery
  Future<XFile?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75, // reasonable quality/size balance
        maxWidth: 1200,
      );

      if (file != null) {
        debugPrint('Image picked → path: ${file.path}');
      }

      return file;
    } catch (e) {
      debugPrint('Image picker error: $e');
      return null;
    }
  }
}

final vendorUploadViewModelProvider = Provider<VendorUploadViewModel>((ref) {
  return VendorUploadViewModel();
});