import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/repositories/store_repository.dart';
import 'package:libro/shared/providers/app_providers.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

// State for Vendor Home
class VendorHomeState {
  final bool isLoading;
  final StoreModel? myStore; // The current vendor's store
  final List<StoreModel> topStores; // List of other stores

  VendorHomeState({
    this.isLoading = false,
    this.myStore,
    this.topStores = const [],
  });

  VendorHomeState copyWith({
    bool? isLoading,
    StoreModel? myStore,
    List<StoreModel>? topStores,
  }) {
    return VendorHomeState(
      isLoading: isLoading ?? this.isLoading,
      myStore: myStore ?? this.myStore,
      topStores: topStores ?? this.topStores,
    );
  }
}

class VendorViewModel extends StateNotifier<VendorHomeState> {
  final StoreRepository _storeRepository;
  final String? _currentUserId;

  VendorViewModel(this._storeRepository, this._currentUserId)
    : super(VendorHomeState()) {
    if (_currentUserId != null) {
      fetchVendorData();
    }
  }

  Future<void> fetchVendorData() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Fetch My Store
      final myStore = await _storeRepository.getStoreByUid(_currentUserId!);

      // 2. Fetch Top Stores (Using stream logic or simple fetch)
      // Since repository has stream, we could listen, but for simplicity here we assume a fetch method or list logic
      // In a real app, topStores might come from a separate provider.
      // For now, we update local state if we had a list method.
      // Since StoreRepository in previous step only had streamAllStores, let's skip fetching list here
      // and let the UI use the StreamProvider for the list part.

      state = state.copyWith(isLoading: false, myStore: myStore);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print("Error fetching vendor data: $e");
    }
  }
}

// 1. Provider for the Vendor ViewModel (My Store Data)
final vendorViewModelProvider =
    StateNotifierProvider.autoDispose<VendorViewModel, VendorHomeState>((ref) {
      // You need to ensure storeRepositoryProvider is defined in app_providers.dart:
      // final storeRepositoryProvider = Provider((ref) => StoreRepository(ref.watch(firestoreServiceProvider)));

      final storeRepo = ref.watch(
        storeRepositoryProvider,
      ); // Make sure this exists in shared/providers
      final user = ref.watch(authStateChangesProvider).value;
      return VendorViewModel(storeRepo, user?.uid);
    });

// 2. Stream Provider for All Stores (Top Selling List)
final allStoresStreamProvider = StreamProvider<List<StoreModel>>((ref) {
  final storeRepo = ref.watch(storeRepositoryProvider);
  return storeRepo.streamAllStores();
});
