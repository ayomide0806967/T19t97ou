import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});

  final double size;

  static const _assetPath = 'assets/images/in_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      height: size,
      width: size,
      fit: BoxFit.contain,
      semanticLabel: 'App logo',
    );
  }
}
