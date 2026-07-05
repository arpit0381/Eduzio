import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/notification/presentation/controllers/notification_service.dart';
// Conditional: native initializes Isar inside ProviderScope; web skips it
import 'core/storage/isar_initializer.dart'
    if (dart.library.html) 'core/storage/isar_initializer_web.dart';

const _supabaseUrl = 'https://ntrpizllaqplbyksjqgr.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50cnBpemxsYXFwbGJ5a3NqcWdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MTA2ODAsImV4cCI6MjA5ODA4NjY4MH0.47NmxltJqxz9C4G6p-PRyUr2sQTYAuknehuWzw5yNXE';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  final root = await createRootWidget(const EduzioApp(), prefs);

  runApp(root);
}

class EduzioApp extends ConsumerStatefulWidget {
  const EduzioApp({super.key});

  @override
  ConsumerState<EduzioApp> createState() => _EduzioAppState();
}

class _EduzioAppState extends ConsumerState<EduzioApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'Eduzio',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
