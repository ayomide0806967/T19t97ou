import 'package:flutter/material.dart';

class FloatingNavBarDestination {
  const FloatingNavBarDestination({
    required this.icon,
    this.label,
    this.onTap,
  });

  final IconData icon;
  final String? label; // unused in current layout, kept for backwards compatibility
  final VoidCallback? onTap;
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    this.onIndexChange,
    this.margin = const EdgeInsets.fromLTRB(24, 0, 24, 16),
  }) : assert(destinations.length >= 2);

  final int currentIndex;
  final List<FloatingNavBarDestination> destinations;
  final ValueChanged<int>? onIndexChange;
  final EdgeInsets margin;

  bool get _hasCenterButton =>
      destinations.length.isOdd && destinations.length >= 3;

  int get _centerIndex => destinations.length ~/ 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color activeColor =
        isDark ? Colors.white : const Color(0xFF111827);
    final Color inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF9CA3AF);
    final Color centralBackground = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFF3F4F6);
    final Color centralIconColor =
        isDark ? Colors.white : const Color(0xFF1F2937);
    final Color indicatorColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFFCFD4DA);

    return Padding(
      padding: margin,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(destinations.length, (index) {
                  final destination = destinations[index];
                  final bool isActive = currentIndex == index;
                  final bool isCenter = _hasCenterButton &&
                      index == _centerIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        onIndexChange?.call(index);
                        destination.onTap?.call();
                      },
                      child: Center(
                        child: isCenter
                            ? Container(
                                height: 48,
                                width: 72,
                                decoration: BoxDecoration(
                                  color: centralBackground,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: isDark
                                      ? const []
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.06),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Icon(
                                  destination.icon,
                                  size: 26,
                                  color: centralIconColor,
                                ),
                              )
                            : Icon(
                                destination.icon,
                                size: isActive ? 28 : 26,
                                color: isActive ? activeColor : inactiveColor,
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 96,
              height: 3,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
