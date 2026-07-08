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

  try {
    // Initialize Firebase Core
    try {
      await Firebase.initializeApp();
    } catch (e, stack) {
      debugPrint('Firebase initialization failed: $e\n$stack');
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
  } catch (e, stack) {
    debugPrint('Fatal Startup Error: $e\n$stack');
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), // Red 500
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The application encountered a fatal error during startup. Please share the details below with the developer:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94A3B8), // Slate 400
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Slate 800
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SelectableText(
                        '$e\n\n$stack',
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9), // Slate 100
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
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
