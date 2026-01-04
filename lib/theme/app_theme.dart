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
  static const Color accent = Color(0xFF000000); // use black as primary accent

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
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // Pure white app background
      scaffoldBackgroundColor: background,
      // Pure white containers/cards via surface
      colorScheme: baseColorScheme.copyWith(
        surface: Colors.white,
        onSurface: textPrimary,
        primary: Colors.black,
        secondary: Colors.black,
        tertiary: Colors.black,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );

    final headline = GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      color: textPrimary,
    );

    final body = GoogleFonts.inter(
      color: textSecondary,
      height: 1.5,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: headline.copyWith(fontSize: 24),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: headline.copyWith(fontSize: 44, letterSpacing: -1.2),
        headlineMedium: headline.copyWith(fontSize: 32, letterSpacing: -0.5),
        headlineSmall: headline.copyWith(fontSize: 24),
        bodyLarge: body.copyWith(fontSize: 16, color: textSecondary),
        bodyMedium: body.copyWith(fontSize: 14, color: textSecondary),
        bodySmall: body.copyWith(fontSize: 13, color: textTertiary),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        hintStyle: GoogleFonts.inter(color: textTertiary),
        labelStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.black, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.black54),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: buttonPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: pillShape,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: buttonSecondary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: pillShape,
          side: const BorderSide(color: divider),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      // Keep date/time pickers visually white without touching layout.
      datePickerTheme: base.datePickerTheme.copyWith(
        backgroundColor: Colors.white,
        headerBackgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: base.timePickerTheme.copyWith(
        backgroundColor: Colors.white,
        dialBackgroundColor: Colors.white,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.black12,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: Colors.black,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: divider,
    );
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

    final headline = GoogleFonts.spaceGrotesk(
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
        titleTextStyle: headline.copyWith(fontSize: 24),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: headline.copyWith(fontSize: 44, letterSpacing: -1.2),
        headlineMedium: headline.copyWith(fontSize: 32, letterSpacing: -0.5),
        headlineSmall: headline.copyWith(fontSize: 24),
        bodyLarge: body.copyWith(fontSize: 16, color: darkTextSecondary),
        bodyMedium: body.copyWith(fontSize: 14, color: darkTextSecondary),
        bodySmall: body.copyWith(fontSize: 13, color: darkTextTertiary),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: darkTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        hintStyle: GoogleFonts.inter(color: darkTextTertiary),
        labelStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.white, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.white70),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: pillShape,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: darkSurface,
          foregroundColor: darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: pillShape,
          side: const BorderSide(color: darkDivider),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: accent.withValues(alpha: 0.18),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: accent,
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
