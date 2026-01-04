import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../features/auth/application/session_providers.dart';
import '../models/post.dart';
import '../widgets/tweet_post_card.dart';
import '../features/messages/replies/message_replies_route.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(postRepositoryProvider);
    final currentUserHandle = ref.watch(currentUserHandleProvider);
    final theme = Theme.of(context);

    return StreamBuilder<List<PostModel>>(
      stream: repository.watchTimeline(),
      initialData: repository.posts,
      builder: (context, snapshot) {
        final bookmarked = repository.bookmarkedPosts();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bookmarks'),
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          body: bookmarked.isEmpty
              ? const Center(child: Text('No saved posts yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: bookmarked.length,
                  itemBuilder: (context, index) {
                    final post = bookmarked[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TweetPostCard(
                        key: ValueKey<String>('bookmark_${post.id}'),
                        post: post,
                        currentUserHandle: currentUserHandle,
                        showRepostBanner: true,
                        onReply: (_) {
                          Navigator.of(context).push(
                            messageRepliesRouteFromPost(
                              post: post,
                              currentUserHandle: currentUserHandle,
                            ),
                          );
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            messageRepliesRouteFromPost(
                              post: post,
                              currentUserHandle: currentUserHandle,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
