import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_providers.dart';
import '../../core/navigation/app_nav.dart';
import '../../core/notification/notification_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tab_scaffold.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<String> _filters = const [
    'All',
    'Follows',
    'Conversations',
    'Reposts',
  ];
  int _selectedFilterIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.load();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<NotificationItem> _filterNotifications(List<NotificationItem> all) {
    switch (_selectedFilterIndex) {
      case 1: // Follows
        return all.where((n) => n.type == 'follow').toList();
      case 2: // Conversations
        return all.where((n) => n.type == 'message').toList();
      case 3: // Reposts
        return all.where((n) => n.type == 'repost').toList();
      default: // All
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(notificationRepositoryProvider);

    return AppTabScaffold(
      currentIndex: 3,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          if (repo.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await repo.markAllAsRead();
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(Icons.mail_outline_rounded, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(AppNav.inbox());
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: repo.watchNotifications(),
        initialData: repo.notifications,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allNotifications = snapshot.data ?? [];
          final notifications = _filterNotifications(allNotifications);

          if (notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildFilterChips(theme),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 24,
                      thickness: 1.0,
                      color: theme.dividerColor.withValues(alpha: 0.55),
                    ),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          repo.deleteNotification(notification.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          child: _NotificationTile(
                            notification: notification,
                            onTap: () {
                              if (!notification.isRead) {
                                repo.markAsRead([notification.id]);
                              }
                              // TODO: Navigate to target
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  final NotificationItem notification;
  final VoidCallback? onTap;

  IconData _iconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_outlined;
      case 'like':
        return Icons.favorite_outline;
      case 'repost':
        return Icons.repeat_rounded;
      case 'comment':
        return Icons.mode_comment_outlined;
      case 'message':
        return Icons.mail_outline;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bool isDark = theme.brightness == Brightness.dark;
    final subtle = onSurface.withValues(alpha: isDark ? 0.65 : 0.6);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            AppTheme.accent.withValues(alpha: isDark ? 0.3 : 0.15),
        child: notification.actorAvatarUrl != null
            ? ClipOval(
                child: Image.network(
                  notification.actorAvatarUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    _iconForType(notification.type),
                    color: AppTheme.accent,
                    size: 20,
                  ),
                ),
              )
            : Icon(
                _iconForType(notification.type),
                color: AppTheme.accent,
                size: 20,
              ),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: onSurface,
          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null) ...[
            const SizedBox(height: 4),
            Text(
              notification.body!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtle,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _formatTimeAgo(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: subtle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: !notification.isRead
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
