import 'package:flutter/material.dart';
import 'dart:async';

class AppToast {
  AppToast._();

  static OverlayEntry? _activeTopEntry;
  static Timer? _activeTopTimer;

  static void showSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        duration: duration,
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static OverlayEntry? showTopOverlay(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    // Ensure toasts aren't tied to the lifetime of the calling widget.
    // Replace any existing toast and cancel its timer.
    _activeTopTimer?.cancel();
    _activeTopTimer = null;
    final previous = _activeTopEntry;
    if (previous != null && previous.mounted) {
      previous.remove();
    }

    final theme = Theme.of(context);
    const logoOrange = Color(0xFFFF7A1A);
    // 10% transparent background (90% opaque), but softened by mixing with white.
    final Color bg = Color.lerp(Colors.white, logoOrange, 0.18)!
        .withValues(alpha: 0.9);
    final Color border = Color.lerp(Colors.white, logoOrange, 0.45)!
        .withValues(alpha: 0.9);
    final Color iconBg = logoOrange.withValues(alpha: 0.95);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Material(
                color: bg,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: border, width: 1.25),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _activeTopEntry = entry;
    _activeTopTimer = Timer(duration, () {
      if (entry.mounted) entry.remove();
      if (identical(_activeTopEntry, entry)) _activeTopEntry = null;
      _activeTopTimer = null;
    });
    return entry;
  }
}
