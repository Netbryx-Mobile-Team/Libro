import 'package:libro/core/models/notification_model.dart';
import 'package:libro/core/services/firestore_service.dart';

abstract class BaseNotificationRepository {
  Stream<List<NotificationModel>> getUserNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> createNotification(NotificationModel notification);
}

class NotificationRepository implements BaseNotificationRepository {
  final FirestoreService _firestoreService;
  final String _collection = 'notifications';

  NotificationRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    // NOTE: This query requires a Firestore Index (userId ASC, timestamp DESC).
    // If you see "FAILED_PRECONDITION", click the link in the debug console to create it.

    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (query) => query
              .where('userId', isEqualTo: userId)
              // Sorting by timestamp requires an index when using 'where' on a different field
              .orderBy('timestamp', descending: true),
        )
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      documentId: notificationId,
      data: {'isRead': true},
    );
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    await _firestoreService.addDocument(
      collection: _collection,
      data: notification.toMap(),
    );
  }
}
