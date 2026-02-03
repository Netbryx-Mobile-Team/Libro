import 'package:libro/exports.dart';
import 'package:libro/features/chat/view_model/chat_view_model.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String otherUserId;

  const ChatInputField({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatViewModel = ref.read(chatViewModelProvider);

    // Clear controller immediately for better UX
    _controller.clear();

    try {
      // FIX: Use Named Arguments as defined in ChatViewModel
      await chatViewModel.sendMessage(
        conversationId: widget.conversationId,
        content: text,
        otherUserId: widget.otherUserId,
      );
    } catch (e) {
      CustomSnackbar.show(
        context: context,
        message: "Failed to send message.",
        backgroundColor: AppColors.errorRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: whiteColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Text Input Field
          Expanded(
            child: CustomTextField(
              controller: _controller,
              hintText: "Type a message...",
              maxLines: 5,
              height: 50,
              horizontalPadding: 12,
              radius: 25.r,
              borderSide: const BorderSide(
                color: AppColors.primaryLight,
                width: 1.5,
              ),
            ),
          ),

          gapW8,

          // Send Button
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: whiteColor),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
