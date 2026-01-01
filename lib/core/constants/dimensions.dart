/// Standardized dimensions, spacing, and sizing constants.
///
/// Use these instead of magic numbers throughout the codebase
/// to ensure visual consistency and easier maintenance.
class Dimensions {
  Dimensions._();

  // ─────────────────────────────────────────────────────────────────────────
  // Spacing (used for padding, margins, gaps)
  // ─────────────────────────────────────────────────────────────────────────

  /// Extra small spacing: 4.0
  static const double xs = 4.0;

  /// Small spacing: 8.0
  static const double sm = 8.0;

  /// Medium spacing: 12.0
  static const double md = 12.0;

  /// Default spacing: 16.0
  static const double df = 16.0;

  /// Large spacing: 24.0
  static const double lg = 24.0;

  /// Extra large spacing: 32.0
  static const double xl = 32.0;

  /// Extra extra large spacing: 48.0
  static const double xxl = 48.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Border Radius
  // ─────────────────────────────────────────────────────────────────────────

  /// Small radius: 8.0
  static const double radiusSm = 8.0;

  /// Medium radius: 12.0
  static const double radiusMd = 12.0;

  /// Large radius: 16.0
  static const double radiusLg = 16.0;

  /// Extra large radius: 20.0
  static const double radiusXl = 20.0;

  /// Card radius: 28.0
  static const double radiusCard = 28.0;

  /// Pill/stadium radius: 999.0
  static const double radiusPill = 999.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Icon Sizes
  // ─────────────────────────────────────────────────────────────────────────

  /// Small icon: 16.0
  static const double iconSm = 16.0;

  /// Medium icon: 20.0
  static const double iconMd = 20.0;

  /// Default icon: 24.0
  static const double iconDf = 24.0;

  /// Large icon: 28.0
  static const double iconLg = 28.0;

  /// Extra large icon: 32.0
  static const double iconXl = 32.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Avatar Sizes
  // ─────────────────────────────────────────────────────────────────────────

  /// Small avatar: 32.0
  static const double avatarSm = 32.0;

  /// Medium avatar: 40.0
  static const double avatarMd = 40.0;

  /// Default avatar: 48.0
  static const double avatarDf = 48.0;

  /// Large avatar: 64.0
  static const double avatarLg = 64.0;

  /// Extra large avatar: 80.0
  static const double avatarXl = 80.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Component Sizes
  // ─────────────────────────────────────────────────────────────────────────

  /// App bar height: 56.0
  static const double appBarHeight = 56.0;

  /// Bottom nav height: 64.0
  static const double bottomNavHeight = 64.0;

  /// Button height: 48.0
  static const double buttonHeight = 48.0;

  /// Input field height: 56.0
  static const double inputHeight = 56.0;

  /// Divider thickness: 0.6
  static const double dividerThickness = 0.6;

  /// Max content width (for centered layouts): 720.0
  static const double maxContentWidth = 720.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Touch Targets
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum touch target size (accessibility): 44.0
  static const double minTouchTarget = 44.0;

  /// Splash radius for buttons: 22.0
  static const double splashRadius = 22.0;
}

/// Animation durations used throughout the app.
class Durations {
  Durations._();

  /// Fast animation: 150ms
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal animation: 250ms
  static const Duration normal = Duration(milliseconds: 250);

  /// Slow animation: 350ms
  static const Duration slow = Duration(milliseconds: 350);

  /// Page transition: 300ms
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// Toast display: 1500ms
  static const Duration toast = Duration(milliseconds: 1500);

  /// Long toast display: 2500ms
  static const Duration toastLong = Duration(milliseconds: 2500);

  /// Refresh indicator spin: 1500ms
  static const Duration refreshSpin = Duration(milliseconds: 1500);
}

/// Opacity values for consistent transparency.
class Opacities {
  Opacities._();

  /// Disabled state: 0.38
  static const double disabled = 0.38;

  /// Subtle/hint: 0.5
  static const double subtle = 0.5;

  /// Secondary: 0.65
  static const double secondary = 0.65;

  /// Nearly opaque: 0.87
  static const double high = 0.87;

  /// Overlay background: 0.5
  static const double overlay = 0.5;

  /// Divider light mode: 0.06
  static const double dividerLight = 0.06;

  /// Divider dark mode: 0.12
  static const double dividerDark = 0.12;
}
