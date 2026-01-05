import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.tintColor});

  final double size;
  final Color? tintColor;

  static const _assetPath = 'assets/images/homelogo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _assetPath,
      height: size,
      width: size,
      fit: BoxFit.contain,
      semanticLabel: 'App logo',
    );

    final tint = tintColor;
    if (tint == null) return image;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: image,
    );
  }
}
