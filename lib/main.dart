import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services here (e.g., Supabase, Isar, etc. in future milestones)

  runApp(
    const ProviderScope(
      child: EduzioApp(),
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
