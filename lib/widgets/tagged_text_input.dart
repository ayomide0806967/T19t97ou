import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaggedTextInput extends StatefulWidget {
  const TaggedTextInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.style,
    this.hintStyle,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLines;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextStyle? hintStyle;

  @override
  State<TaggedTextInput> createState() => _TaggedTextInputState();
}

class _TaggedTextInputState extends State<TaggedTextInput> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;
  String _currentMention = '';
  int _mentionStart = 0;
  int _mentionEnd = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _showSuggestions) {
      _showSuggestionsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: _MentionSuggestions(
            query: _currentMention,
            onSelected: _onSuggestionSelected,
            onClose: () {
              setState(() {
                _showSuggestions = false;
                _currentMention = '';
              });
              _removeOverlay();
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSuggestionSelected(String suggestion) {
    final text = widget.controller.text;
    final beforeMention = text.substring(0, _mentionStart);
    final afterMention = text.substring(_mentionEnd);

    widget.controller.text = '$beforeMention$suggestion $afterMention';
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: beforeMention.length + suggestion.length + 1),
    );

    setState(() {
      _showSuggestions = false;
      _currentMention = '';
    });
    _removeOverlay();

    widget.onChanged?.call(widget.controller.text);
  }

  void _handleTextChange(String text) {
    final cursorPosition = widget.controller.selection.baseOffset;
    if (cursorPosition < 0) return;

    // Check for @ mentions
    if (cursorPosition > 0 && text[cursorPosition - 1] == '@') {
      // Start of a new mention
      setState(() {
        _showSuggestions = true;
        _currentMention = '';
        _mentionStart = cursorPosition - 1;
        _mentionEnd = cursorPosition;
      });
      _showSuggestionsOverlay();
    } else if (_showSuggestions && cursorPosition > _mentionStart + 1) {
      // Continuing an existing mention
      final mentionText = text.substring(_mentionStart, cursorPosition);
      if (mentionText.contains(' ') || mentionText.contains('\n')) {
        // Mention ended
        setState(() {
          _showSuggestions = false;
          _currentMention = '';
        });
        _removeOverlay();
      } else {
        // Update suggestion query
        setState(() {
          _currentMention = mentionText.substring(1); // Remove @
          _mentionEnd = cursorPosition;
        });
        _showSuggestionsOverlay();
      }
    }

    widget.onChanged?.call(text);
  }

  List<TextSpan> _buildHighlightedSpans(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(@\w+|#\w+)');

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      // Add the highlighted match
      final matchedText = match.group(0)!;
      spans.add(
        TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(
            color: AppTheme.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppTheme.accent
                  : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Hidden text field for input
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                style: (widget.style ?? theme.textTheme.bodyLarge)?.copyWith(
                  color: Colors.transparent,
                  height: 1.4,
                ),
                onChanged: _handleTextChange,
                onTap: widget.onTap,
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: '',
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              // Rich text display
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    alignment: Alignment.centerLeft,
                    child: widget.controller.text.isEmpty
                        ? Text(
                            widget.hintText,
                            style:
                                widget.hintStyle ??
                                TextStyle(
                                  color: isDark
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 16,
                                ),
                          )
                        : RichText(
                            text: TextSpan(
                              children: _buildHighlightedSpans(
                                widget.controller.text,
                                (widget.style ?? theme.textTheme.bodyLarge)
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          height: 1.4,
                                        ) ??
                                    const TextStyle(
                                      color: Color(0xFF1E293B),
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showSuggestions && _focusNode.hasFocus)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSuggestions = false;
                  _currentMention = '';
                });
                _removeOverlay();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }
}

class _MentionSuggestions extends StatefulWidget {
  const _MentionSuggestions({
    required this.query,
    required this.onSelected,
    required this.onClose,
  });

  final String query;
  final Function(String) onSelected;
  final VoidCallback onClose;

  @override
  State<_MentionSuggestions> createState() => _MentionSuggestionsState();
}

class _MentionSuggestionsState extends State<_MentionSuggestions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MentionSuggestion> _getFilteredSuggestions() {
    final allSuggestions = _allMentionSuggestions;
    if (widget.query.isEmpty) {
      return allSuggestions.take(8).toList();
    }
    return allSuggestions
        .where(
          (s) => s.username.toLowerCase().contains(widget.query.toLowerCase()),
        )
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestions = _getFilteredSuggestions();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 16),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: suggestions.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    'No suggestions found',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: suggestions.length,
                                separatorBuilder: (_, __) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Divider(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    height: 1,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final suggestion = suggestions[index];
                                  return _SuggestionTile(
                                    suggestion: suggestion,
                                    onTap: () =>
                                        widget.onSelected(suggestion.username),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final MentionSuggestion suggestion;
  final VoidCallback onTap;

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.suggestion.colors,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: widget.suggestion.colors.first.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(child: widget.suggestion.avatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.suggestion.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.suggestion.username,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.suggestion.isVerified)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MentionSuggestion {
  const MentionSuggestion({
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.colors,
    this.isVerified = false,
  });

  final String username;
  final String displayName;
  final Widget avatar;
  final List<Color> colors;
  final bool isVerified;
}

const List<MentionSuggestion> _allMentionSuggestions = [
  MentionSuggestion(
    username: '@dean_creative',
    displayName: 'Dr. Maya Chen',
    avatar: Icon(Icons.school_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    isVerified: true,
  ),
  MentionSuggestion(
    username: '@life_at_in',
    displayName: 'Student Affairs',
    avatar: Icon(Icons.groups_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
  ),
  MentionSuggestion(
    username: '@insights',
    displayName: 'Research Collective',
    avatar: Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  ),
  MentionSuggestion(
    username: '@designlab',
    displayName: 'Design Lab',
    avatar: Icon(Icons.palette_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
  ),
  MentionSuggestion(
    username: '@techclub',
    displayName: 'Tech Club',
    avatar: Icon(Icons.code_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
  ),
  MentionSuggestion(
    username: '@library',
    displayName: 'Campus Library',
    avatar: Icon(Icons.local_library_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFF30CFD0), Color(0xFF330867)],
  ),
  MentionSuggestion(
    username: '@sports',
    displayName: 'Athletics',
    avatar: Icon(
      Icons.sports_basketball_rounded,
      color: Colors.white,
      size: 20,
    ),
    colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
  ),
  MentionSuggestion(
    username: '@career',
    displayName: 'Career Services',
    avatar: Icon(Icons.work_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFFFD297B), Color(0xFFFF5864)],
  ),
  MentionSuggestion(
    username: '@health',
    displayName: 'Health Center',
    avatar: Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFF6DD5ED), Color(0xFF2193B0)],
  ),
  MentionSuggestion(
    username: '@sustainability',
    displayName: 'Green Campus',
    avatar: Icon(Icons.eco_rounded, color: Colors.white, size: 20),
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  ),
];
