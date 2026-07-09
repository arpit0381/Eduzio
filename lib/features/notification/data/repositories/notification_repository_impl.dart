import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_preferences.dart';
import '../models/isar_notification.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _supabase;
  final Isar? _isar;
  final SharedPreferences _prefs;

  NotificationRepositoryImpl(this._supabase, this._isar, this._prefs);

  @override
  Future<void> registerDeviceToken({
    required String userId,
    required String role,
    String? instituteId,
    required String fcmToken,
  }) async {
    String platform = 'unknown';
    if (identical(0, 0.0)) {
      platform = 'web';
    } else {
      platform = const bool.fromEnvironment('dart.library.js_util') ? 'web' : 'mobile';
    }

    final payload = {
      'user_id': userId,
      'role': role,
      'institute_id': instituteId,
      'device_name': 'Device',
      'platform': platform,
      'fcm_token': fcmToken,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('notification_tokens').upsert(payload, onConflict: 'fcm_token');
  }

  @override
  Future<void> deleteDeviceToken({required String fcmToken}) async {
    await _supabase.from('notification_tokens').delete().eq('fcm_token', fcmToken);
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final prefsStr = _prefs.getString('notification_preferences');
    if (prefsStr == null) return const NotificationPreferences();
    try {
      final map = json.decode(prefsStr) as Map<String, dynamic>;
      return NotificationPreferences.fromMap(map);
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  @override
  Future<void> savePreferences(NotificationPreferences prefs) async {
    await _prefs.setString('notification_preferences', json.encode(prefs.toMap()));
  }

  @override
  Future<List<CachedNotification1816>> getNotificationHistory() async {
    if (_isar == null) return [];
    final list = await _isar.collection<CachedNotification1816>().where().findAll();
    list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return list;
  }

  @override
  Future<void> saveNotification(CachedNotification1816 notification) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.collection<CachedNotification1816>().put(notification);
    });
  }

  @override
  Future<void> markAsRead(int id) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      final notification = await _isar.collection<CachedNotification1816>().get(id);
      if (notification != null) {
        notification.isRead = true;
        await _isar.collection<CachedNotification1816>().put(notification);
      }
    });
  }

  @override
  Future<void> markAllAsRead() async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      final list = await _isar.collection<CachedNotification1816>().where().findAll();
      final unread = list.where((n) => !n.isRead).toList();
      for (final n in unread) {
        n.isRead = true;
        await _isar.collection<CachedNotification1816>().put(n);
      }
    });
  }

  @override
  Future<void> deleteNotification(int id) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.collection<CachedNotification1816>().delete(id);
    });
  }

  @override
  Future<void> clearAllNotifications() async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.collection<CachedNotification1816>().clear();
    });
  }

  @override
  Future<List<CachedNotification1816>> searchNotifications(String query) async {
    if (_isar == null) return [];
    final list = await _isar.collection<CachedNotification1816>().where().findAll();
    if (query.isEmpty) {
      list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return list;
    }
    final lowerQuery = query.toLowerCase();
    final filtered = list.where((n) =>
        n.title.toLowerCase().contains(lowerQuery) ||
        n.body.toLowerCase().contains(lowerQuery)).toList();
    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }
}
