// lib/core/repositories/store_repository.dart

import 'package:libro/core/models/store_model.dart';
import 'package:libro/core/services/firestore_service.dart';

abstract class BaseStoreRepository {
  Future<void> createStore(StoreModel store);
  Future<StoreModel?> getStoreByUid(String uid);
  Stream<List<StoreModel>> streamAllStores();
}

class StoreRepository implements BaseStoreRepository {
  final FirestoreService _firestoreService;
  final String _storeCollection = 'stores';

  StoreRepository(this._firestoreService);

  // --- Store Creation ---

  // Creates a new store or updates an existing one (using vendor UID as document ID)
  @override
  Future<void> createStore(StoreModel store) async {
    await _firestoreService.setDocument(
      collection: _storeCollection,
      documentId: store.uid, // Vendor UID is the document ID
      data: store.toMap(),
    );
  }

  // --- Fetch Single Store ---

  @override
  Future<StoreModel?> getStoreByUid(String uid) async {
    final data = await _firestoreService.getDocument(
      collection: _storeCollection,
      documentId: uid,
    );
    if (data != null) {
      return StoreModel.fromMap(data, uid);
    }
    return null;
  }

  // --- Stream All Stores (for Vendor Home/Stores Tab) ---

  @override
  Stream<List<StoreModel>> streamAllStores() {
    return _firestoreService
        .streamCollection(
          collection: _storeCollection,
          queryBuilder: (query) => query.orderBy('updatedAt', descending: true),
        )
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => StoreModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }
}
