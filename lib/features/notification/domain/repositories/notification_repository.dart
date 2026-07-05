import '../../data/models/isar_notification.dart';
import '../entities/notification_preferences.dart';

abstract class NotificationRepository {
  Future<void> registerDeviceToken({
    required String userId,
    required String role,
    String? instituteId,
    required String fcmToken,
  });

  Future<void> deleteDeviceToken({required String fcmToken});

  Future<NotificationPreferences> getPreferences();
  
  Future<void> savePreferences(NotificationPreferences prefs);

  Future<List<CachedNotification1816>> getNotificationHistory();

  Future<void> saveNotification(CachedNotification1816 notification);

  Future<void> markAsRead(int id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(int id);

  Future<void> clearAllNotifications();

  Future<List<CachedNotification1816>> searchNotifications(String query);
}
