import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/repositories/chat_repository.dart';
import 'package:libro/shared/providers/app_providers.dart';

// Note: In app_providers.dart, we assumed 'firestoreServiceProvider' exists.
// If it was named differently, adjust here.

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  // Corrected constructor usage:
  return ChatRepository(firestoreService: firestoreService);
});
