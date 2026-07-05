import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../data/models/isar_notification.dart';
import 'notification_controller.dart';

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM automatically caches notifications on system tray for background/terminated states
  // History is cached locally upon in-app foreground reception or center launch
}

class NotificationService {
  final Ref _ref;
  bool _isInitialized = false;

  NotificationService(this._ref);

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Request notification permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Set up background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 3. Set up foreground message handler
        FirebaseMessaging.onMessage.listen((message) {
          if (context.mounted) {
            _handleForegroundMessage(context, message);
          }
        });

        // 4. Set up message click handlers
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (context.mounted) {
            _handleMessageClick(context, message);
          }
        });

        // Handle initial terminated app message launch
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null && context.mounted) {
          _handleMessageClick(context, initialMessage);
        }

        // 5. Setup Token Management
        _setupTokenSync();
      }
    } catch (e) {
      debugPrint('FCM Initialization failed: $e');
    }
  }

  void _setupTokenSync() {
    final repository = _ref.read(notificationRepositoryProvider);

    // Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = _ref.read(authStateProvider).value;
      if (user != null) {
        try {
          await repository.registerDeviceToken(
            userId: user.id,
            role: user.role.name,
            instituteId: user.organizationId,
            fcmToken: token,
          );
        } catch (e) {
          debugPrint('Failed to sync refreshed FCM token: $e');
        }
      }
    });

    // Listen to authState changes
    _ref.listen<AsyncValue<UserProfile?>>(authStateProvider, (prev, next) async {
      final user = next.value;
      final prevUser = prev?.value;

      if (user != null && user != prevUser) {
        // User logged in / refreshed -> register token
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await repository.registerDeviceToken(
              userId: user.id,
              role: user.role.name,
              instituteId: user.organizationId,
              fcmToken: token,
            );
            await syncTopicSubscriptions(user);
          }
        } catch (e) {
          debugPrint('Failed to register FCM token on login: $e');
        }
      } else if (user == null && prevUser != null) {
        // User logged out -> delete token
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await repository.deleteDeviceToken(fcmToken: token);
            await _unsubscribeFromUserTopics(prevUser);
          }
        } catch (e) {
          debugPrint('Failed to delete FCM token on logout: $e');
        }
      }
    });
  }

  Future<void> syncTopicSubscriptions(UserProfile user) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Subscribe to global topics
      await messaging.subscribeToTopic('global');
      await messaging.subscribeToTopic(user.role.name);
      
      if (user.organizationId != null) {
        await messaging.subscribeToTopic('institute_${user.organizationId}');
      }
      
      // Additional topics
      if (user.role == UserProfileRole.student) {
        await messaging.subscribeToTopic('student');
      } else if (user.role == UserProfileRole.teacher) {
        await messaging.subscribeToTopic('teacher');
      } else if (user.role == UserProfileRole.admin) {
        await messaging.subscribeToTopic('admin');
      }
    } catch (e) {
      debugPrint('FCM topic subscription failed: $e');
    }
  }

  Future<void> _unsubscribeFromUserTopics(UserProfile user) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.unsubscribeFromTopic('global');
      await messaging.unsubscribeFromTopic(user.role.name);
      
      if (user.organizationId != null) {
        await messaging.unsubscribeFromTopic('institute_${user.organizationId}');
      }
      
      if (user.role == UserProfileRole.student) {
        await messaging.unsubscribeFromTopic('student');
      } else if (user.role == UserProfileRole.teacher) {
        await messaging.unsubscribeFromTopic('teacher');
      } else if (user.role == UserProfileRole.admin) {
        await messaging.unsubscribeFromTopic('admin');
      }
    } catch (e) {
      debugPrint('FCM topic unsubscription failed: $e');
    }
  }

  Future<void> _handleForegroundMessage(BuildContext context, RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final type = data['type'] as String?;
    final screen = data['screen'] as String?;
    final payload = data['payload'] as String?;

    // Create local Isar record
    final localNotif = CachedNotification1816()
      ..remoteId = message.messageId
      ..title = notification.title ?? 'No Title'
      ..body = notification.body ?? 'No Body'
      ..receivedAt = DateTime.now()
      ..isRead = false
      ..type = type
      ..screen = screen
      ..payload = payload;

    // Save locally
    await _ref.read(notificationHistoryProvider.notifier).addNotification(localNotif);

    // Show in-app banner alertSnack
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(notification.body ?? ''),
            ],
          ),
          action: screen != null
              ? SnackBarAction(
                  label: 'View',
                  onPressed: () => _handleDeepLink(context, screen, payload),
                )
              : null,
        ),
      );
    }
  }

  void _handleMessageClick(BuildContext context, RemoteMessage message) {
    final data = message.data;
    final screen = data['screen'] as String?;
    final payload = data['payload'] as String?;

    if (screen != null) {
      _handleDeepLink(context, screen, payload);
    }
  }

  void _handleDeepLink(BuildContext context, String screen, String? payload) {
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = json.decode(payload) as Map<String, dynamic>;
        context.go(screen, extra: decoded);
        return;
      } catch (_) {}
    }
    context.go(screen);
  }
}

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
