import 'dart:ui';

import 'package:flutter/material.dart';

class FloatingNavBarDestination {
  const FloatingNavBarDestination({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    this.onIndexChange,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 28),
  }) : assert(destinations.length >= 2);

  final int currentIndex;
  final List<FloatingNavBarDestination> destinations;
  final ValueChanged<int>? onIndexChange;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color background = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.78);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final Color activeColor = theme.colorScheme.onSurface;
    final Color inactiveColor = activeColor.withValues(alpha: 0.45);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  children: List.generate(destinations.length, (index) {
                    final destination = destinations[index];
                    final bool isActive = currentIndex == index;
                    final Color color = isActive ? activeColor : inactiveColor;

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          onIndexChange?.call(index);
                          destination.onTap?.call();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(destination.icon, size: 22, color: color),
                              const SizedBox(height: 4),
                              Text(
                                destination.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
