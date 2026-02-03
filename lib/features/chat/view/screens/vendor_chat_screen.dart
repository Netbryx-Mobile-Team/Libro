import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:libro/core/models/chat_message_model.dart';
import 'package:libro/features/chat/view_model/chat_view_model.dart';
import 'package:libro/shared/providers/chat_repository_provider.dart';

class VendorChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String? bookTitle;

  const VendorChatScreen({
    super.key,
    this.conversationId = '',
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.bookTitle,
  });

  @override
  ConsumerState<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends ConsumerState<VendorChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String activeConversationId = '';
  bool _isLoading = true;

  late List<String> _vendorPredefinedReplies;

  @override
  void initState() {
    super.initState();
    _vendorPredefinedReplies = _buildVendorPredefinedReplies();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final repo = ref.read(chatRepositoryProvider);
    final vendorId = ref.read(chatViewModelProvider).currentUserId;

    String id = widget.conversationId;

    if (id.isEmpty) {
      id = await repo.findOrCreateConversation(
        currentUserId: vendorId,
        otherUserId: widget.otherUserId,
        conversationKey: '',
      );
    }

    if (!mounted) return;

    setState(() {
      activeConversationId = id;
      _isLoading = false;
    });

    // ✅ MARK CHAT AS READ FOR VENDOR
    await FirebaseFirestore.instance.collection('chats').doc(id).update({
      'unreadCount.$vendorId': 0,
    });
  }

  List<String> _buildVendorPredefinedReplies() {
    return [
      "Available",
      "Not Available",
      "The condition is Used.",
      "The condition is New.",
      "The price of our books are fixed.",
      "Delivery will take 3-5 days."
    ];
  }

  Future<void> _sendPredefinedMessage(String message) async {
    if (activeConversationId.isEmpty) return;

    await ref.read(chatViewModelProvider).sendMessage(
          conversationId: activeConversationId,
          content: message,
          otherUserId: widget.otherUserId,
        );

    // Optional: auto scroll after sending
    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final vendorId = ref.watch(chatViewModelProvider).currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<ChatMessageModel>>(
                    stream: ref
                        .read(chatViewModelProvider)
                        .getMessages(activeConversationId),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text("Messages are end-to-end encrypted."),
                        );
                      }

                      // Auto-scroll on new messages
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom(animate: false);
                      });

                      return ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final isMe = msg.senderId == vendorId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      );
                    },
                  ),
          ),

          // SafeArea for the quick reply button
          SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: ElevatedButton.icon(
                onPressed: _openVendorReplySheet,
                icon: const Icon(Icons.reply_outlined, color: Colors.white),
                label: const Text(
                  "Send Quick Reply",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openVendorReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for full control over height
      backgroundColor: Colors.transparent, // So we can style the container
      builder: (_) {
        return SafeArea(  // ← SafeArea added here for the bottom sheet
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Optional drag handle
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                // List of replies
                Flexible(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    shrinkWrap: true,
                    children: _vendorPredefinedReplies.map((reply) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _sendPredefinedMessage(reply);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Text(
                              reply,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            msg.type == MessageType.image
                ? Image.memory(base64Decode(msg.content))
                : Text(msg.content),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}