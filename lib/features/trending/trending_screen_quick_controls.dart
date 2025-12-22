part of 'trending_screen.dart';

class _QuickControlIcon extends StatelessWidget {
  const _QuickControlIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuickControlLine(color: color),
          const SizedBox(height: 6),
          _QuickControlLine(color: color),
        ],
      ),
    );
  }
}

class _TrendingQuickControlPanel extends StatefulWidget {
  const _TrendingQuickControlPanel({
    required this.theme,
    required this.appSettings,
    required this.onCompose,
    required this.onBackToTop,
    required this.onClearSearch,
  });

  final ThemeData theme;
  final AppSettings appSettings;
  final VoidCallback onCompose;
  final VoidCallback onBackToTop;
  final VoidCallback onClearSearch;

  @override
  State<_TrendingQuickControlPanel> createState() =>
      _TrendingQuickControlPanelState();
}

class _TrendingQuickControlPanelState
    extends State<_TrendingQuickControlPanel> {
  late final List<_QuickControlItem> _items;
  late final List<bool> _activeStates;

  Future<void> _showComingSoon(String feature) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$feature is coming soon',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _items = [
      _QuickControlItem(
        icon: Icons.school_rounded,
        label: 'Class',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      _QuickControlItem(
        icon: Icons.mode_edit_outline_rounded,
        label: 'Post',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onCompose();
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Quiz',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.quizDashboard());
        },
      ),
      _QuickControlItem(
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
      _QuickControlItem(
        icon: Icons.notifications_none_outlined,
        label: 'Notifications',
        onPressed: () async => _showComingSoon('Notifications'),
      ),
      _QuickControlItem(
        icon: Icons.forum_outlined,
        label: 'Messages',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      _QuickControlItem(
        icon: Icons.search_rounded,
        label: 'Search',
        onPressed: () async {
          Navigator.of(context).pop();
          // Already on search/trends page – just close the panel.
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Settings',
        onPressed: () async => _showComingSoon('Settings'),
      ),
      _QuickControlItem(
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
      child: Align(
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
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

class _QuickControlItem {
  const _QuickControlItem({
    required this.icon,
    required this.label,
    this.onPressed,
  })  : isTogglable = false,
        onToggle = null,
        initialValue = false;

  final IconData icon;
  final String label;
  final Future<void> Function()? onPressed;
  final Future<void> Function(bool)? onToggle;
  final bool isTogglable;
  final bool initialValue;
}

class _QuickControlButton extends StatelessWidget {
  const _QuickControlButton({
    required this.item,
    required this.isActive,
    required this.onPressed,
  });

  final _QuickControlItem item;
  final bool isActive;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final bool isLogoutTile = item.label == 'Log out';

    final Color baseIconColor = isActive
        ? (isDark ? Colors.white : Colors.black)
        : theme.colorScheme.onSurface.withValues(alpha: 0.70);
    final Color baseBorderColor = theme.dividerColor.withValues(
      alpha: isActive ? 0.4 : 0.25,
    );
    final Color baseBackgroundColor = isDark
        ? Colors.white.withValues(alpha: isActive ? 0.12 : 0.04)
        : Colors.white.withValues(alpha: isActive ? 0.9 : 0.8);

    final Color iconColor = isLogoutTile ? Colors.white : baseIconColor;
    final Color borderColor =
        isLogoutTile ? const Color(0xFFF56565) : baseBorderColor;
    final Color backgroundColor =
        isLogoutTile ? const Color(0xFFF56565) : baseBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed == null ? null : () => onPressed!(),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 24, color: iconColor),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickControlLine extends StatelessWidget {
  const _QuickControlLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
