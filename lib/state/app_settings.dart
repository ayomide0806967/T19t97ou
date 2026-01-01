import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application settings state.
///
/// This is an immutable state class used by [AppSettingsNotifier].
@immutable
class AppSettingsState {
  const AppSettingsState({
    this.themeMode = ThemeMode.light,
    this.isLoaded = false,
  });

  final ThemeMode themeMode;
  final bool isLoaded;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    bool? isLoaded,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Riverpod notifier for managing application settings.
///
/// Replaces the legacy ChangeNotifier-based AppSettings for
/// consistent state management throughout the app.
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  static const _themeModeKey = 'app_theme_mode';

  @override
  AppSettingsState build() {
    // Load settings asynchronously on first build
    _loadAsync();
    return const AppSettingsState();
  }

  Future<void> _loadAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    final ThemeMode mode;
    switch (value) {
      case 'dark':
        mode = ThemeMode.dark;
      case 'system':
        mode = ThemeMode.system;
      case 'light':
      default:
        mode = ThemeMode.light;
    }
    state = state.copyWith(themeMode: mode, isLoaded: true);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_themeModeKey, value);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}

/// Provider for app settings state.
final appSettingsNotifierProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Legacy Support (for gradual migration)
// ─────────────────────────────────────────────────────────────────────────────

/// Legacy AppSettings class for backward compatibility.
///
/// @deprecated Use [appSettingsNotifierProvider] instead.
/// This class will be removed in a future version.
class AppSettings extends ChangeNotifier {
  static const _themeModeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    switch (value) {
      case 'dark':
        _themeMode = ThemeMode.dark;
      case 'system':
        _themeMode = ThemeMode.system;
      case 'light':
      default:
        _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_themeModeKey, value);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}