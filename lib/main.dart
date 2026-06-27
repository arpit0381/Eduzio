import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
// Conditional: native initializes Isar inside ProviderScope; web skips it
import 'core/storage/isar_initializer.dart'
    if (dart.library.html) 'core/storage/isar_initializer_web.dart';

// ─────────────────────────────────────────────
// ⚠️  REPLACE these with your real Supabase project values.
// You can find them in: Supabase Dashboard → Project Settings → API
// ─────────────────────────────────────────────
const _supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase FIRST — must happen before any provider reads it
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  // 2. Initialize platform-specific storage (Isar on native, no-op on web)
  //    and wrap app in ProviderScope
  final root = await createRootWidget(const EduzioApp());

  runApp(root);
}

class EduzioApp extends ConsumerWidget {
  const EduzioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Eduzio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
