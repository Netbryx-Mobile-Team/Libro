import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/features/notifications/view_model/notification_view_model.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

// --- State Class ---
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

// --- ViewModel ---
class UploadViewModel extends StateNotifier<UploadState> {
  final StorageService _storageService;
  final Ref ref;

  UploadViewModel(this._storageService, this.ref) : super(UploadState());

  Future<void> pickImages() async {
    final images = await _storageService.pickImages(maxCount: 3);
    if (images.isNotEmpty) {
      // We append/set images. Using copyWith ensures state is updated properly.
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

  /// Safety Fix: Checks if files exist before converting to Base64 
  /// to prevent PathNotFoundException.
  Future<List<String>> getBase64Images() async {
    if (state.selectedImages.isEmpty) return [];
    
    List<File> validFiles = [];
    for (var file in state.selectedImages) {
      if (await file.exists()) {
        validFiles.add(file);
      }
    }

    if (validFiles.isEmpty) return [];
    return await _storageService.encodeFilesToBase64(validFiles);
  }

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
    List<String>? bookImagesBase64,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw "User not logged in.";

      // Get images: Priority to passed list, fallback to state
      final imagesToUpload = (bookImagesBase64 != null && bookImagesBase64.isNotEmpty)
          ? bookImagesBase64
          : await getBase64Images();

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
        'bookImagesBase64': imagesToUpload,
        'uploadDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'price': transactionType == 'Exchange' ? null : price,
        'exchangeBookTitle': transactionType == 'Exchange' ? exchangePreference : null,
        'location': location,
        'storeId': storeId,
      };

      // 1. Save to Public Market (e.g., 'books' collection)
      await FirebaseFirestore.instance.collection(collection).add(data);

      // 2. Save to Vendor's specific Store sub-collection
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('books')
          .add(data);

      // 3. Trigger Notification
      await ref.read(notificationViewModelProvider).notifyBookUploaded(
            userId: user.uid,
            bookTitle: title,
            transactionType: transactionType,
          );

      // Success cleanup
      clearImages();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow; 
    }
  }
}

// --- Provider ---
// REMOVED .autoDispose so state persists between tab switches
final uploadViewModelProvider =
    StateNotifierProvider<UploadViewModel, UploadState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UploadViewModel(storageService, ref);
});