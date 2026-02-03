import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessageContent;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int>? unreadCounts; // Map userId -> unread count

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessageContent,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCounts,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id, String currentUserId) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessageContent: map['lastMessageContent'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  /// Get unread count for a specific user
  int unreadCountForUser(String userId) {
    return unreadCounts?[userId] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts ?? {},
    };
  }
}
