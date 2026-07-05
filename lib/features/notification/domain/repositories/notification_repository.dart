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

  Future<List<IsarNotification>> getNotificationHistory();

  Future<void> saveNotification(IsarNotification notification);

  Future<void> markAsRead(int id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(int id);

  Future<void> clearAllNotifications();

  Future<List<IsarNotification>> searchNotifications(String query);
}
