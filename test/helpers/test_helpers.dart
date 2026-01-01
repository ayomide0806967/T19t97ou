import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/di/app_providers.dart';
import 'package:my_app/services/data_service.dart';
import 'package:my_app/services/profile_service.dart';
import 'package:my_app/state/app_settings.dart';

/// Creates a [ProviderScope] with mocked dependencies for testing.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(
///   createTestApp(child: YourWidget()),
/// );
/// ```
Widget createTestApp({
  required Widget child,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: [
      // Provide test implementations of core services
      appSettingsProvider.overrideWithValue(AppSettings()),
      dataServiceProvider.overrideWithValue(DataService()),
      profileServiceProvider.overrideWithValue(ProfileService()),
      ...?overrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Creates a [ProviderContainer] for unit testing providers.
///
/// Usage:
/// ```dart
/// final container = createProviderContainer();
/// final value = container.read(someProvider);
/// ```
ProviderContainer createProviderContainer({
  List<Override>? overrides,
}) {
  final container = ProviderContainer(
    overrides: [
      appSettingsProvider.overrideWithValue(AppSettings()),
      dataServiceProvider.overrideWithValue(DataService()),
      profileServiceProvider.overrideWithValue(ProfileService()),
      ...?overrides,
    ],
  );
  
  // Ensure the container is disposed after the test
  addTearDown(container.dispose);
  
  return container;
}

/// Pumps the widget and settles all animations/frames.
extension WidgetTesterExtensions on WidgetTester {
  /// Pumps and settles with a timeout to avoid infinite animations.
  Future<void> pumpAndSettleWithTimeout([
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    await pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  }
}

/// Matcher for finding widgets by key prefix.
Finder findByKeyPrefix(String prefix) {
  return find.byWidgetPredicate(
    (widget) => widget.key?.toString().contains(prefix) ?? false,
  );
}

/// Creates a mock [ThemeData] for consistent testing.
ThemeData createTestTheme({
  Brightness brightness = Brightness.light,
}) {
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: brightness,
    ),
  );
}
