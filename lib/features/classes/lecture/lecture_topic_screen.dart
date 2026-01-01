import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/class_topic.dart';
import '../../../widgets/lecture_note_card.dart';
import '../../messages/replies/message_replies_route.dart';
import '../../auth/application/session_providers.dart';
import 'class_note_stepper_screen.dart';
import 'create/create_note_welcome_screen.dart';
import '../application/class_topic_posts_controller.dart';

class LectureTopicScreen extends ConsumerWidget {
  const LectureTopicScreen({super.key, required this.topic});

  final ClassTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState =
        ref.watch(classTopicPostsControllerProvider(topic.topicTag));
    final posts = postsState.posts;
    final String currentUserHandle = ref.watch(currentUserHandleProvider);

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
