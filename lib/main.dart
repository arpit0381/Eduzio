import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/isar_database.dart';
import 'features/attendance/data/models/isar_attendance_record.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar Local Database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [IsarAttendanceRecordSchema],
    directory: dir.path,
  );

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const EduzioApp(),
    ),
  );
}

class EduzioApp extends ConsumerWidget {
  const EduzioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Eduzio',
      debugShowCheckedModeBanner: false,
      
      // Theme settings
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // Router configuration
      routerConfig: router,
    );
  }
}
