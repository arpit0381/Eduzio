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
    final deletedIds = (_prefs.getStringList('deleted_notification_remote_ids') ?? []).toSet();
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

            for (final row in announcementsData as List) {
              final remoteIdStr = row['id'] as String;
              final hashIdStr = remoteIdStr.hashCode.abs().toString();

              if (deletedIds.contains(remoteIdStr) || deletedIds.contains(hashIdStr)) {
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
      // For web, sort and return non-deleted remote notifications directly
      remoteNotifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return remoteNotifications;
    }

    // On mobile, sync remote announcements to Isar
    await _isar.writeTxn(() async {
      for (final remote in remoteNotifications) {
        if (deletedIds.contains(remote.id.toString()) || 
            (remote.remoteId != null && deletedIds.contains(remote.remoteId!))) {
          continue;
        }

        final existing = await _isar.collection<CachedNotification1816>()
            .filter()
            .remoteIdEqualTo(remote.remoteId)
            .findFirst();

        if (existing == null) {
          await _isar.collection<CachedNotification1816>().put(remote);
        }
      }
    });

    // Read back all notifications from Isar and exclude deleted
    final list = await _isar.collection<CachedNotification1816>().where().findAll();
    final filtered = list.where((n) {
      if (deletedIds.contains(n.id.toString())) return false;
      if (n.remoteId != null && deletedIds.contains(n.remoteId!)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }

  @override
  Future<void> saveNotification(CachedNotification1816 notification) async {
    if (_isar == null) return;
    final deletedIds = (_prefs.getStringList('deleted_notification_remote_ids') ?? []).toSet();
    if (deletedIds.contains(notification.id.toString()) || 
        (notification.remoteId != null && deletedIds.contains(notification.remoteId!))) {
      return;
    }

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
    final deletedIds = (_prefs.getStringList('deleted_notification_remote_ids') ?? []).toSet();
    deletedIds.add(id.toString());

    if (_isar != null) {
      final notification = await _isar.collection<CachedNotification1816>().get(id);
      if (notification != null) {
        if (notification.remoteId != null) {
          deletedIds.add(notification.remoteId!);
        }
        await _isar.writeTxn(() async {
          await _isar.collection<CachedNotification1816>().delete(id);
        });
      }
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
                  deletedIds.add(remoteIdStr);
                  deletedIds.add(remoteIdStr.hashCode.abs().toString());
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

    await _prefs.setStringList('deleted_notification_remote_ids', deletedIds.toList());
  }

  @override
  Future<void> clearAllNotifications() async {
    final deletedIds = (_prefs.getStringList('deleted_notification_remote_ids') ?? []).toSet();

    if (_isar != null) {
      final list = await _isar.collection<CachedNotification1816>().where().findAll();
      for (final n in list) {
        deletedIds.add(n.id.toString());
        if (n.remoteId != null) {
          deletedIds.add(n.remoteId!);
        }
      }
      await _isar.writeTxn(() async {
        await _isar.collection<CachedNotification1816>().clear();
      });
    }

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
              deletedIds.add(remoteIdStr);
              deletedIds.add(remoteIdStr.hashCode.abs().toString());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to clear remote notifications list: $e');
    }

    await _prefs.setStringList('deleted_notification_remote_ids', deletedIds.toList());
  }

  @override
  Future<List<CachedNotification1816>> searchNotifications(String query) async {
    final deletedIds = (_prefs.getStringList('deleted_notification_remote_ids') ?? []).toSet();
    if (_isar == null) return [];

    final list = await _isar.collection<CachedNotification1816>().where().findAll();
    final validList = list.where((n) {
      if (deletedIds.contains(n.id.toString())) return false;
      if (n.remoteId != null && deletedIds.contains(n.remoteId!)) return false;
      return true;
    }).toList();

    if (query.isEmpty) {
      validList.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return validList;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = validList.where((n) =>
        n.title.toLowerCase().contains(lowerQuery) ||
        n.body.toLowerCase().contains(lowerQuery)).toList();

    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }
}
