// lib/core/utils/chat_seen_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSeenManager {
  static const String _prefix = 'chat_last_seen_';

  static Future<void> markConversationSeen(String conversationId) async {
    if (conversationId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_prefix$conversationId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> hasUnseenMessages(
    String conversationId,
    int? lastMessageTimestampMs,
  ) async {
    if (lastMessageTimestampMs == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastSeenMs = prefs.getInt('$_prefix$conversationId') ?? 0;
    return lastMessageTimestampMs > lastSeenMs;
  }
}

final vendorUnreadChatsCountProvider = StreamProvider<int>((ref) {
  final vendorId = FirebaseAuth.instance.currentUser!.uid;

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: vendorId)
      .snapshots()
      .map((snapshot) {
        int totalUnread = 0;

        for (var doc in snapshot.docs) {
          final unreadMap = doc.data()['unreadCount'] as Map<String, dynamic>?;
          if (unreadMap != null) {
            totalUnread += (unreadMap[vendorId] ?? 0) as int;
          }
        }
        return totalUnread;
      });
});
