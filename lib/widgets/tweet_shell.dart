import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TweetShell extends StatelessWidget {
  const TweetShell({
    required this.child,
    this.showBorder = false,
    this.backgroundColor,
    this.cornerAccentColor,
    this.showCornerAccent = true,
    super.key,
  });

  final Widget child;
  final bool showBorder;
  final Color? backgroundColor;
  final Color? cornerAccentColor;
  final bool showCornerAccent;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg =
        backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white);
    final Color border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.accent.withValues(alpha: 0.3);

    final Color accent =
        cornerAccentColor ??
        AppTheme.accent.withValues(alpha: isDark ? 0.05 : 0.1);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _radius,
        border: showBorder ? Border.all(color: border) : null,
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          children: [
            if (showCornerAccent)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(26),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
