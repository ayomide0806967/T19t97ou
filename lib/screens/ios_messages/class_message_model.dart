part of '../ios_messages_screen.dart';

class _ClassMessage {
  const _ClassMessage({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    this.likes = 0,
    this.replies = 0,
    this.heartbreaks = 0,
  });

  final String id;
  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final int likes;
  final int replies;
  final int heartbreaks;
}
