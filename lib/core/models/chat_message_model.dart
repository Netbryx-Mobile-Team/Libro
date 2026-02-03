import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, String> reactions;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.reactions = const {},
    required this.isRead,
  });

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ChatMessageModel(
      id: documentId,
      conversationId: map['conversationId'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      type: MessageType.values.byName(map['type']),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    reactions: Map<String, String>.from(map['reactions'] ?? {}),
    isRead: map['isRead'] as bool? ?? false,
  );
}


  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'reactions': reactions,
    };
  }
}
