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
    this.margin = EdgeInsets.zero,
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
    final Color barBorder = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.22,
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: barBorder)),
        ),
        padding: margin,
        child: SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final bool isActive = currentIndex == index;
              final bool isCenter = _hasCenterButton && index == _centerIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    onIndexChange?.call(index);
                    destination.onTap?.call();
                  },
                  child: Center(
                    child: Icon(
                      destination.icon,
                      size: isCenter ? 34 : (isActive ? 34 : 32),
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
