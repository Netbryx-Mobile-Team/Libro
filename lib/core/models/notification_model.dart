import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId; // Who receives this notification
  final String title;
  final String body;
  final String type; // e.g., 'order', 'rental', 'info'
  final String relatedId; // ID of the order/book involved
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final timestamp = map['timestamp'] as Timestamp?;
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info',
      relatedId: map['relatedId'] ?? '',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
