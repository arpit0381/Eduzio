import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/attendance/data/models/isar_attendance_record.dart';
import '../../features/notification/data/models/isar_notification.dart';
import '../../features/notification/presentation/controllers/notification_controller.dart';
import '../../features/upload/data/models/isar_upload_task.dart';
import 'isar_database.dart';

/// Returns a ProviderScope with Isar initialized on native platforms.
Future<Widget> createRootWidget(Widget child, SharedPreferences prefs) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      IsarAttendanceRecordSchema,
      CachedNotification6200Schema,
      IsarUploadTaskSchema,
    ],
    directory: dir.path,
  );
  return ProviderScope(
    overrides: [
      isarProvider.overrideWithValue(isar),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: child,
  );
}
