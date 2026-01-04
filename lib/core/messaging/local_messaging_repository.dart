import 'dart:async';

import 'messaging_repository.dart';

/// Local in-memory implementation of [MessagingRepository].
///
/// This is for offline/demo use and does not perform any network IO.
class LocalMessagingRepository implements MessagingRepository {
  final List<Conversation> _conversations = <Conversation>[];
  final Map<String, List<Message>> _messagesByConversationId =
      <String, List<Message>>{};
  final Map<String, StreamController<List<Message>>>
      _messageControllers = <String, StreamController<List<Message>>>{};

  @override
  Future<List<Conversation>> getConversations() async =>
      List<Conversation>.unmodifiable(_conversations);

  @override
  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    final existing = _conversations
        .firstWhere(
          (c) =>
              c.type == 'direct' &&
              c.participants.any((p) => p.userId == otherUserId),
          orElse: () => Conversation(
            id: '',
            type: 'direct',
            name: 'Direct chat',
            avatarUrl: null,
            participants: <Participant>[],
            lastMessage: null,
            unreadCount: 0,
            isMuted: false,
            isArchived: false,
            updatedAt: DateTime.now(),
          ),
        );
    if (existing.id.isNotEmpty) {
      return existing.id;
    }

    final id = 'local_conversation_${DateTime.now().microsecondsSinceEpoch}';
    final conversation = Conversation(
      id: id,
      type: 'direct',
      name: 'Chat with $otherUserId',
      avatarUrl: null,
      participants: <Participant>[
        Participant(
          userId: otherUserId,
          name: 'User',
          handle: '@user',
          avatarUrl: null,
        ),
      ],
      lastMessage: null,
      unreadCount: 0,
      isMuted: false,
      isArchived: false,
      updatedAt: DateTime.now(),
    );
    _conversations.add(conversation);
    return id;
  }

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final list =
        _messagesByConversationId[conversationId] ?? <Message>[];
    return List<Message>.unmodifiable(
      list.length > limit ? list.sublist(0, limit) : list,
    );
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    _messageControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<Message>>.broadcast(),
    );
    _emitMessages(conversationId);
    return _messageControllers[conversationId]!.stream;
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? replyToId,
    List<String>? mediaUrls,
  }) async {
    final now = DateTime.now();
    final message = Message(
      id: 'local_msg_${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'local_user',
      senderName: 'Local User',
      body: body,
      createdAt: now,
      replyToId: replyToId,
      mediaUrls: mediaUrls ?? <String>[],
    );
    final list = _messagesByConversationId.putIfAbsent(
      conversationId,
      () => <Message>[],
    );
    list.insert(0, message);
    _emitMessages(conversationId);
    return message;
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    // Local mode: unread counts are not tracked.
  }

  @override
  Future<int> getTotalUnreadCount() async {
    // Local mode: always zero.
    return 0;
  }

  void _emitMessages(String conversationId) {
    final controller = _messageControllers[conversationId];
    if (controller == null || controller.isClosed) return;
    controller.add(
      List<Message>.unmodifiable(
        _messagesByConversationId[conversationId] ?? <Message>[],
      ),
    );
  }

  void dispose() {
    for (final controller in _messageControllers.values) {
      controller.close();
    }
  }
}
