part of 'tagged_text_input.dart';

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
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MentionSuggestion> _getFilteredSuggestions() {
    if (widget.query.isEmpty) {
      return _allMentionSuggestions;
    }
    final lowerQuery = widget.query.toLowerCase();
    return _allMentionSuggestions.where((suggestion) {
      return suggestion.username.toLowerCase().contains(lowerQuery) ||
          suggestion.displayName.toLowerCase().contains(lowerQuery);
    }).toList();
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
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.9),
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                                  separatorBuilder: (context, _) => Padding(
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
                                      onTap: () => widget.onSelected(
                                        suggestion.username,
                                      ),
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
