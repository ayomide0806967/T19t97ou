part of '../ios_messages_screen.dart';

class _TopicFeedList extends StatefulWidget {
  const _TopicFeedList({required this.topic});
  final ClassTopic topic;
  @override
  State<_TopicFeedList> createState() => _TopicFeedListState();
}

class _TopicFeedListState extends State<_TopicFeedList> {
  static const int _pageSize = 10;
  int _visible = 0;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = context.watch<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(widget.topic.topicTag))
        .toList();
    final initial = posts.isEmpty
        ? 0
        : (posts.length < _pageSize ? posts.length : _pageSize);
    if (_visible == 0 && initial != 0) {
      _visible = initial;
    } else if (_visible > posts.length) {
      _visible = posts.length;
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final data = context.read<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(widget.topic.topicTag))
        .toList();
    final next = _visible + _pageSize;
    setState(() {
      _visible = next > posts.length ? posts.length : next;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(widget.topic.topicTag))
        .toList();
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }
    final slice = posts.take(_visible == 0 ? posts.length : _visible).toList();
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
            repostEnabled: !widget.topic.privateLecture,
            onRepost: widget.topic.privateLecture
                ? null
                : () async {
                    final String me = deriveHandleFromEmail(
                      SimpleAuthService().currentUserEmail,
                      maxLength: 999,
                    );
                    final toggled = await context
                        .read<DataService>()
                        .toggleRepost(postId: p.id, userHandle: me);
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
        if ((_visible == 0 && posts.length > _pageSize) ||
            (_visible > 0 && _visible < posts.length)) ...[
          Center(
            child: SizedBox(
              width: 200,
              height: 36,
              child: OutlinedButton(
                onPressed: _loading ? null : _loadMore,
                child: _loading
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

// Lightweight relative time formatter used by ActiveTopicCard
String _formatRelative(DateTime time) {
  final Duration diff = DateTime.now().difference(time);
  if (diff.inDays >= 1) {
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }
  if (diff.inHours >= 1) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (diff.inMinutes >= 1) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m mins ago';
  }
  return 'just now';
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

// --- Reusable step rails ---
class _StepRailVertical extends StatelessWidget {
  const _StepRailVertical({
    required this.steps,
    required this.activeIndex,
    this.titles,
    this.onStepTap,
  });

  final List<String> steps; // Dot labels (e.g., 1..4)
  final List<String>? titles; // Step titles shown to the right
  final int activeIndex;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasTitles = titles != null && titles!.length == steps.length;
    final Color connectorColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.25,
    );
    const double dotSize = 24;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: onStepTap == null ? null : () => onStepTap!(i),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StepDot(
                    active: i == activeIndex,
                    label: steps[i],
                    size: dotSize,
                  ),
                  if (hasTitles) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titles![i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: i == activeIndex
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: i == activeIndex
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (i < steps.length - 1)
            Row(
              children: [
                const SizedBox(width: dotSize / 2),
                Container(width: 1, height: 28, color: connectorColor),
                if (hasTitles) const SizedBox(width: 10),
                if (hasTitles) const Expanded(child: SizedBox()),
              ],
            ),
        ],
      ],
    );
  }
}

class _StepRailHorizontal extends StatelessWidget {
  const _StepRailHorizontal({
    required this.steps,
    required this.activeIndex,
    this.onStepTap,
  });

  final List<String> steps;
  final int activeIndex;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color connectorColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.25,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: onStepTap == null ? null : () => onStepTap!(i),
            borderRadius: BorderRadius.circular(12),
            child: _StepDot(
              active: i == activeIndex,
              label: steps[i],
              size: 24,
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: 28,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: connectorColor,
            ),
        ],
      ],
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

class _TopicDetailPage extends StatelessWidget {
  const _TopicDetailPage({required this.topic, required this.classCode});
  final ClassTopic topic;
  final String classCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(topic.topicTag))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(topic.topicTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '${topic.courseName} • Tutor ${topic.tutorName}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          for (final p in posts) ...[
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
            ),
            const SizedBox(height: 8),
          ],
          if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No notes found for this topic',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
