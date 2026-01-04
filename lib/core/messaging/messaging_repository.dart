import '../supabase/supabase_messaging_repository.dart';

// Re-export models from the Supabase implementation
export '../supabase/supabase_messaging_repository.dart'
    show Conversation, Participant, Message;

/// Domain-level contract for messaging operations.
///
/// This interface decouples UI from storage implementation.
abstract class MessagingRepository {
  /// Get all conversations for current user.
  Future<List<Conversation>> getConversations();

  /// Get or create a direct conversation with another user.
  Future<String> getOrCreateDirectConversation(String otherUserId);

  /// Get messages for a conversation.
  Future<List<Message>> getMessages(String conversationId, {int limit = 50});

  /// Watch messages in a conversation with realtime updates.
  Stream<List<Message>> watchMessages(String conversationId);

  /// Send a message.
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? replyToId,
    List<String>? mediaUrls,
  });

  /// Mark conversation as read.
  Future<void> markConversationAsRead(String conversationId);

  /// Get total unread message count across all conversations.
  Future<int> getTotalUnreadCount();
}

