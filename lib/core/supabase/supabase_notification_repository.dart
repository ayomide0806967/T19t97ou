import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../notification/notification_repository.dart';

/// Repository for user notifications.
///
/// Uses the `notifications` table with realtime subscriptions for instant updates.
class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;
  final List<NotificationItem> _notifications = <NotificationItem>[];
  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();

  RealtimeChannel? _notificationChannel;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  Stream<List<NotificationItem>> watchNotifications() => _controller.stream;

  /// Get the unread count for the notification badge.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Load notifications for current user.
  Future<void> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final rows = await _client
        .from('notifications')
        .select('*, actor:profiles!actor_id(full_name, handle, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    _notifications
      ..clear()
      ..addAll((rows as List).map((row) => _fromRow(row)));
    _emit();

    // Subscribe to realtime
    _subscribeToNotifications(userId);
  }

  void _subscribeToNotifications(String userId) {
    _notificationChannel?.unsubscribe();
    _notificationChannel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Add new notification to the top
            final newNotification = _fromRow(payload.newRecord);
            _notifications.insert(0, newNotification);
            _emit();
          },
        )
        .subscribe();
  }

  /// Mark specific notifications as read.
  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    await _client.rpc('mark_notifications_read', params: {
      'p_notification_ids': notificationIds,
    });

    for (final id in notificationIds) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    }
    _emit();
  }

  /// Mark all notifications as read.
  Future<int> markAllAsRead() async {
    final result = await _client.rpc('mark_all_notifications_read');
    final count = result as int? ?? 0;

    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _emit();
    return count;
  }

  /// Delete a notification.
  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);

    _notifications.removeWhere((n) => n.id == notificationId);
    _emit();
  }

  NotificationItem _fromRow(Map<String, dynamic> row) {
    final actor = row['actor'] as Map<String, dynamic>?;

    return NotificationItem(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String? ?? '',
      body: row['body'] as String?,
      actorId: row['actor_id'] as String?,
      actorName: actor?['full_name'] as String?,
      actorHandle: actor?['handle'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      targetType: row['target_type'] as String?,
      targetId: row['target_id'] as String?,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_notifications));
    }
  }

  void dispose() {
    _notificationChannel?.unsubscribe();
    _controller.close();
  }
}

/// Model for a notification item.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.actorId,
    this.actorName,
    this.actorHandle,
    this.actorAvatarUrl,
    this.targetType,
    this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? actorId;
  final String? actorName;
  final String? actorHandle;
  final String? actorAvatarUrl;
  final String? targetType;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? actorId,
    String? actorName,
    String? actorHandle,
    String? actorAvatarUrl,
    String? targetType,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorHandle: actorHandle ?? this.actorHandle,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
