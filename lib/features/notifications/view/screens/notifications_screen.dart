import 'package:libro/exports.dart';
import 'package:libro/core/models/notification_model.dart';
import 'package:libro/features/notifications/view_model/notification_view_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: AppStyles.headingMedium.copyWith(
            fontSize: 20.sp,
            color: whiteColor,
            letterSpacing: 1.0,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.done_all, color: whiteColor),
        //     onPressed: () {
        //       // Future implementation: Mark all as read
        //     },
        //   ),
        // ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.topCenter,
            colors: [AppColors.primaryColor.withOpacity(0.1), whiteColor],
            stops: const [0.0, 0.1],
          ),
        ),
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
          error: (err, stack) {
            // Handle Index Error specifically
            if (err.toString().contains("FAILED_PRECONDITION")) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: const Text(
                    "Database Index Required.\nPlease check the debug console for the creation link.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            return Center(child: Text("Error: $err"));
          },
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        size: 50.w,
                        color: AppColors.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    gapH16,
                    Text(
                      "No notifications yet",
                      style: AppStyles.headingSmall.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    gapH8,
                    Text(
                      "Updates about orders, books, and\nsubscriptions will appear here.",
                      textAlign: TextAlign.center,
                      style: AppStyles.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              itemCount: notifications.length,
              separatorBuilder: (c, i) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(context, ref, notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    return Container(
      color: notification.isRead
          ? whiteColor
          : AppColors.primaryColor.withOpacity(0.05),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: _getIconColor(notification.type).withOpacity(0.1),
          child: Icon(
            _getIcon(notification.type),
            color: _getIconColor(notification.type),
            size: 24.sp,
          ),
        ),
        title: Text(
          notification.title,
          style: AppStyles.headingSmall.copyWith(
            fontSize: 16.sp,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.body,
              style: AppStyles.bodySmall.copyWith(
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              timeago.format(notification.timestamp),
              style: AppStyles.bodySmall.copyWith(
                color: Colors.grey,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationViewModelProvider).markAsRead(notification.id);
          }
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'rental':
        return Icons.key_outlined;
      case 'book_upload':
        return Icons.cloud_upload_outlined;
      case 'subscription':
        return Icons.monetization_on_outlined;
      case 'store':
        return Icons.storefront_outlined;
      case 'security':
        return Icons.security_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'rental':
        return Colors.orange;
      case 'book_upload':
        return Colors.teal;
      case 'subscription':
        return Colors.green;
      case 'store':
        return Colors.purple;
      case 'security':
        return Colors.red;
      default:
        return AppColors.primaryColor;
    }
  }
}
