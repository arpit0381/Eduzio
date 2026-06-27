import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../features/attendance/data/models/isar_attendance_record.dart';
import 'isar_database.dart';

/// Returns a ProviderScope with Isar initialized on native platforms.
Future<Widget> createRootWidget(Widget child) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [IsarAttendanceRecordSchema],
    directory: dir.path,
  );
  return ProviderScope(
    overrides: [isarProvider.overrideWithValue(isar)],
    child: child,
  );
}
