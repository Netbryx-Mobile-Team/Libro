// lib/shared/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/core/repositories/book_repository.dart';
import 'package:libro/core/repositories/store_repository.dart';
import 'package:libro/core/services/firestore_service.dart';

// --- Services Providers ---

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// --- Repository Providers ---

// 1. Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthRepository(firebaseAuth, firestoreService);
});

// 2. Book Repository (This was missing)
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookRepository(firestoreService);
});

// 3. Store Repository (This was also needed for Vendor)
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return StoreRepository(firestoreService);
});
