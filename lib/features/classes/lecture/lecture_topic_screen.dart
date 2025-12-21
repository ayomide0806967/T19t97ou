import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/feed/post_repository.dart';
import '../../../core/user/handle.dart';
import '../../../models/class_topic.dart';
import '../../../widgets/lecture_note_card.dart';
import '../../messages/replies/message_replies_route.dart';
import 'class_note_stepper_screen.dart';
import 'create/create_note_welcome_screen.dart';

class LectureTopicScreen extends StatelessWidget {
  const LectureTopicScreen({super.key, required this.topic});

  final ClassTopic topic;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PostRepository>();
    final posts =
        data.posts.where((p) => p.tags.contains(topic.topicTag)).toList();

    final String currentUserHandle = deriveHandleFromEmail(
      context.read<AuthRepository>().currentUser?.email,
      fallback: '@yourprofile',
    );

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
                MaterialPageRoute(
                  builder: (_) => const ClassNoteStepperScreen(),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: posts.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showCreateLectureModal(context);
        },
        label: const Text('Start Lecture'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
