import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libro/core/models/chat_message_model.dart';
import 'package:libro/core/models/conversation_model.dart';
import 'package:libro/core/services/firestore_service.dart';

class ChatRepository {
  final FirestoreService _firestoreService;
  final String _conversations = 'conversations';
  final String _messages = 'messages';

  ChatRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  // ---------------------------------------------------------------------------
  // STREAM ALL CONVERSATIONS FOR CURRENT USER
  // ---------------------------------------------------------------------------
  Stream<List<ConversationModel>> streamConversations(String userId) {
    return _firestoreService
        .streamCollection(
          collection: _conversations,
          queryBuilder: (q) => q
              .where('participants', arrayContains: userId)
              .orderBy('lastMessageTime', descending: true),
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                  userId, // Pass currentUserId
                ))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // STREAM MESSAGES OF A CONVERSATION
  // ---------------------------------------------------------------------------
  Stream<List<ChatMessageModel>> streamMessages(String conversationId) {
    return _firestoreService
        .streamCollection(
          collection: '$_conversations/$conversationId/$_messages',
          queryBuilder: (q) => q.orderBy('timestamp', descending: true),
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // SEND MESSAGE
  // ---------------------------------------------------------------------------
  Future<void> sendMessage(String conversationId, ChatMessageModel message) async {
    final convoRef =
        FirebaseFirestore.instance.collection(_conversations).doc(conversationId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      // Add message
      tx.set(
        convoRef.collection(_messages).doc(),
        message.toMap(),
      );

      // Update last message and unread counts
      final preview = message.type == MessageType.image ? '📷 Image' : message.content;

      tx.update(convoRef, {
        'lastMessageContent': preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': message.senderId,
        'unreadCounts.${message.receiverId}': FieldValue.increment(1),
        'unreadCounts.${message.senderId}': 0,
      });
    });
  }

  // ---------------------------------------------------------------------------
  // FIND OR CREATE CONVERSATION
  // ---------------------------------------------------------------------------
  Future<String> findOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    required String conversationKey,
    String? bookId,
    String? bookTitle,
  }) async {
    final participants = [currentUserId, otherUserId]..sort();

    final snapshot = await FirebaseFirestore.instance
        .collection(_conversations)
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }

    // Create new conversation
    final docRef = FirebaseFirestore.instance.collection(_conversations).doc();

    await docRef.set({
      'participants': participants,
      'lastMessageContent': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'unreadCounts': {
        currentUserId: 0,
        otherUserId: 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ---------------------------------------------------------------------------
  // MARK CONVERSATION AS READ FOR A USER
  // ---------------------------------------------------------------------------
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    final convoRef = FirebaseFirestore.instance.collection(_conversations).doc(conversationId);

    await convoRef.update({
      'unreadCounts.$userId': 0,
    });
  }

  // ---------------------------------------------------------------------------
  // DELETE A CONVERSATION
  // ---------------------------------------------------------------------------
  Future<void> deleteConversation(String conversationId) async {
    await _firestoreService.deleteDocument(
      collection: _conversations,
      documentId: conversationId,
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE A SINGLE MESSAGE
  // ---------------------------------------------------------------------------
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _firestoreService.deleteDocument(
      collection: '$_conversations/$conversationId/$_messages',
      documentId: messageId,
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE MESSAGE REACTION
  // ---------------------------------------------------------------------------
  Future<void> updateMessageReaction(
    String conversationId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    await _firestoreService.updateDocument(
      collection: '$_conversations/$conversationId/$_messages',
      documentId: messageId,
      data: {'reactions.$userId': emoji},
    );
  }
}
