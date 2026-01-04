import 'dart:async';

import 'notification_repository.dart';

/// Local in-memory implementation of [NotificationRepository].
///
/// This is suitable for offline/demo mode; notifications are not persisted.
class LocalNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _items = <NotificationItem>[];
  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();

  @override
  List<NotificationItem> get notifications =>
      List<NotificationItem>.unmodifiable(_items);

  @override
  Stream<List<NotificationItem>> watchNotifications() =>
      _controller.stream;

  @override
  int get unreadCount =>
      _items.where((n) => !n.isRead).length;

  @override
  Future<void> load() async {
    // No-op for local mode; start with empty list.
    _emit();
  }

  @override
  Future<void> markAsRead(List<String> notificationIds) async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (notificationIds.contains(item.id) && !item.isRead) {
        _items[i] = item.copyWith(isRead: true);
      }
    }
    _emit();
  }

  @override
  Future<int> markAllAsRead() async {
    int changed = 0;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!item.isRead) {
        _items[i] = item.copyWith(isRead: true);
        changed++;
      }
    }
    if (changed > 0) {
      _emit();
    }
    return changed;
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    _items.removeWhere((n) => n.id == notificationId);
    _emit();
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(List<NotificationItem>.unmodifiable(_items));
  }

  void dispose() {
    _controller.close();
  }
}
