import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../messaging/messaging_repository.dart' as repo;

/// Repository for direct messaging.
///
/// Uses:
/// - `conversations` table for conversation metadata
/// - `conversation_participants` for membership
/// - `messages` table for messages with realtime
/// - `message_reads` for read receipts
class SupabaseMessagingRepository implements repo.MessagingRepository {
  SupabaseMessagingRepository(this._client);

  final SupabaseClient _client;

  // ============================================================================
  // Conversations
  // ============================================================================

  /// Get all conversations for current user.
  Future<List<Conversation>> getConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Get conversations where user is a participant
    final rows = await _client
        .from('conversation_participants')
        .select('''
          conversation_id,
          last_read_at,
          is_muted,
          is_archived,
          conversations(id, type, name, avatar_url, created_at, updated_at),
          profiles:user_id(full_name, handle, avatar_url)
        ''')
        .eq('user_id', userId)
        .isFilter('left_at', null)
        .order('conversations(updated_at)', ascending: false);

    final conversations = <Conversation>[];
    for (final row in rows as List) {
      final conv = row['conversations'] as Map<String, dynamic>?;
      if (conv == null) continue;

      // Get other participants for display
      final otherParticipants = await _getOtherParticipants(
        conv['id'] as String,
        userId,
      );

      // Get last message
      final lastMessage = await _getLastMessage(conv['id'] as String);

      // Get unread count
      final unreadCount = await _getUnreadCount(
        conv['id'] as String,
        row['last_read_at'] as String?,
      );

      conversations.add(Conversation(
        id: conv['id'] as String,
        type: conv['type'] as String? ?? 'direct',
        name: conv['name'] as String? ?? otherParticipants.firstOrNull?.name ?? 'Chat',
        avatarUrl: conv['avatar_url'] as String? ?? otherParticipants.firstOrNull?.avatarUrl,
        participants: otherParticipants,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        isMuted: row['is_muted'] as bool? ?? false,
        isArchived: row['is_archived'] as bool? ?? false,
        updatedAt: DateTime.tryParse(conv['updated_at'] as String? ?? '') ?? DateTime.now(),
      ));
    }

    return conversations;
  }

  Future<List<Participant>> _getOtherParticipants(String conversationId, String excludeUserId) async {
    final rows = await _client
        .from('conversation_participants')
        .select('user_id, profiles(full_name, handle, avatar_url)')
        .eq('conversation_id', conversationId)
        .neq('user_id', excludeUserId)
        .isFilter('left_at', null);

    return (rows as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      return Participant(
        userId: row['user_id'] as String,
        name: profile?['full_name'] as String? ?? 'User',
        handle: profile?['handle'] as String? ?? '@unknown',
        avatarUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<Message?> _getLastMessage(String conversationId) async {
    final row = await _client
        .from('messages')
        .select('id, body, sender_id, created_at, profiles:sender_id(full_name)')
        .eq('conversation_id', conversationId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    final sender = row['profiles'] as Map<String, dynamic>?;
    return Message(
      id: row['id'] as String,
      conversationId: conversationId,
      senderId: row['sender_id'] as String,
      senderName: sender?['full_name'] as String? ?? 'User',
      body: row['body'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Future<int> _getUnreadCount(String conversationId, String? lastReadAt) async {
    if (lastReadAt == null) {
      final result = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .isFilter('deleted_at', null);
      return (result as List).length;
    }

    final result = await _client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .gt('created_at', lastReadAt)
        .isFilter('deleted_at', null);
    return (result as List).length;
  }

  /// Get or create a direct conversation with another user.
  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    final result = await _client.rpc('get_or_create_direct_conversation', params: {
      'p_other_user_id': otherUserId,
    });
    return result as String;
  }

  // ============================================================================
  // Messages
  // ============================================================================

  /// Get messages for a conversation.
  Future<List<Message>> getMessages(String conversationId, {int limit = 50}) async {
    final rows = await _client
        .from('messages')
        .select('*, profiles:sender_id(full_name, handle, avatar_url)')
        .eq('conversation_id', conversationId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).map((row) => _messageFromRow(row, conversationId)).toList();
  }

  /// Watch messages in a conversation with realtime updates.
  Stream<List<Message>> watchMessages(String conversationId) {
    final controller = StreamController<List<Message>>();
    final messages = <Message>[];

    // Initial load
    getMessages(conversationId).then((msgs) {
      messages.addAll(msgs);
      controller.add(List.unmodifiable(messages));
    });

    // Subscribe to new messages
    final channel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newMessage = _messageFromRow(payload.newRecord, conversationId);
            messages.insert(0, newMessage);
            if (!controller.isClosed) {
              controller.add(List.unmodifiable(messages));
            }
          },
        )
        .subscribe();

    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  /// Send a message.
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? replyToId,
    List<String>? mediaUrls,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in');

    final result = await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'body': body,
      'reply_to_id': replyToId,
      'media_urls': mediaUrls ?? [],
    }).select().single();

    return _messageFromRow(result, conversationId);
  }

  /// Mark conversation as read.
  Future<void> markConversationAsRead(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  /// Get total unread message count across all conversations.
  Future<int> getTotalUnreadCount() async {
    final result = await _client.rpc('get_unread_message_count');
    return result as int? ?? 0;
  }

  Message _messageFromRow(Map<String, dynamic> row, String conversationId) {
    final sender = row['profiles'] as Map<String, dynamic>?;
    return Message(
      id: row['id'] as String,
      conversationId: conversationId,
      senderId: row['sender_id'] as String,
      senderName: sender?['full_name'] as String? ?? 'User',
      senderHandle: sender?['handle'] as String?,
      senderAvatarUrl: sender?['avatar_url'] as String?,
      body: row['body'] as String? ?? '',
      replyToId: row['reply_to_id'] as String?,
      mediaUrls: (row['media_urls'] as List?)?.cast<String>() ?? [],
      isEdited: row['is_edited'] as bool? ?? false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  void dispose() {
    // Cleanup handled by individual stream subscriptions
  }
}

// ============================================================================
// Models
// ============================================================================

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    required this.isMuted,
    required this.isArchived,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String name;
  final String? avatarUrl;
  final List<Participant> participants;
  final Message? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final DateTime updatedAt;
}

class Participant {
  const Participant({
    required this.userId,
    required this.name,
    required this.handle,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String handle;
  final String? avatarUrl;
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderHandle,
    this.senderAvatarUrl,
    required this.body,
    this.replyToId,
    this.mediaUrls = const [],
    this.isEdited = false,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderHandle;
  final String? senderAvatarUrl;
  final String body;
  final String? replyToId;
  final List<String> mediaUrls;
  final bool isEdited;
  final DateTime createdAt;
}
