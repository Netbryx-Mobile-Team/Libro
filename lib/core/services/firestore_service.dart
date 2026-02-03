// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // General write operation for adding a new document
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection(collection)
        .doc(documentId)
        .set(data, SetOptions(merge: true));
  }

  // General write operation for adding a new document with an auto-generated ID
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final docRef = await _db.collection(collection).add(data);
    return docRef.id;
  }
// Returns a DocumentReference directly
DocumentReference docRef(String collection, String docId) {
  return _db.collection(collection).doc(docId);
}

  // General read operation to fetch a single document
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    final docSnapshot = await _db.collection(collection).doc(documentId).get();
    return docSnapshot.data();
  }

  // General stream operation to listen to a single document (for real-time updates)
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _db
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // General stream operation to listen to a collection (for lists like home feed)
  Stream<QuerySnapshot> streamCollection({
    required String collection,
    Query Function(Query query)? queryBuilder, // Optional filters/ordering
  }) {
    Query query = _db.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }
// Returns a list of documents matching a field condition
Future<List<Map<String, dynamic>>> getCollectionWhere({
  required String collection,
  required String field,
  required dynamic isEqualTo,
}) async {
  final querySnapshot = await _db
      .collection(collection)
      .where(field, isEqualTo: isEqualTo)
      .get();

  return querySnapshot.docs.map((doc) => doc.data()).toList();
}

  // General delete operation
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await _db.collection(collection).doc(documentId).delete();
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  // Method to fetch a limited list of documents for a page (for pagination)
  // This will be used in the HomeViewModel/Repository for the '10 books per page' logic.
  Future<QuerySnapshot> getPaginatedCollection({
    required String collection,
    required int limit,
    DocumentSnapshot? startAfterDocument,
    Query Function(Query query)? queryBuilder,
  }) async {
    Query query = _db.collection(collection);

    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    query = query.limit(limit);
    return query.get();
  }
}
