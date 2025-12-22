part of '../ios_messages_screen.dart';

mixin _CommentTileActions on _CommentTileStateBase {
  void _toggleRepostActions() {
    setState(() {
      final bool opening = !_showRepostActions;
      if (opening) {
        _CommentTileStateBase._openRepostTile?._closeRepostActions();
        _CommentTileStateBase._openRepostTile = this;
        _showRepostActions = true;
      } else {
        _showRepostActions = false;
        if (identical(_CommentTileStateBase._openRepostTile, this)) {
          _CommentTileStateBase._openRepostTile = null;
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
}
