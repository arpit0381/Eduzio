import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefKey = 'eduzio_theme_mode';

/// Riverpod provider for managing the app's ThemeMode.
/// Persists to SharedPreferences so it survives app restarts.
final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(() {
  return ThemeController();
});

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.light; // default
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themePrefKey);
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}

// ── Notification Preference ──────────────────────────────────────────────

const _notifPrefKey = 'eduzio_notifications_enabled';

final notificationsEnabledProvider =
    NotifierProvider<NotificationsController, bool>(() {
  return NotificationsController();
});

class NotificationsController extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true; // default: enabled
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_notifPrefKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifPrefKey, state);
  }
}
