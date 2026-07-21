import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../data/models/isar_notification.dart';
import 'notification_controller.dart';

// Background handler must be a top-level function annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Error initializing Firebase in background handler: $e');
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final Ref _ref;
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (Firebase.apps.isEmpty) {
      debugPrint('FCM Initialization skipped: Firebase is not initialized.');
      return;
    }

    try {
      // 1. Create High Importance Notification Channel on Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
      }

      // 2. Initialize Flutter Local Notifications Plugin
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initializationSettingsDarwin = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          if (details.payload != null && details.payload!.isNotEmpty && context.mounted) {
            try {
              final data = json.decode(details.payload!) as Map<String, dynamic>;
              final screen = data['screen'] as String?;
              final payload = data['payload'] as String?;
              if (screen != null) {
                _handleDeepLink(context, screen, payload);
              }
            } catch (e) {
              debugPrint('Error parsing notification payload click: $e');
            }
          }
        },
      );

      // 3. Set foreground notification options for FCM
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Request notification permissions from FCM
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 5. Set up background message handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        // 6. Set up foreground message handler
        FirebaseMessaging.onMessage.listen((message) {
          if (context.mounted) {
            _handleForegroundMessage(context, message);
          }
        });

        // 7. Set up message click handlers
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

        // 8. Setup Token Management
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
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Notification';
    final body = notification?.body ?? data['body'] ?? '';
    final type = data['type'] as String?;
    final screen = data['screen'] as String?;
    final payload = data['payload'] as String?;

    // Show heads-up alert banner with sound in foreground
    if (!kIsWeb) {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/launcher_icon',
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
      );

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
        payload: json.encode(data),
      );
    }

    // Create local Isar record
    final localNotif = CachedNotification1816()
      ..remoteId = message.messageId
      ..title = title
      ..body = body
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
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(body),
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
