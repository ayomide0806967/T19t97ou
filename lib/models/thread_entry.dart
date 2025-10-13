import '../services/data_service.dart';

class ThreadEntry {
  const ThreadEntry({
    required this.post,
    this.replyToHandle,
    this.replies = const <ThreadEntry>[],
  });

  final PostModel post;
  final String? replyToHandle;
  final List<ThreadEntry> replies;

  ThreadEntry copyWith({
    PostModel? post,
    String? replyToHandle,
    List<ThreadEntry>? replies,
  }) {
    return ThreadEntry(
      post: post ?? this.post,
      replyToHandle: replyToHandle ?? this.replyToHandle,
      replies: replies ?? this.replies,
    );
  }
}
