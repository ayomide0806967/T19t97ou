part of '../ios_messages_screen.dart';

class _ClassMessageTile extends StatefulWidget {
  const _ClassMessageTile({
    required this.message,
    required this.onShare,
    this.showReplyButton = true,
    this.onRepost, // when provided, triggers a real repost action
    this.repostEnabled = true,
  });

  final _ClassMessage message;
  final Future<void> Function() onShare;
  final Future<bool> Function()? onRepost; // returns new repost state (active?)
  final bool repostEnabled;
  final bool showReplyButton;

  @override
  State<_ClassMessageTile> createState() => _ClassMessageTileState();
}

class _ClassMessageTileState extends State<_ClassMessageTile> {
  bool _saved = false;
  int _good = 0;
  int _bad = 0;
  int _reposts = 0;
  bool _goodActive = false;
  bool _badActive = false;

  String _formatDisplayName(String author, String handle) {
    String base = (author.trim().isNotEmpty ? author : handle).trim();
    // Strip leading @ if present
    base = base.replaceFirst(RegExp(r'^\s*@'), '');
    // Replace underscores/hyphens with spaces
    base = base.replaceAll(RegExp(r'[_-]+'), ' ');
    // Insert spaces in camelCase or PascalCase (e.g., StudyCouncil -> Study Council)
    base = base.replaceAllMapped(
      RegExp(r'(?<=[a-z])([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    // Title-case words
    final parts = base.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final titled = parts
        .map(
          (w) => w.substring(0, 1).toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
    return titled.isEmpty ? base : titled;
  }

  @override
  void initState() {
    super.initState();
    _good = widget.message.likes;
    _bad = widget.message.heartbreaks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color nameColor = theme.colorScheme.onSurface;
    final Color meta = nameColor.withValues(alpha: 0.6);

    final message = widget.message;

    String avatarText() {
      final base = message.author.isNotEmpty ? message.author : message.handle;
      final t = base.trim();
      if (t.isEmpty) return '?';
      final first = t.substring(0, 1);
      return first.toUpperCase();
    }

    // Card container for note – reuse the same cut-in avatar + rounded border
    // treatment as the Replies cards.
    final Color cardBackground = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFFAFAFA);
    final Color borderColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.30 : 0.14,
    );

    /*return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 24, bottom: 16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: _formatDisplayName(message.author, message.handle),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: nameColor,
                          ),
                          children: [
                            TextSpan(
                              text: ' • ${message.timeAgo}',
                              style: theme.textTheme.bodySmall?.copyWith(color: meta),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      color: meta,
                      onPressed: () {},
                      tooltip: 'More',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
          const SizedBox(height: 6),
          // Body now uses full width (no left indent under avatar)
          LayoutBuilder(builder: (context, constraints) {
            // Determine if text exceeds 22 lines (truncate threshold)
            final textStyle = theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.0,
            );
            final span = TextSpan(text: message.body, style: textStyle);
            final tp = TextPainter(
              text: span,
              maxLines: null,
              textDirection: Directionality.of(context),
            );
            tp.layout(maxWidth: constraints.maxWidth);
            final int totalLines = tp.computeLineMetrics().length;
            final bool longLines = totalLines > 22; // Collapse if more than 22 lines

            if (!_expanded && longLines) {
              final linkStyle = theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              );
              int low = 0, high = message.body.length, best = 0;
              while (low <= high) {
                final mid = (low + high) >> 1;
                final prefix = '${message.body.substring(0, mid).trimRight()} ';
                final spanTry = TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: prefix),
                    TextSpan(text: 'Read more', style: linkStyle),
                  ],
                );
                final tpTry = TextPainter(
                  text: spanTry,
                  maxLines: 22,
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);
                if (!tpTry.didExceedMaxLines) {
                  best = mid;
                  low = mid + 1;
                } else {
                  high = mid - 1;
                }
              }
              final visible = message.body.substring(0, best).trimRight();
              // Reserve extra room by removing the last 3 words so the link
              // reliably sits on the same final line and not below.
              String visibleTrimmed = visible;
              final words = visibleTrimmed.split(RegExp(r"\s+"));
              if (words.length > 3) {
                visibleTrimmed = words.sublist(0, words.length - 3).join(' ');
              }
              return Text.rich(
                TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: '$visibleTrimmed '),
                    TextSpan(
                      text: 'Read more',
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => setState(() => _expanded = true),
                    ),
                  ],
                ),
                maxLines: 22,
                overflow: TextOverflow.clip,
              );
            }

            return Text(message.body, style: textStyle);
          }),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Always show the View replies pill when enabled, even at 0
              if (widget.showReplyButton)
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _openComments(context, message),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            // Use neutral grey instead of accent/primary
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'View ${message.replies} ${message.replies == 1 ? 'reply' : 'replies'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              // Keep neutral text to match grey outline
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 8),
              // Three equal columns: Like, Repost, Heartbreak
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _LabelCountButton(
                          icon: _goodActive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconSize: 20,
                          count: _good,
                          color: _goodActive ? Colors.red : null,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_goodActive) {
                                _good = (_good - 1).clamp(0, 1 << 30);
                                _goodActive = false;
                              } else {
                                _good += 1;
                                _goodActive = true;
                                if (_badActive) {
                                  _bad = (_bad - 1).clamp(0, 1 << 30);
                                  _badActive = false;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: widget.repostEnabled
                            ? _ScaleTap(
                                onTap: () async {
                                  if (widget.onRepost != null) {
                                    final bool next = await widget.onRepost!.call();
                                    setState(() {
                                      if (_saved != next) {
                                        _reposts += next ? 1 : -1;
                                        if (_reposts < 0) _reposts = 0;
                                      }
                                      _saved = next;
                                    });
                                  } else {
                                    setState(() {
                                      _saved = !_saved;
                                      _reposts += _saved ? 1 : -1;
                                      if (_reposts < 0) _reposts = 0;
                                    });
                                  }
                                },
                                child: LayoutBuilder(
                                  builder: (context, c) {
                                    final maxW = c.maxWidth;
                                    final bool tight = maxW.isFinite && maxW < 60;
                                    final bool ultra = maxW.isFinite && maxW < 38;
                                    final String label = ultra ? 'R' : (tight ? 'Rep' : 'Repost');
                                    final double gap = ultra ? 2 : (tight ? 4 : 6);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _saved ? Colors.green : meta,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: gap),
                                        Text(
                                          '$_reposts',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: _saved ? Colors.green : meta,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : LayoutBuilder(
                            builder: (context, c) {
                              final maxW = c.maxWidth;
                              final bool tight = maxW.isFinite && maxW < 60;
                              final bool ultra = maxW.isFinite && maxW < 38;
                              final String label = ultra ? 'R' : (tight ? 'Rep' : 'Repost');
                              final double gap = ultra ? 2 : (tight ? 4 : 6);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: meta,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Text(
                                    '$_reposts',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: meta,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _LabelCountButton(
                          icon: _badActive ? Icons.heart_broken_rounded : Icons.heart_broken_outlined,
                          iconSize: 18,
                          count: _bad,
                          color: _badActive ? Colors.black : null,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_badActive) {
                                _bad = (_bad - 1).clamp(0, 1 << 30);
                                _badActive = false;
                              } else {
                                _bad += 1;
                                _badActive = true;
                                if (_goodActive) {
                                  _good = (_good - 1).clamp(0, 1 << 30);
                                  _goodActive = false;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Picture-frame avatar overlapping the left edge of the card.
        Positioned(
          left: 0,
          top: 16,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );*/

    final Widget card = Container(
      margin: const EdgeInsets.only(left: 24, bottom: 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: _formatDisplayName(message.author, message.handle),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                      ),
                      children: [
                        TextSpan(
                          text: ' • ${message.timeAgo}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: meta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: meta,
                  onPressed: () {},
                  tooltip: 'More',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showReplyButton)
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _openComments(context, message),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Text(
                              'View ${message.replies} ${message.replies == 1 ? 'reply' : 'replies'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _LabelCountButton(
                            icon: _goodActive
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            iconSize: 20,
                            count: _good,
                            color: _goodActive ? Colors.red : null,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_goodActive) {
                                  _good = (_good - 1).clamp(0, 1 << 30);
                                  _goodActive = false;
                                } else {
                                  _good += 1;
                                  _goodActive = true;
                                  if (_badActive) {
                                    _bad = (_bad - 1).clamp(0, 1 << 30);
                                    _badActive = false;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: widget.repostEnabled
                              ? _ScaleTap(
                                  onTap: () async {
                                    if (widget.onRepost != null) {
                                      final bool next = await widget.onRepost!
                                          .call();
                                      setState(() {
                                        if (_saved != next) {
                                          _reposts += next ? 1 : -1;
                                          if (_reposts < 0) _reposts = 0;
                                        }
                                        _saved = next;
                                      });
                                    } else {
                                      setState(() {
                                        _saved = !_saved;
                                        _reposts += _saved ? 1 : -1;
                                        if (_reposts < 0) _reposts = 0;
                                      });
                                    }
                                  },
                                  child: LayoutBuilder(
                                    builder: (context, c) {
                                      final maxW = c.maxWidth;
                                      final bool tight =
                                          maxW.isFinite && maxW < 60;
                                      final bool ultra =
                                          maxW.isFinite && maxW < 38;
                                      final String label = ultra
                                          ? 'R'
                                          : (tight ? 'Rep' : 'Repost');
                                      final double gap = ultra
                                          ? 2
                                          : (tight ? 4 : 6);
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            label,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: _saved
                                                      ? Colors.green
                                                      : meta,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          SizedBox(width: gap),
                                          Text(
                                            '$_reposts',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color: _saved
                                                      ? Colors.green
                                                      : meta,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, c) {
                                    final maxW = c.maxWidth;
                                    final bool tight =
                                        maxW.isFinite && maxW < 60;
                                    final bool ultra =
                                        maxW.isFinite && maxW < 38;
                                    final String label = ultra
                                        ? 'R'
                                        : (tight ? 'Rep' : 'Repost');
                                    final double gap = ultra
                                        ? 2
                                        : (tight ? 4 : 6);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: meta,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        SizedBox(width: gap),
                                        Text(
                                          '$_reposts',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: meta,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _LabelCountButton(
                            icon: _badActive
                                ? Icons.heart_broken_rounded
                                : Icons.heart_broken_outlined,
                            iconSize: 18,
                            count: _bad,
                            color: _badActive ? Colors.black : null,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_badActive) {
                                  _bad = (_bad - 1).clamp(0, 1 << 30);
                                  _badActive = false;
                                } else {
                                  _bad += 1;
                                  _badActive = true;
                                  if (_goodActive) {
                                    _good = (_good - 1).clamp(0, 1 << 30);
                                    _goodActive = false;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Picture-frame avatar overlapping the left edge of the card.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: 0,
          top: 16,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openComments(BuildContext context, _ClassMessage message) {
    final String me = deriveHandleFromEmail(
      context.read<AuthRepository>().currentUser?.email,
      maxLength: 999,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _MessageCommentsPage(message: message, currentUserHandle: me),
      ),
    );
  }
}
