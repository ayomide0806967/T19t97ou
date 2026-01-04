import '../supabase/supabase_notification_repository.dart';

// Re-export model from the Supabase implementation so UI code
// can depend on a single domain-level type.
export '../supabase/supabase_notification_repository.dart'
    show NotificationItem;

/// Domain-level contract for notification operations.
///
/// This interface decouples UI from storage implementation.
abstract class NotificationRepository {
  /// Get the current list of notifications.
  List<NotificationItem> get notifications;

  /// Stream of notification updates for reactive UI.
  Stream<List<NotificationItem>> watchNotifications();

  /// Get current unread count.
  int get unreadCount;

  /// Load notifications for current user.
  Future<void> load();

  /// Mark specific notifications as read.
  Future<void> markAsRead(List<String> notificationIds);

  /// Mark all notifications as read.
  Future<int> markAllAsRead();

  /// Delete a notification.
  Future<void> deleteNotification(String notificationId);
}
