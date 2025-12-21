part of '../ios_messages_screen.dart';

class _Attachment {
  _Attachment({required this.bytes, this.name, this.mimeType});
  final Uint8List bytes;
  final String? name;
  final String? mimeType;
  bool get isImage {
    final mt = (mimeType ?? '').toLowerCase();
    return mt.startsWith('image/');
  }
}

/// Public helper to open the "Replies" UI (classes/messages style)
/// for a given timeline post. This keeps the private types local to this
/// file while exposing a simple route factory for other screens.
Route<void> messageRepliesRouteFromPost({
  required PostModel post,
  required String currentUserHandle,
}) {
  final _ClassMessage msg = _ClassMessage(
    id: post.id,
    author: post.author,
    handle: post.handle,
    timeAgo: post.timeAgo,
    body: post.body,
    likes: post.likes,
    replies: post.replies,
    heartbreaks: 0,
  );
  return MaterialPageRoute<void>(
    builder: (_) => _MessageCommentsPage(
      message: msg,
      currentUserHandle: currentUserHandle,
    ),
  );
}

