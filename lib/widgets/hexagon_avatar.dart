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
    final bg = backgroundColor ?? AppTheme.buttonSecondary;
    final border = borderColor ?? AppTheme.accent.withValues(alpha: 0.4);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: _HexagonClipper(),
            child: Container(color: border),
          ),
          Padding(
            padding: EdgeInsets.all(borderWidth.clamp(0, size / 4)),
            child: ClipPath(
              clipper: _HexagonClipper(),
              child: image != null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: bg,
                        image: DecorationImage(
                          image: image!,
                          fit: imageFit,
                        ),
                      ),
                      child: child == null
                          ? null
                          : Center(child: child),
                    )
                  : Container(color: bg, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final side = w / 2;
    final triangleHeight = (side * 0.57735); // tan(30deg)

    path
      ..moveTo(w / 2, 0)
      ..lineTo(w, triangleHeight)
      ..lineTo(w, h - triangleHeight)
      ..lineTo(w / 2, h)
      ..lineTo(0, h - triangleHeight)
      ..lineTo(0, triangleHeight)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
