import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/isar_database.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../data/models/isar_notification.dart';

// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized. Override in main.');
});

// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationRepositoryImpl(supabase, isar, prefs);
});

// Notifier for NotificationPreferences
class NotificationPreferencesController extends Notifier<NotificationPreferences> {
  late final NotificationRepository _repository;

  @override
  NotificationPreferences build() {
    _repository = ref.watch(notificationRepositoryProvider);
    _loadPreferences();
    return const NotificationPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _repository.getPreferences();
    state = prefs;
  }

  Future<void> updatePreference(String category, bool value) async {
    NotificationPreferences updated;
    switch (category) {
      case 'homework':
        updated = state.copyWith(homework: value);
        break;
      case 'attendance':
        updated = state.copyWith(attendance: value);
        break;
      case 'fees':
        updated = state.copyWith(fees: value);
        break;
      case 'results':
        updated = state.copyWith(results: value);
        break;
      case 'events':
        updated = state.copyWith(events: value);
        break;
      case 'announcements':
        updated = state.copyWith(announcements: value);
        break;
      case 'marketing':
        updated = state.copyWith(marketing: value);
        break;
      default:
        return;
    }
    state = updated;
    await _repository.savePreferences(updated);
  }
}

final notificationPreferencesProvider = NotifierProvider<NotificationPreferencesController, NotificationPreferences>(() {
  return NotificationPreferencesController();
});

// AsyncNotifier for NotificationHistory
class NotificationHistoryController extends AutoDisposeAsyncNotifier<List<IsarNotification>> {
  late final NotificationRepository _repository;

  @override
  Future<List<IsarNotification>> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    return _repository.getNotificationHistory();
  }

  Future<void> addNotification(IsarNotification notification) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.saveNotification(notification);
      return _repository.getNotificationHistory();
    });
  }

  Future<void> markAsRead(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.markAsRead(id);
      return _repository.getNotificationHistory();
    });
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.markAllAsRead();
      return _repository.getNotificationHistory();
    });
  }

  Future<void> deleteNotification(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteNotification(id);
      return _repository.getNotificationHistory();
    });
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.clearAllNotifications();
      return [];
    });
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.searchNotifications(query);
    });
  }
}

final notificationHistoryProvider = AutoDisposeAsyncNotifierProvider<NotificationHistoryController, List<IsarNotification>>(() {
  return NotificationHistoryController();
});
