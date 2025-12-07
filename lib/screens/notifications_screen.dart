import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> _filters = const [
    'All',
    'Follows',
    'Conversations',
    'Reposts',
  ];
  int _selectedFilterIndex = 0;

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildFilterChips(theme),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 20,
                thickness: 0.6,
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                // For now, the sample data is not categorized;
                // all filters show the same list but the UI matches
                // the Instagram-style segmented control.
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _NotificationTile(notification: notification),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color baseBorder = theme.dividerColor.withValues(
      alpha: isDark ? 0.5 : 0.35,
    );
    final Color selectedBg =
        isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white;
    final Color unselectedBg =
        isDark ? Colors.white.withValues(alpha: 0.04) : theme.cardColor;
    final Color selectedText = theme.colorScheme.onSurface;
    final Color unselectedText = theme.colorScheme.onSurface.withValues(
      alpha: 0.85,
    );

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < _filters.length; i++) ...[
              if (i == 0) const SizedBox(width: 4),
              _buildFilterPill(
                label: _filters[i],
                selected: _selectedFilterIndex == i,
                theme: theme,
                selectedBg: selectedBg,
                unselectedBg: unselectedBg,
                selectedText: selectedText,
                unselectedText: unselectedText,
                borderColor: baseBorder,
                onTap: () {
                  setState(() => _selectedFilterIndex = i);
                },
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required ThemeData theme,
    required Color selectedBg,
    required Color unselectedBg,
    required Color selectedText,
    required Color unselectedText,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final Color bg = selected ? selectedBg : unselectedBg;
    final Color fg = selected ? selectedText : unselectedText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
            width: 1.1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
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
    final onSurface = theme.colorScheme.onSurface;
    final bool isDark = theme.brightness == Brightness.dark;
    final subtle = onSurface.withValues(alpha: isDark ? 0.65 : 0.6);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            AppTheme.accent.withValues(alpha: isDark ? 0.3 : 0.15),
        child: Icon(
          notification.isNew
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_rounded,
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
    );
  }
}
