import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/features/notifications/view_model/notification_view_model.dart';
import 'package:libro/features/vendor/view_model/vendor_upload_view_model.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

/// State Class
class UploadState {
  final bool isLoading;
  final List<File> selectedImages;

  UploadState({this.isLoading = false, this.selectedImages = const []});

  UploadState copyWith({bool? isLoading, List<File>? selectedImages}) {
    return UploadState(
      isLoading: isLoading ?? this.isLoading,
      selectedImages: selectedImages ?? this.selectedImages,
    );
  }
}

/// ViewModel
class UploadViewModel extends StateNotifier<UploadState> {
  final StorageService _storageService;
  final Ref ref;

  UploadViewModel(this._storageService, this.ref) : super(UploadState());

  /// Pick images from gallery
  Future<void> pickImages() async {
    final images = await _storageService.pickImages(maxCount: 3);
    if (images.isNotEmpty) {
      state = state.copyWith(selectedImages: images);
    }
  }

  void removeImage(File image) {
    final updatedList =
        state.selectedImages.where((file) => file.path != image.path).toList();
    state = state.copyWith(selectedImages: updatedList);
  }

  void clearImages() {
    state = state.copyWith(selectedImages: []);
  }

  /// Convert selected images to Base64
  Future<List<String>> getBase64Images() async {
    if (state.selectedImages.isEmpty) return [];
    return await _storageService.encodeFilesToBase64(state.selectedImages);
  }

  /// Upload Book
  Future<void> uploadBook({
    required String collection,
    required String title,
    required String description,
    required String price,
    required String condition,
    required String type,
    required String transactionType,
    required String? exchangePreference,
    required String location,
    required String storeId,
    List<String>? bookImagesBase64, // NEW: optional base64 list
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw "User not logged in.";

      // If images are passed from screen, use them; otherwise use selectedImages
      final imagesToSave = bookImagesBase64 ?? await getBase64Images();

      final Map<String, dynamic> data = {
        'sellerUid': user.uid,
        'sellerName': user.displayName ?? 'User',
        'title': title,
        'author': "Unknown Author",
        'description': description,
        'condition': condition,
        'type': type,
        'transactionType': transactionType,
        'genres': [type],
        'bookImagesBase64': imagesToSave, // ✅ Save images
        'uploadDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'price': transactionType == 'Exchange' ? null : price,
        'exchangeBookTitle':
            transactionType == 'Exchange' ? exchangePreference : null,
        'location': location,
        'storeId': storeId,
      };

      // Save to Public Market
      await FirebaseFirestore.instance.collection(collection).add(data);

      // Save to Vendor's Store
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('books')
          .add(data);

      // Send Notification
      await ref.read(notificationViewModelProvider).notifyBookUploaded(
            userId: user.uid,
            bookTitle: title,
            transactionType: transactionType,
          );

      // Clean up
      clearImages();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final vendorUploadViewModelProvider =
    StateNotifierProvider<UploadViewModel, UploadState>((ref) {
  return UploadViewModel(ref.watch(storageServiceProvider), ref);
});


