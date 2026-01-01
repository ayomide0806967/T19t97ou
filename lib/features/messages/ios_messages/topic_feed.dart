part of '../ios_messages_screen.dart';

class _TopicFeedList extends ConsumerWidget {
  const _TopicFeedList({required this.topic});
  final ClassTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(classTopicPostsControllerProvider(topic.topicTag));
    final posts = state.posts;
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleCount =
        state.visibleCount == 0 ? posts.length : state.visibleCount;
    final slice = posts.take(visibleCount).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.topicNotes,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final p in slice) ...[
          // Reuse the class message-style tile so the replies pill remains
          _ClassMessageTile(
            message: _ClassMessage(
              id: p.id,
              author: p.author,
              handle: p.handle,
              timeAgo: p.timeAgo,
              body: p.body,
              likes: p.likes,
              replies: p.replies,
              heartbreaks: 0,
            ),
            onShare: () async {},
            repostEnabled: !topic.privateLecture,
            onRepost: topic.privateLecture
                ? null
                : () async {
                    final String me =
                        ref.read(currentUserHandleProvider);
                    final toggled = await ref
                        .read(messageThreadControllerProvider.notifier)
                        .toggleRepost(
                          postId: p.id,
                          userHandle: me,
                        );
                    if (!context.mounted) return toggled;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          toggled
                              ? 'Reposted to your timeline'
                              : 'Repost removed',
                        ),
                      ),
                    );
                    return toggled;
                  },
          ),
          const SizedBox(height: 8),
        ],
        if (state.visibleCount < posts.length) ...[
          Center(
            child: SizedBox(
              width: 200,
              height: 36,
              child: OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => ref
                        .read(
                          classTopicPostsControllerProvider(topic.topicTag)
                              .notifier,
                        )
                        .loadMore(),
                child: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(S.loadMoreNotes),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClassSettings {
  const _ClassSettings({
    required this.adminOnlyPosting,
    required this.allowReplies,
    required this.allowMedia,
    required this.approvalRequired,
    required this.isPrivate,
    required this.autoArchiveOnEnd,
  });
  final bool adminOnlyPosting;
  final bool allowReplies;
  final bool allowMedia;
  final bool approvalRequired;
  final bool isPrivate;
  final bool autoArchiveOnEnd;
}

class _TopicSettings {
  const _TopicSettings({
    this.privateLecture = false,
    this.requirePin = false,
    this.pinCode,
    this.autoArchiveAt,
    this.attachQuizForNote = false,
  });
  final bool privateLecture;
  final bool requirePin;
  final String? pinCode;
  final DateTime? autoArchiveAt;
  final bool attachQuizForNote;
}

// Replaced by SettingSwitchRow in widgets/setting_switch_row.dart

class _PinGateCard extends StatefulWidget {
  const _PinGateCard({required this.onUnlock});
  final void Function(String code) onUnlock;
  @override
  State<_PinGateCard> createState() => _PinGateCardState();
}

class _PinGateCardState extends State<_PinGateCard> {
  final TextEditingController _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter PIN to view notes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () => widget.onUnlock(_code.text.trim()),
              child: const Text('Unlock'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRailMini extends StatelessWidget {
  const _StepRailMini({required this.activeIndex, required this.steps});
  final int activeIndex;
  final List<String> steps;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepDot(active: i == activeIndex, label: steps[i], size: 18),
          if (i < steps.length - 1)
            Container(
              width: 24,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.active,
    required this.label,
    this.size = 24,
    this.dimmed = false,
  });
  final bool active;
  final String label;
  final double size;
  final bool dimmed;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color border = dimmed ? Colors.black26 : theme.colorScheme.onSurface;
    final Color fill = active ? Colors.black : Colors.white;
    final Color text = active
        ? Colors.white
        : (dimmed ? Colors.black38 : Colors.black);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: size == 24 ? 12 : 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
