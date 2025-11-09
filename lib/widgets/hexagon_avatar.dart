import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HexagonAvatar extends StatelessWidget {
  const HexagonAvatar({
    super.key,
    required this.size,
    this.backgroundColor,
    this.borderColor,
    this.child,
    this.borderWidth = 3,
    this.image,
    this.imageFit = BoxFit.cover,
  });

  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? child;
  final double borderWidth;
  final ImageProvider<Object>? image;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    // Render as a sharp rectangle avatar (four corners),
    // keeping the existing API for drop-in replacement.
    final bg = backgroundColor ?? AppTheme.buttonSecondary;
    final br = BorderRadius.zero;
    final Color borderCol =
        (borderColor ?? AppTheme.accent.withValues(alpha: 0.35));

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          border: Border.all(color: borderCol, width: borderWidth.clamp(0, 6)),
        ),
        child: ClipRRect(
          borderRadius: br,
          child: image != null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    image: DecorationImage(image: image!, fit: imageFit),
                  ),
                  child: child == null ? null : Center(child: child),
                )
              : Container(color: bg, child: child),
        ),
      ),
    );
  }
}
