part of 'home_screen.dart';

class _QuickControlPanel extends StatefulWidget {
  const _QuickControlPanel({
    required this.theme,
    required this.appSettings,
    required this.userCard,
    required this.onNavigateHome,
    required this.onCompose,
  });

  final ThemeData theme;
  final AppSettings appSettings;
  final Widget userCard;
  final VoidCallback onNavigateHome;
  final VoidCallback onCompose;

  @override
  State<_QuickControlPanel> createState() => _QuickControlPanelState();
}

class _QuickControlPanelState extends State<_QuickControlPanel> {
  late final List<QuickControlItem> _items;
  late final List<bool> _activeStates;

  @override
  void initState() {
    super.initState();
    _items = [
      QuickControlItem(
        icon: Icons.school_rounded,
        label: 'Class',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      QuickControlItem(
        icon: Icons.mode_edit_outline_rounded,
        label: 'Post',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onCompose();
        },
      ),
      QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Quiz',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.quizDashboard());
        },
      ),
      QuickControlItem(
        icon: Icons.dark_mode_rounded,
        label: 'Dark Theme',
        onPressed: () async {
          final next = !widget.appSettings.isDarkMode;
          await widget.appSettings.toggleDarkMode(next);
          setState(() {
            _activeStates[3] = next;
          });
        },
      ),
      QuickControlItem(
        icon: Icons.notifications_none_outlined,
        label: 'Notifications',
        onPressed: () async => showComingSoonSnackBar(context, 'Notifications'),
      ),
      QuickControlItem(
        icon: Icons.forum_outlined,
        label: 'Messages',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      QuickControlItem(
        icon: Icons.search_rounded,
        label: 'Search',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.trending());
        },
      ),
      QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Settings',
        onPressed: () async => showComingSoonSnackBar(context, 'Settings'),
      ),
      QuickControlItem(
        icon: Icons.logout_outlined,
        label: 'Log out',
        onPressed: () async {
          Navigator.of(context).pop();
          await context.read<AuthRepository>().signOut();
        },
      ),
    ];

    _activeStates = _items.map((item) => item.initialValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final bool isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(0, value * 60), child: child);
      },
      child: Stack(
        children: [
          // Tap-through scrim: tapping anywhere above the panel closes it.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.16),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickControlGrid(),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'IN INSTITUTION',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleItemInteraction(int index) async {
    final item = _items[index];
    await item.onPressed?.call();
  }

  Widget _buildQuickControlGrid() {
    return QuickControlGrid(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return _QuickControlButton(
          item: _items[index],
          isActive: _activeStates[index],
          onPressed: () => _handleItemInteraction(index),
        );
      },
    );
  }
}

class _QuickControlButton extends StatelessWidget {
  const _QuickControlButton({
    required this.item,
    required this.isActive,
    required this.onPressed,
  });

  final QuickControlItem item;
  final bool isActive;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final bool isLogoutTile = item.label == 'Log out';

    final Color baseBorder = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.35,
    );
    final Color activeBorder = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.38 : 0.45,
    );
    final Color baseBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final Color activeBackground = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    final Color tileBorder = isLogoutTile
        ? const Color(0xFFF56565)
        : (isActive ? activeBorder : baseBorder);
    final Color tileBackground = isLogoutTile
        ? const Color(0xFFF56565)
        : (isActive ? activeBackground : baseBackground);

    final decoration = BoxDecoration(
      color: tileBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: tileBorder, width: 1),
    );

    final bool isThemeTile = item.label == 'Dark Theme';
    final String displayLabel = isThemeTile
        ? (isDark ? 'White mode' : 'Dark mode')
        : item.label;
    final IconData displayIcon = isThemeTile
        ? (isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)
        : item.icon;

    final Color labelColor = isLogoutTile
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.82);

    final TextStyle labelStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: labelColor,
        ) ??
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: labelColor);

    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          displayIcon,
          size: 20,
          color: isLogoutTile
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.72),
        ),
        const SizedBox(height: 8),
        Text(
          displayLabel,
          textAlign: TextAlign.center,
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        onTap: onPressed == null ? null : () => onPressed?.call(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}
