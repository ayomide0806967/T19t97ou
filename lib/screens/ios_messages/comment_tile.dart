part of '../ios_messages_screen.dart';

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.currentUserHandle,
    this.onSwipeReply,
    this.selected = false,
    this.onLongPress,
    this.onTap,
  });
  final _ThreadComment comment;
  final bool isDark;
  final String currentUserHandle;
  final VoidCallback? onSwipeReply;
  final bool selected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  // Track which comment currently shows inline repost actions so only one is open.
  static _CommentTileState? _openRepostTile;

  bool _highlight = false;
  double _dx = 0;
  double _dragOffset = 0; // visual slide during swipe-to-reply
  int _likes = 0;
  bool _liked = false;
  bool _reposted = false;
  int _reposts = 0;
  bool _swipeHapticFired = false;
  bool _showRepostActions = false;
  final Map<String, int> _reactions = <String, int>{};
  String? _currentUserReaction;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
    _seedMockReactions();
  }

  @override
  void dispose() {
    if (identical(_openRepostTile, this)) {
      _openRepostTile = null;
    }
    super.dispose();
  }

  void _closeRepostActions() {
    if (!_showRepostActions) return;
    setState(() {
      _showRepostActions = false;
    });
  }

  void _toggleRepostActions() {
    setState(() {
      final bool opening = !_showRepostActions;
      if (opening) {
        _openRepostTile?._closeRepostActions();
        _openRepostTile = this;
        _showRepostActions = true;
      } else {
        _showRepostActions = false;
        if (identical(_openRepostTile, this)) {
          _openRepostTile = null;
        }
      }
    });
  }

  void _showReactionDetails(String emoji) {
    final theme = Theme.of(context);
    final int count = _reactions[emoji] ?? 0;
    if (count <= 0) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: false,
      builder: (BuildContext ctx) {
        final String title = '$count reaction${count == 1 ? '' : 's'}';
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Emoji filters row – show all reaction emojis with counts.
                Builder(
                  builder: (_) {
                    final List<MapEntry<String, int>> sorted =
                        _reactions.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < sorted.length; i++) ...[
                            _EmojiReactionChip(
                              emoji: sorted[i].key,
                              count: sorted[i].value,
                              isActive: sorted[i].key == emoji,
                            ),
                            if (i != sorted.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    itemCount: count,
                    itemBuilder: (BuildContext _, int index) {
                      final bool isYou =
                          index == 0 && _currentUserReaction == emoji;
                      final String name = isYou
                          ? 'You'
                          : '${widget.comment.author} #${index + 1}';
                      final String subtitle = isYou
                          ? widget.currentUserHandle
                          : widget.currentUserHandle;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isYou
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        trailing: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _seedMockReactions() {
    if (_reactions.isNotEmpty) return;
    final List<String> pool = <String>['👍', '❤️', '😂', '😮', '😢', '👏'];
    final int base = widget.comment.body.hashCode.abs();
    // Between 0 and 3 mock reactions.
    final int reactionCount = (base % 4); // 0–3
    for (int i = 0; i < reactionCount; i++) {
      final String emoji = pool[(base + i * 5) % pool.length];
      final int value = 1 + ((base >> (i * 3)) & 0x3); // 1–4
      _reactions[emoji] = value;
    }
  }

  Future<void> _openReactionPicker() async {
    const List<String> emojis = <String>[
      '👍',
      '❤️',
      '😂',
      '😮',
      '😢',
      '👏',
      '🔥',
      '🎉',
      '🙏',
      '😍',
    ];
    final theme = Theme.of(context);
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset origin = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    String? choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final double top = (origin.dy - 72).clamp(16.0, double.infinity);
        final double centerX = origin.dx + size.width / 2;
        return Stack(
          children: [
            Positioned(
              top: top,
              left: centerX - 160,
              right: centerX - 160,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrollable emoji strip
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final String emoji in emojis)
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.of(dialogContext).pop(emoji),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        emoji,
                                        style: TextStyle(
                                          fontSize: 26,
                                          color: emoji == '❤️'
                                              ? Colors.red
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.95),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Plus button (always visible)
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(dialogContext).pop('__more__'),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.0,
                                  ),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (choice == '__more__') {
      choice = await _openFullEmojiSheet();
    }
    if (choice == null) return;
    final String selected = choice;
    setState(() {
      // Enforce a single active reaction per user.
      if (_currentUserReaction == selected) {
        // Tapping the same reaction again clears it.
        final int existing = _reactions[selected] ?? 0;
        if (existing > 0) {
          final int next = existing - 1;
          if (next > 0) {
            _reactions[selected] = next;
          } else {
            _reactions.remove(selected);
          }
        }
        _currentUserReaction = null;
      } else {
        // Remove previous reaction, if any.
        final String? previous = _currentUserReaction;
        if (previous != null) {
          final int current = _reactions[previous] ?? 0;
          if (current > 0) {
            final int next = current - 1;
            if (next > 0) {
              _reactions[previous] = next;
            } else {
              _reactions.remove(previous);
            }
          }
        }
        // Apply new reaction.
        _reactions[selected] = (_reactions[selected] ?? 0) + 1;
        _currentUserReaction = selected;
      }
    });
  }

  Future<String?> _openFullEmojiSheet() async {
    final theme = Theme.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: EmojiPicker(
              onEmojiSelected: (Category? category, Emoji emoji) {
                Navigator.of(ctx).pop(emoji.emoji);
              },
              config: Config(
                height: 320,
                // Avoid platform channel call for getSupportedEmojis on
                // platforms where the plugin is not registered.
                checkPlatformCompatibility: false,
                // Order: search bar on top, emoji grid in middle,
                // category bar at the very bottom like WhatsApp.
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.searchBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.categoryBar,
                ),
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 30,
                  backgroundColor: theme.colorScheme.surface,
                  verticalSpacing: 8,
                  horizontalSpacing: 8,
                  gridPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  buttonMode: ButtonMode.CUPERTINO,
                ),
                // Start on RECENT so frequently used emojis are shown first,
                // then users can scroll through other categories.
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.SMILEYS,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                  backgroundColor: theme.colorScheme.surface,
                  iconColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.45,
                  ),
                  iconColorSelected: theme.colorScheme.primary,
                  indicatorColor: theme.colorScheme.primary,
                  backspaceColor: theme.colorScheme.primary,
                  dividerColor: theme.dividerColor.withValues(alpha: 0.2),
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: false,
                  backgroundColor: theme.colorScheme.surface,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.98,
                  ),
                  buttonIconColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  hintText: 'Search emoji',
                  hintTextStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  inputTextStyle: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _ThreadComment comment = widget.comment;
    final bool isMine =
        comment.author == widget.currentUserHandle || comment.author == 'You';
    // Light: subtle card variants. Dark: glassy card with semi-transparent white.
    final Color lightMine = const Color(0xFFF8FAFC);
    final Color lightOther = Colors.white;
    final Color baseLight = isMine
        ? lightMine
        : lightOther; // used only in light mode
    final Color bubble = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : baseLight;

    // Meta text color uses default onSurface alpha in light theme
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isDark = widget.isDark;
    // Soft material-style card shadow for each reply (matches app card style).
    final List<BoxShadow> popShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
        offset: const Offset(0, 6),
        blurRadius: 18,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
    const double bubbleRadius = 18;
    const double avatarSize = 48;

    final Color selectedHover = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);
    // When a reply has been reposted, highlight its card border in green.
    final Color borderColor = _reposted
        ? const Color(0xFF00BA7C)
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE5E7EB));
    // Avatar used inside the card for other users.
    final String displayAuthor = comment.author
        .replaceFirst(RegExp(r'^\s*@'), '')
        .trim();
    final String initial = displayAuthor.isNotEmpty
        ? displayAuthor.substring(0, 1).toUpperCase()
        : 'U';
    final Widget avatarWidget = isMine
        ? const SizedBox.shrink()
        : Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Text(
                initial,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
    // Padding inside the reply card.
    final EdgeInsets bubblePadding = const EdgeInsets.fromLTRB(12, 8, 12, 8);

    final Widget bubbleCore = Container(
      padding: bubblePadding,
      decoration: BoxDecoration(
        color: widget.selected ? selectedHover : bubble,
        borderRadius: BorderRadius.circular(bubbleRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: popShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMine) avatarWidget,
          if (!isMine) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.author.replaceFirst(RegExp(r'^\s*@'), ''),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        comment.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(color: meta),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                if (comment.quotedBody != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : theme.colorScheme.surfaceVariant.withValues(
                              alpha: 0.9,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(
                          alpha: widget.isDark ? 0.4 : 0.3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (comment.quotedFrom ?? 'Reply').replaceFirst(
                                  RegExp(r'^\s*@'),
                                  '',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.quotedBody!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: widget.isDark ? 0.9 : 0.85,
                                  ),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  comment.body,
                  style: AppTheme.tweetBody(
                    widget.isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                  ),
                ),
                if (_reposted && !_showRepostActions) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const XRetweetIcon(size: 14, color: Color(0xFF00BA7C)),
                        const SizedBox(width: 4),
                        Text(
                          'Reposted',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00BA7C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_showRepostActions) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: widget.isDark ? 0.25 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _reposted = !_reposted;
                                _reposts += _reposted ? 1 : -1;
                                if (_reposts < 0) _reposts = 0;
                                _showRepostActions = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  XRetweetIcon(
                                    size: 16,
                                    color: _reposted
                                        ? const Color(0xFF00BA7C)
                                        : meta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _reposted ? 'Unrepost' : 'Repost',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: _reposted ? Colors.green : meta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: widget.isDark ? 0.35 : 0.25,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setState(() {
                                _showRepostActions = false;
                              });
                              widget.onSwipeReply?.call();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.reply_rounded, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reply',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: meta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Pop effect on selection
    final Widget poppedCard = AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      scale: widget.selected ? 1.06 : 1.02,
      child: bubbleCore,
    );

    // Swipe progress (0..1) for extra effects
    final double swipeT = (_dragOffset / 80.0).clamp(0.0, 1.0);
    final Widget swipeBackground = IgnorePointer(
      child: Opacity(
        opacity: swipeT,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(
                alpha: widget.isDark ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.reply_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _highlight = true),
      onTapUp: (_) => setState(() => _highlight = false),
      onTapCancel: () => setState(() => _highlight = false),
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _toggleRepostActions();
        }
      },
      onDoubleTap: _openReactionPicker,
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: (details) {
        _dx += details.delta.dx;
        // visual slide to the right only
        final double next = (_dragOffset + details.delta.dx).clamp(0, 56);
        setState(() {
          _dragOffset = next;
          _highlight = true;
        });
        if (!_swipeHapticFired && _dragOffset > 42) {
          HapticFeedback.mediumImpact();
          _swipeHapticFired = true;
        }
        if (_dx > 42) {
          _dx = 0;
          widget.onSwipeReply?.call();
        }
      },
      onHorizontalDragEnd: (details) {
        final bool trigger =
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 250) ||
            _dragOffset >= 42;
        if (trigger) {
          widget.onSwipeReply?.call();
        }
        setState(() {
          _highlight = false;
          _dragOffset = 0; // animate back to rest
        });
        _swipeHapticFired = false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Reply bubble + swipe background
            Padding(
              padding: EdgeInsets.only(
                left: 0,
                bottom: _reactions.isNotEmpty ? 14 : 0,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned.fill(child: swipeBackground),
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Transform.rotate(
                      angle: -0.03 * swipeT,
                      child: Transform.scale(
                        scale: 1.0 + (0.02 * swipeT),
                        child: poppedCard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_reactions.isNotEmpty)
              Positioned(
                left: isMine ? 12 : avatarSize / 2 + 12,
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Builder(
                    builder: (_) {
                      final List<MapEntry<String, int>> sorted =
                          _reactions.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                      const int maxVisible = 4;
                      final int visibleCount = sorted.length > maxVisible
                          ? maxVisible
                          : sorted.length;

                      int totalCount = 0;
                      for (final entry in sorted) {
                        totalCount += entry.value;
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < visibleCount; i++) ...[
                            _EmojiReactionChip(
                              emoji: sorted[i].key,
                              count: sorted[i].value,
                              isActive: sorted[i].key == _currentUserReaction,
                              onTap: () => _showReactionDetails(sorted[i].key),
                            ),
                            if (i != visibleCount - 1) const SizedBox(width: 8),
                          ],
                          if (totalCount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '$totalCount',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
