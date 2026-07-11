import 'package:flutter/foundation.dart';
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
    List<CachedNotification1816> remoteNotifications = [];
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        // 1. Fetch user profile to get role and organization
        final profileRes = await _supabase
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();

        if (profileRes != null) {
          final organizationId = profileRes['organization_id'] as String?;
          final role = profileRes['role'] as String?;

          if (organizationId != null && role != null) {
            // 2. Fetch student's enrolled batches
            List<String> batchIds = [];
            if (role == 'student') {
              final batchesRes = await _supabase
                  .from('batch_students')
                  .select('batch_id')
                  .eq('student_id', currentUser.id);
              batchIds = (batchesRes as List).map((b) => b['batch_id'] as String).toList();
            }

            // 3. Fetch announcements from Supabase
            final announcementsData = await _supabase
                .from('announcements')
                .select()
                .eq('organization_id', organizationId);

            // Get local list of deleted remote announcement IDs to filter them out
            final deletedIds = _prefs.getStringList('deleted_notification_remote_ids') ?? [];

            for (final row in announcementsData as List) {
              final remoteIdStr = row['id'] as String;
              if (deletedIds.contains(remoteIdStr)) {
                continue;
              }

              final targetRoles = List<String>.from(row['target_roles'] ?? []);
              final announcementBatchId = row['batch_id'] as String?;
              final targetUserId = row['user_id'] as String?;

              // Filter by user_id for private notifications (like fees)
              if (targetUserId != null) {
                if (targetUserId != currentUser.id) {
                  continue;
                }
              } else {
                // If it's a role or batch targeted announcement
                if (role != 'super_admin' && !targetRoles.contains(role)) {
                  continue;
                }
                if (announcementBatchId != null && !batchIds.contains(announcementBatchId)) {
                  continue;
                }
              }

              // Determine type and screen based on title
              String? type;
              String? screen;
              final title = row['title'] as String? ?? 'Notification';
              if (title.contains('Note')) {
                type = 'homework';
                screen = '/notes';
              } else if (title.contains('Fee')) {
                type = 'fees';
                screen = '/fees';
              } else if (title.contains('Attendance')) {
                type = 'attendance';
                screen = '/attendance';
              }

              remoteNotifications.add(CachedNotification1816()
                ..id = remoteIdStr.hashCode.abs()
                ..remoteId = remoteIdStr
                ..title = title
                ..body = row['content'] as String? ?? ''
                ..receivedAt = DateTime.parse(row['created_at'] as String)
                ..isRead = false
                ..type = type
                ..screen = screen
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync remote announcements: $e');
    }

    if (_isar == null) {
      // For web, sort and return the remote notifications directly
      remoteNotifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return remoteNotifications;
    }

    // On mobile, sync remote announcements to Isar
    await _isar.writeTxn(() async {
      for (final remote in remoteNotifications) {
        final existing = await _isar.collection<CachedNotification1816>()
            .filter()
            .remoteIdEqualTo(remote.remoteId)
            .findFirst();

        if (existing == null) {
          await _isar.collection<CachedNotification1816>().put(remote);
        }
      }
    });

    // Read back all notifications from Isar
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
    // 1. Record the deleted ID in SharedPreferences so it filters out on next fetch
    final deletedIds = _prefs.getStringList('deleted_notification_remote_ids') ?? [];

    if (_isar != null) {
      final notification = await _isar.collection<CachedNotification1816>().get(id);
      if (notification != null && notification.remoteId != null) {
        if (!deletedIds.contains(notification.remoteId!)) {
          deletedIds.add(notification.remoteId!);
          await _prefs.setStringList('deleted_notification_remote_ids', deletedIds);
        }
      }
      await _isar.writeTxn(() async {
        await _isar.collection<CachedNotification1816>().delete(id);
      });
    } else {
      // On Web, map hashCode id back to remoteId
      try {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          final profileRes = await _supabase.from('profiles').select('organization_id').eq('id', currentUser.id).maybeSingle();
          if (profileRes != null) {
            final organizationId = profileRes['organization_id'] as String?;
            if (organizationId != null) {
              final announcementsData = await _supabase.from('announcements').select('id').eq('organization_id', organizationId);
              for (final row in announcementsData as List) {
                final remoteIdStr = row['id'] as String;
                if (remoteIdStr.hashCode.abs() == id) {
                  if (!deletedIds.contains(remoteIdStr)) {
                    deletedIds.add(remoteIdStr);
                    await _prefs.setStringList('deleted_notification_remote_ids', deletedIds);
                  }
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to process web deletion: $e');
      }
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    // 1. Add all fetched remote IDs to deleted list
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final profileRes = await _supabase.from('profiles').select('organization_id').eq('id', currentUser.id).maybeSingle();
        if (profileRes != null) {
          final organizationId = profileRes['organization_id'] as String?;
          if (organizationId != null) {
            final announcementsData = await _supabase.from('announcements').select('id').eq('organization_id', organizationId);
            final deletedIds = _prefs.getStringList('deleted_notification_remote_ids') ?? [];
            for (final row in announcementsData as List) {
              final remoteIdStr = row['id'] as String;
              if (!deletedIds.contains(remoteIdStr)) {
                deletedIds.add(remoteIdStr);
              }
            }
            await _prefs.setStringList('deleted_notification_remote_ids', deletedIds);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to clear remote notifications list: $e');
    }

    // 2. Clear local database
    if (_isar != null) {
      await _isar.writeTxn(() async {
        await _isar.collection<CachedNotification1816>().clear();
      });
    }
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
