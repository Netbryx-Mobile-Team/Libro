// lib/features/profile/view_model/profile_view_model.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/core/services/firestore_service.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/shared/providers/app_providers.dart';

class ProfileState {
  final bool isLoading;
  final bool isEditing;
  final File? selectedImage;

  ProfileState({
    this.isLoading = false,
    this.isEditing = false,
    this.selectedImage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isEditing,
    File? selectedImage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final AuthRepository _authRepository;
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final Ref ref;

  ProfileViewModel(
    this._authRepository,
    this._firestoreService,
    this._storageService,
    this.ref,
  ) : super(ProfileState());

  // Toggle Edit Mode
  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  // Pick Profile Image
  Future<void> pickImage() async {
    try {
      final images = await _storageService.pickImages(maxCount: 1);
      if (images.isNotEmpty) {
        state = state.copyWith(selectedImage: images.first);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // Update Profile
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String? shopName,
    String? shopAddress,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      String? base64Image;

      // 1. If new image selected, encode it
      if (state.selectedImage != null) {
        final base64List = await _storageService.encodeFilesToBase64([
          state.selectedImage!,
        ]);
        if (base64List.isNotEmpty) {
          base64Image = base64List.first;
        }
      }

      // 2. Prepare Data to Update
      final Map<String, dynamic> dataToUpdate = {
        'name': name,
        'phone': phone,
        if (base64Image != null) 'profileImageBase64': base64Image,
        if (shopName != null) 'shopName': shopName,
        if (shopAddress != null) 'shopAddress': shopAddress,
      };

      // 3. Update Firestore
      await _firestoreService.setDocument(
        collection: 'users',
        documentId: uid,
        data: dataToUpdate,
      );

      // 4. Refresh User Data Stream (to update UI immediately)
      // Note: Since userStreamProvider is a stream, it *should* auto-update if setDocument triggers it.
      // If not, manual refresh might be needed, but usually Firestore streams handle this.

      state = state.copyWith(
        isLoading: false,
        isEditing: false,
        selectedImage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authRepository.signOut();
  }
}

// Provider
final profileViewModelProvider =
    StateNotifierProvider.autoDispose<ProfileViewModel, ProfileState>((ref) {
      return ProfileViewModel(
        ref.watch(authRepositoryProvider),
        ref.watch(firestoreServiceProvider),
        ref.watch(storageServiceProvider),
        ref,
      );
    });
