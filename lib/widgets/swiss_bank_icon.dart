import 'package:flutter/material.dart';

class SwissBankIcon extends StatelessWidget {
  const SwissBankIcon({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidthFactor = 0.06,
    this.refreshProgress,
    this.refreshDotColor = Colors.black,
  });

  final double size;
  final Color? color;
  final double strokeWidthFactor;
  final Animation<double>? refreshProgress;
  final Color refreshDotColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/homelogo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
