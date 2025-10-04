import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TweetShell extends StatelessWidget {
  const TweetShell({required this.child, super.key});

  final Widget child;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
        boxShadow: [
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
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.circular(36),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
