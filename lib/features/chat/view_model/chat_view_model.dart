import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libro/core/models/chat_message_model.dart';
import 'package:libro/core/models/conversation_model.dart';
import 'package:libro/core/models/user_model.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/core/repositories/chat_repository.dart';
import 'package:libro/shared/providers/chat_repository_provider.dart';
import 'package:libro/shared/providers/app_providers.dart';

// -----------------------------------------------------------------------------
// PROVIDERS
// -----------------------------------------------------------------------------

final chatViewModelProvider = Provider<ChatViewModel>((ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return ChatViewModel(chatRepo, authRepo);
});

/// 🔔 TOTAL UNREAD COUNT (FOR BOTTOM NAV BADGE)
final unreadMessageCountProvider = StreamProvider<int>((ref) {
  final viewModel = ref.watch(chatViewModelProvider);

  return viewModel.myConversations.map((conversations) {
    int totalUnread = 0;
    for (final c in conversations) {
      totalUnread += c.unreadCounts as int;
    }
    return totalUnread;
  });
});

// -----------------------------------------------------------------------------
// VIEW MODEL
// -----------------------------------------------------------------------------

class ChatViewModel {
  final ChatRepository _chatRepo;
  final AuthRepository _authRepo;

  ChatViewModel(this._chatRepo, this._authRepo);

  String get currentUserId => _authRepo.getCurrentUser()?.uid ?? '';

  Future<UserModel?> getCurrentUserModel() async {
    final uid = currentUserId;
    if (uid.isEmpty) return null;
    return await _authRepo.getUserData(uid);
  }

  /// ✅ FIXED & AVAILABLE
  Future<bool> isCurrentUserVendor() async {
    final user = await getCurrentUserModel();
    return user?.userType == 'vendor';
  }

  Stream<List<ConversationModel>> get myConversations {
    return _chatRepo.streamConversations(currentUserId);
  }

  Stream<List<ChatMessageModel>> getMessages(String conversationId) {
    return _chatRepo.streamMessages(conversationId);
  }

  Future<String> startConversation(String otherUserId) async {
    return await _chatRepo.findOrCreateConversation(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      conversationKey: '',
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String otherUserId,
  }) async {
    if (content.trim().isEmpty) return;

    final chatId = conversationId.isEmpty
        ? await startConversation(otherUserId)
        : conversationId;

    final message = ChatMessageModel(
      id: '',
      conversationId: chatId,
      senderId: currentUserId,
      receiverId: otherUserId,
      content: content.trim(),
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.text,
    );

    await _chatRepo.sendMessage(chatId, message);
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await _chatRepo.markConversationAsRead(
      conversationId,
      currentUserId,
    );
  }
  /// Delete a conversation
Future<void> deleteConversation(String conversationId) async {
  await _chatRepo.deleteConversation(conversationId);
}

/// Get other user's profile
Future<UserModel?> getUserProfile(String userId) async {
  return await _authRepo.getUserData(userId);
}
  Stream<int> vendorUnreadCount() {
    return _chatRepo.streamConversations(currentUserId).map((convos) {
      int total = 0;
      for (var c in convos) {
        total += c.unreadCountForUser(currentUserId);
      }
      return total;
    });
  }
    Stream<int> userUnreadCount() {
    return _chatRepo.streamConversations(currentUserId).map((convos) {
      int total = 0;
      for (var c in convos) {
        total += c.unreadCountForUser(currentUserId);
      }
      return total;
    });
  }
}