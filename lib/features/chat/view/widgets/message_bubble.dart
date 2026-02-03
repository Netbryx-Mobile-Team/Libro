// lib/features/chat/view/widgets/message_bubble.dart

import 'package:libro/core/models/chat_message_model.dart';
import 'package:libro/core/services/storage_service.dart';
import 'package:libro/exports.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String? profileImageBase64; // User's profile image Base64 string

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.profileImageBase64,
  });

  @override
  Widget build(BuildContext context) {
    final StorageService storageService = StorageService();

    // Bubble alignment
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? AppColors.primaryLight : AppColors.greyBackground;
    final textColor = isMe ? whiteColor : blackColor;

    // Time formatting
    final time = '${message.timestamp.hour}:${message.timestamp.minute}';

    // Future: Logic to show profile image if not 'isMe'
    Widget buildProfileImage() {
      if (!isMe &&
          profileImageBase64 != null &&
          profileImageBase64!.isNotEmpty) {
        return CircleAvatar(
          radius: 15.r,
          backgroundImage: MemoryImage(
            storageService.dataFromBase64String(profileImageBase64!),
          ),
        );
      }
      // Placeholder for other user
      return CircleAvatar(
        radius: 15.r,
        backgroundColor: Colors.grey.shade400,
        child: Icon(Icons.person, size: 18.w, color: whiteColor),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                buildProfileImage(), // Show profile pic only for receiver
              if (!isMe) gapW8,

              // Message Bubble
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: isMe
                        ? Radius.circular(16.r)
                        : Radius.circular(4.r),
                    bottomRight: isMe
                        ? Radius.circular(4.r)
                        : Radius.circular(16.r),
                  ),
                ),
                child: Text(
                  message.content,
                  style: AppStyles.bodyMedium.copyWith(color: textColor),
                ),
              ),
            ],
          ),

          gapH4,

          // Time and Read Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe)
                Icon(
message.isRead
    ? Icons.done_all
    : Icons.done,
                  size: 14.w,
                  color: message.isRead
                      ? AppColors.primaryColor
                      : AppColors.greyText,
                ),
              if (isMe) gapW4,

              Text(time, style: AppStyles.bodySmall.copyWith(fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
