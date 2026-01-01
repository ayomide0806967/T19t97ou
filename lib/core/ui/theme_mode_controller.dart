import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/app_providers.dart';

/// Riverpod controller that exposes and mutates the current [ThemeMode].
///
/// This sits on top of the existing [AppSettings] ChangeNotifier, so that
/// widgets can rely on a simple Riverpod state while `AppSettings` handles
/// persistence.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.read(appSettingsProvider);
    return settings.themeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref.read(appSettingsProvider).setThemeMode(mode);
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

