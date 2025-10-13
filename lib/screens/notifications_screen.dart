import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = _sampleNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationTile(notification: notification);
        },
      ),
    );
  }
}

class _Notification {
  const _Notification({
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isNew = false,
  });

  final String title;
  final String body;
  final String timeAgo;
  final bool isNew;
}

const _sampleNotifications = <_Notification>[
  _Notification(
    title: 'New mentor reply',
    body: 'Dr. Maya Chen shared pointers on your sterile dressing question.',
    timeAgo: '2m ago',
    isNew: true,
  ),
  _Notification(
    title: 'Checklist reminder',
    body: 'Complete the OSCE airway simulation before Friday.',
    timeAgo: '15m ago',
  ),
  _Notification(
    title: 'Group invite',
    body: 'Clinical Skills Lab added you to “Medication Safety Sprint”.',
    timeAgo: '1h ago',
  ),
  _Notification(
    title: 'Insight drop',
    body: 'Leadership Forum posted a new shift handover framework.',
    timeAgo: '3h ago',
  ),
  _Notification(
    title: 'Saved session update',
    body: 'Night Shift Recovery tips now include a quick breathing routine.',
    timeAgo: 'Yesterday',
  ),
];

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final _Notification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.65 : 0.6);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor:
              AppTheme.accent.withValues(alpha: isDark ? 0.3 : 0.15),
          child: Icon(
            notification.isNew ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
            color: AppTheme.accent,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtle,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              notification.timeAgo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: subtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: notification.isNew
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
