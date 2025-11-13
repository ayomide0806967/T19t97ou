import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../widgets/lecture_note_card.dart';
import 'ios_messages_screen.dart' show ClassTopic, messageRepliesRouteFromPost; // reuse route

class LectureTopicScreen extends StatelessWidget {
  const LectureTopicScreen({super.key, required this.topic});

  final ClassTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<DataService>();
    final posts = data.posts.where((p) => p.tags.contains(topic.topicTag)).toList();

    final String currentUserHandle = _currentUserHandle();

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.topicTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemBuilder: (context, index) {
          final post = posts[index];
          return LectureNoteCard(
            post: post,
            currentUserHandle: currentUserHandle,
            onReply: (_) {
              Navigator.of(context).push(
                messageRepliesRouteFromPost(post: post, currentUserHandle: currentUserHandle),
              );
            },
            onTap: () {
              Navigator.of(context).push(
                messageRepliesRouteFromPost(post: post, currentUserHandle: currentUserHandle),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: posts.length,
      ),
    );
  }

  static String _currentUserHandle() {
    final email = SimpleAuthService().currentUserEmail;
    if (email == null || email.isEmpty) return '@yourprofile';
    final normalized = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
    return normalized.isEmpty ? '@yourprofile' : '@$normalized';
  }
}

