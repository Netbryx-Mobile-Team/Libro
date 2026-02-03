import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/user_model.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/core/repositories/notification_repository.dart';
import 'package:libro/core/services/firestore_service.dart';

// 1. Auth State Provider (Listens to Login/Logout)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirestoreService());
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  // Uses the same FirestoreService as others
  return NotificationRepository(firestoreService: FirestoreService());
});

// 3. User Data Stream Provider (The Critical One)
// This listens to the Firestore document of the currently logged-in user.
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        // Return stream of user document
        return FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map((snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                return UserModel.fromMap(snapshot.data()!);
              }
              // If doc doesn't exist yet (creation lag), return null but don't hang
              return null;
            });
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
