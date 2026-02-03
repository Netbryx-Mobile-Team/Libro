import 'package:libro/exports.dart';
import 'package:libro/core/models/conversation_model.dart';
import 'package:libro/core/models/user_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/features/chat/view/screens/chat_screen.dart';
import 'package:libro/features/chat/view/screens/vendor_chat_screen.dart';
import 'package:libro/features/chat/view_model/chat_view_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  void _confirmDelete(BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: whiteColor,
        title: const Text("Delete Conversation?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await ref.read(chatViewModelProvider).deleteConversation(conversationId);
              CustomSnackbar.show(
                context: context,
                message: "Conversation deleted",
                backgroundColor: Colors.grey.shade800,
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(chatViewModelProvider);
    final myId = viewModel.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Messages",
          style: AppStyles.headingLarge.copyWith(
            fontSize: 20.sp,
            color: whiteColor,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.primaryColor.withOpacity(0.1),
              const Color(0xFFF5F5F5),
            ],
            stops: const [0.0, 0.2],
          ),
        ),
        child: StreamBuilder<List<ConversationModel>>(
          stream: viewModel.myConversations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Error loading chats."));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 50,
                      color: AppColors.primaryColor.withOpacity(0.5),
                    ),
                    gapH24,
                    Text(
                      "No messages yet",
                      style: AppStyles.headingSmall.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }

            final conversations = snapshot.data!;

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primaryColor,
              backgroundColor: whiteColor,
              child: ListView.separated(
                key: ValueKey(_refreshKey),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                itemCount: conversations.length,
                separatorBuilder: (c, i) => gapH12,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];

                  final otherUserId = conversation.participants.firstWhere(
                    (id) => id != myId,
                    orElse: () => '',
                  );
                  if (otherUserId.isEmpty) return const SizedBox.shrink();

                  final unreadCount = conversation.unreadCountForUser(myId);

                  return FutureBuilder<UserModel?>(
                    future: viewModel.getUserProfile(otherUserId),
                    builder: (context, userSnap) {
                      final otherUser = userSnap.data;
                      final name = otherUser?.name ?? "Loading...";
                      final imageBase64 = otherUser?.profileImageBase64;
                      final isLoading = userSnap.connectionState == ConnectionState.waiting;

                      return Dismissible(
                        key: Key(conversation.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.w),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: whiteColor,
                            size: 28,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          _confirmDelete(context, conversation.id);
                          return false;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.r),
                              onLongPress: () => _confirmDelete(context, conversation.id),
                              onTap: () async {
                                final isVendorUser = await viewModel.isCurrentUserVendor();

                                if (isVendorUser) {
                                  navigation.push(
                                    context,
                                    VendorChatScreen(
                                      conversationId: conversation.id,
                                      otherUserId: otherUserId,
                                      otherUserName: name,
                                      otherUserImage: imageBase64,
                                    ),
                                  );
                                } else {
                                  navigation.push(
                                    context,
                                    ChatScreen(
                                      conversationId: conversation.id,
                                      otherUserId: otherUserId,
                                      otherUserName: name,
                                      otherUserImage: imageBase64,
                                      initialMessage: '',
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 26.r,
                                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                                      backgroundImage: (imageBase64 != null && !isLoading)
                                          ? ref.read(storageServiceProvider).imageFromBase64String(imageBase64).image
                                          : null,
                                      child: (imageBase64 == null && !isLoading)
                                          ? Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                                              style: AppStyles.headingSmall.copyWith(
                                                color: AppColors.primaryColor,
                                              ),
                                            )
                                          : null,
                                    ),
                                    gapW12,

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: AppStyles.headingSmall.copyWith(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                timeago.format(
                                                  conversation.lastMessageTime,
                                                  locale: 'en_short',
                                                ),
                                                style: AppStyles.bodySmall.copyWith(
                                                  fontSize: 11.sp,
                                                  color: unreadCount > 0
                                                      ? AppColors.primaryColor
                                                      : Colors.grey,
                                                  fontWeight: unreadCount > 0
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          gapH4,
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  conversation.lastMessageContent,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppStyles.bodySmall.copyWith(
                                                    color: unreadCount > 0
                                                        ? Colors.black87
                                                        : Colors.grey.shade600,
                                                    fontWeight: unreadCount > 0
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if (unreadCount > 0)
                                                Container(
                                                  margin: EdgeInsets.only(left: 8.w),
                                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryColor,
                                                    borderRadius: BorderRadius.circular(10.r),
                                                  ),
                                                  child: Text(
                                                    unreadCount > 9 ? "9+" : unreadCount.toString(),
                                                    style: TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 10.sp,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}