import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod controller that manages the current [ThemeMode] with self-contained
/// persistence via SharedPreferences.
///
/// This is a modern Riverpod-only implementation that does not depend on
/// any legacy ChangeNotifier classes.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _themeModeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    // Load theme mode asynchronously on first build
    _loadAsync();
    return ThemeMode.light; // Default until loaded
  }

  Future<void> _loadAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    final ThemeMode mode = switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    if (state != mode) {
      state = mode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_themeModeKey, value);
  }

  Future<void> toggleDarkMode(bool enabled) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
