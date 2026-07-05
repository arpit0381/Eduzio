import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notification/presentation/controllers/notification_controller.dart';

/// Web stub: returns a plain ProviderScope with SharedPreferences overrides.
Future<Widget> createRootWidget(Widget child, SharedPreferences prefs) async {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: child,
  );
}
