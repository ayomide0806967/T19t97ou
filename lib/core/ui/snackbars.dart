import 'package:flutter/material.dart';

Future<void> showComingSoonSnackBar(
  BuildContext context,
  String feature, {
  bool popRoute = true,
}) async {
  if (popRoute) {
    Navigator.of(context).maybePop();
  }

  final messenger = ScaffoldMessenger.of(context);
  final theme = Theme.of(context);

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        '$feature is coming soon',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 2),
    ),
  );
}
