import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/core/models/conversation_model.dart';
import 'package:libro/shared/providers/chat_repository_provider.dart';

// Provider to stream the list of conversations for a specific user
final conversationListProvider =
    StreamProvider.family<List<ConversationModel>, String>((ref, userId) {
      final chatRepository = ref.watch(chatRepositoryProvider);
      return chatRepository.streamConversations(userId);
    });
