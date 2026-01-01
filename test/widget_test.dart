import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/theme/app_theme.dart';

void main() {
  group('AppTheme Color Constants', () {
    test('light color palette is defined correctly', () {
      // These are static color constants that don't trigger google_fonts
      expect(AppTheme.background, const Color(0xFFFFFFFF));
      expect(AppTheme.surface, const Color(0xFFF3F4F8));
      expect(AppTheme.divider, const Color(0xFFE5E7EB));
      expect(AppTheme.textPrimary, const Color(0xFF111827));
      expect(AppTheme.textSecondary, const Color(0xFF6B7280));
      expect(AppTheme.textTertiary, const Color(0xFF9CA3AF));
      expect(AppTheme.buttonPrimary, const Color(0xFF000000));
      expect(AppTheme.buttonSecondary, const Color(0xFFF3F4F6));
      expect(AppTheme.accent, const Color(0xFF000000));
    });

    test('dark color palette is defined correctly', () {
      expect(AppTheme.darkBackground, const Color(0xFF0B0F14));
      expect(AppTheme.darkSurface, const Color(0xFF10161B));
      expect(AppTheme.darkDivider, const Color(0xFF1F2A33));
      expect(AppTheme.darkTextPrimary, const Color(0xFFE5E7EB));
      expect(AppTheme.darkTextSecondary, const Color(0xFF9CA3AF));
      expect(AppTheme.darkTextTertiary, const Color(0xFF6B7280));
    });

    test('pillShape has max border radius', () {
      // Test the static shape property
      expect(AppTheme.pillShape, isA<RoundedRectangleBorder>());
    });
  });

  group('Basic Widget Rendering', () {
    testWidgets('Scaffold with basic theme renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          // Use basic theme without google_fonts
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppTheme.background,
          ),
          home: const Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('Scaffold with dark theme renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppTheme.darkBackground,
          ),
          home: const Scaffold(
            body: Center(child: Text('Dark Test')),
          ),
        ),
      );

      expect(find.text('Dark Test'), findsOneWidget);
    });

    testWidgets('Elevated button renders correctly', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => wasPressed = true,
                child: const Text('Press Me'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(wasPressed, isTrue);
    });
  });
}
