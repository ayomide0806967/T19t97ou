import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/post.dart';
import '../../../models/thread_entry.dart';

/// Controller responsible for encapsulating the business rules of creating
/// and appending a reply to a thread. For now this operates on in-memory
/// [ThreadEntry] trees; later it can be extended to persist via repositories.
class ThreadReplyController extends Notifier<void> {
  @override
  void build() {}

  ThreadEntry addLocalReply({
    required ThreadEntry root,
    required String targetPostId,
    required String currentUserHandle,
    required String body,
  }) {
    final String handle = _normalizeHandle(currentUserHandle);
    final ThreadEntry newReply = ThreadEntry(
      post: PostModel(
        id: '${targetPostId}_local_${DateTime.now().microsecondsSinceEpoch}',
        author: 'You',
        handle: handle,
        timeAgo: 'just now',
        body: body,
        tags: const <String>[],
        replies: 0,
        reposts: 0,
        likes: 0,
        views: 0,
        bookmarks: 0,
      ),
      replyToHandle: null,
    );
    return _appendReply(root, targetPostId, newReply);
  }

  String _normalizeHandle(String handle) {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) return '@you';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  ThreadEntry _appendReply(
    ThreadEntry node,
    String targetId,
    ThreadEntry reply,
  ) {
    if (node.post.id == targetId) {
      final List<ThreadEntry> updatedReplies =
          List<ThreadEntry>.from(node.replies)..add(reply);
      return node.copyWith(
        post: node.post.copyWith(replies: node.post.replies + 1),
        replies: updatedReplies,
      );
    }

    bool modified = false;
    final List<ThreadEntry> children = <ThreadEntry>[];
    for (final ThreadEntry child in node.replies) {
      final ThreadEntry updatedChild = _appendReply(child, targetId, reply);
      if (!identical(child, updatedChild)) {
        modified = true;
      }
      children.add(updatedChild);
    }

    if (!modified) return node;

    return node.copyWith(replies: children);
  }
}

final threadReplyControllerProvider =
    NotifierProvider<ThreadReplyController, void>(
  ThreadReplyController.new,
);

