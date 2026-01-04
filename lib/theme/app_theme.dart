import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Light palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF3F4F8);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color buttonPrimary = Color(0xFF000000);
  static const Color buttonSecondary = Color(0xFFF3F4F6);
  // Keep accents grayscale to match the "white/grey only" design.
  static const Color accent = Color(0xFF9CA3AF);

  // Dark palette
  static const Color darkBackground = Color(0xFF0B0F14);
  static const Color darkSurface = Color(0xFF10161B);
  static const Color darkDivider = Color(0xFF1F2A33);
  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  static final RoundedRectangleBorder pillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(999),
  );

  /// Primary tweet body style – tuned to feel like X's Chirp:
  /// slightly larger, compact line height, light tracking.
  static TextStyle tweetBody(Color color) {
    return GoogleFonts.inter(
      // Approximate Twitter/X mobile styling
      color: color.withValues(alpha: 0.87),
      fontSize: 15,
      height: 1.4,
      letterSpacing: -0.02,
      fontWeight: FontWeight.w400,
    );
  }

  static ThemeData lightTheme = _buildLightTheme();
  static ThemeData darkTheme = _buildDarkTheme();
  static ThemeData blackoutDarkTheme = _buildBlackoutDarkTheme();

  static ThemeData _buildLightTheme() {
    // This app uses a "lights out" grayscale theme across platforms, so the
    // "light" theme is intentionally dark as well (white/grey text only).
    return _buildBlackoutDarkTheme();
  }

  static ThemeData _buildDarkTheme() {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.dark,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: baseColorScheme.copyWith(
        surface: darkSurface,
        onSurface: darkTextPrimary,
        primary: Colors.black,
        secondary: Colors.black,
        tertiary: Colors.black,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    final headline = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      color: darkTextPrimary,
    );

    final body = GoogleFonts.inter(
      color: darkTextSecondary,
      height: 1.5,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        titleTextStyle: headline.copyWith(fontSize: 20),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: headline.copyWith(fontSize: 36, letterSpacing: -0.8),
        headlineMedium: headline.copyWith(fontSize: 26, letterSpacing: -0.3),
        headlineSmall: headline.copyWith(fontSize: 20),
        bodyLarge: body.copyWith(fontSize: 15, color: darkTextSecondary),
        bodyMedium: body.copyWith(fontSize: 13, color: darkTextSecondary),
        bodySmall: body.copyWith(fontSize: 12, color: darkTextTertiary),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: darkTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B0F14),
        hintStyle: GoogleFonts.inter(color: darkTextTertiary),
        labelStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: darkTextTertiary, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: darkDivider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: pillShape,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF0B0F14),
          foregroundColor: darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: pillShape,
          side: const BorderSide(color: darkDivider),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: darkDivider,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: darkTextPrimary,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: darkDivider,
    );
  }

  static ThemeData _buildBlackoutDarkTheme() {
    final base = _buildDarkTheme();
    final ColorScheme cs = base.colorScheme.copyWith(
      surface: const Color(0xFF0B0F14),
      background: Colors.black,
      onBackground: darkTextPrimary,
      onSurface: darkTextPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: cs,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: Colors.white.withValues(alpha: 0.12),
      cardTheme: base.cardTheme.copyWith(
        color: const Color(0xFF0B0F14),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: const Color(0xFF0B0F14),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
