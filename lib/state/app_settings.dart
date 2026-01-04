import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application settings state.
///
/// This is an immutable state class used by [AppSettingsNotifier].
@immutable
class AppSettingsState {
  const AppSettingsState({
    this.isLoaded = false,
  });

  final bool isLoaded;

  AppSettingsState copyWith({
    bool? isLoaded,
  }) {
    return AppSettingsState(
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Riverpod notifier for managing application settings.
///
/// Handles any app-wide settings that don't fit into the theme or preferences
/// controllers. This is deliberately minimal - most settings are now handled by:
/// - [ThemeModeController] for theme mode
/// - [AppPreferencesController] for user preferences
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    // Mark as loaded immediately since we don't have async dependencies anymore
    return const AppSettingsState(isLoaded: true);
  }

  /// Clear all app-wide settings. This is rarely needed but available for
  /// reset functionality.
  Future<void> clearAll() async {
    // Only clear app settings state, not preferences or theme
    // (those are handled by their respective controllers).
    state = const AppSettingsState(isLoaded: true);
  }
}

/// Provider for app settings state.
final appSettingsNotifierProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);
