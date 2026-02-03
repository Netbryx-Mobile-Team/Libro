import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:libro/core/models/chat_message_model.dart';
import 'package:libro/features/chat/view_model/chat_view_model.dart';
import 'package:libro/shared/providers/chat_repository_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String? bookTitle;

  const ChatScreen({
    super.key,
    this.conversationId = '',
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.bookTitle,
    required String initialMessage,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  String activeConversationId = '';
  bool _isLoading = true;

  late List<String> _predefinedMessages;

  @override
  void initState() {
    super.initState();
    _predefinedMessages = _buildPredefinedMessages();
    _initializeChat();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otherUserId != oldWidget.otherUserId ||
        widget.bookTitle != oldWidget.bookTitle) {
      setState(() {
        _isLoading = true;
        activeConversationId = '';
        _predefinedMessages = _buildPredefinedMessages();
      });
      _initializeChat();
    }
  }

  List<String> _buildPredefinedMessages() {
    final book = widget.bookTitle ?? "this book";
    return [
      "Is '$book' available?",
      "What is the condition of '$book'?",
      "Is the price of '$book' negotiable?",
      "How long will delivery take for '$book'?",
    ];
  }

  /// 🔥 MOST IMPORTANT FIX IS HERE
  Future<void> _initializeChat() async {
    final chatVM = ref.read(chatViewModelProvider);
    final repo = ref.read(chatRepositoryProvider);

    final myId = chatVM.currentUserId;
    String id = widget.conversationId;

    if (id.isEmpty) {
      id = await repo.findOrCreateConversation(
        currentUserId: myId,
        otherUserId: widget.otherUserId,
        conversationKey: '',
      );
    }

    if (!mounted) return;

    setState(() {
      activeConversationId = id;
      _isLoading = false;
    });

    /// ✅ RESET UNREAD COUNT (BADGE FIX)
    await chatVM.markConversationAsRead(id);
  }

  Future<void> _sendPredefinedMessage(String message) async {
    if (activeConversationId.isEmpty) return;

    await ref.read(chatViewModelProvider).sendMessage(
          conversationId: activeConversationId,
          content: message,
          otherUserId: widget.otherUserId,
        );
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }

  void _openPredefinedMessageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Send a Quick Message",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                ..._predefinedMessages.map(
                  (msg) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                          horizontal: 16.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _sendPredefinedMessage(msg);
                      },
                      child: Text(
                        msg,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(chatViewModelProvider).currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.otherUserName),
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
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
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (_, i) {
                            final msg = messages[i];
                            final isMe = msg.senderId == myId;
                            return _buildMessageBubble(msg, isMe);
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: ElevatedButton.icon(
                onPressed: _openPredefinedMessageSheet,
                icon: const Icon(Icons.message_outlined, color: Colors.white),
                label: const Text(
                  "Send Quick Message",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Messages are end-to-end encrypted.",
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
  final bubbleColor = isMe ? Colors.teal.shade50 : Colors.white;
  final textColor = Colors.black87;

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: 280.w),
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
          bottomLeft: Radius.circular(isMe ? 16.r : 0),
          bottomRight: Radius.circular(isMe ? 0 : 16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Image or text
          msg.type == MessageType.image
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(msg.content)),
                )
              : Text(
                  msg.content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('hh:mm a').format(msg.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 4.w),
              if (isMe)
                Icon(
                  msg.isRead ? Icons.done_all : Icons.done,
                  size: 14.w,
                  color: msg.isRead ? Colors.blue : Colors.grey,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
}