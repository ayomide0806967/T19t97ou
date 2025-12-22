part of 'home_screen.dart';

class _StoryRail extends StatelessWidget {
  const _StoryRail({required this.currentUserHandle});

  final String currentUserHandle;

  @override
  Widget build(BuildContext context) {
    final classes = ClassService.userColleges(currentUserHandle);
    final List<_Story> stories = classes.map((c) => _Story(c.name)).toList();
    final theme = Theme.of(context);

    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 112,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => false,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final story = stories[index];
            final Color borderColor = theme.colorScheme.primary.withValues(
              alpha: 0.25,
            );
            final Color background = Theme.of(context).colorScheme.surface;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HexagonAvatar(
                    size: 56,
                    backgroundColor: background,
                    borderColor: borderColor,
                    borderWidth: 1.1,
                    child: Center(
                      child: Text(
                        story.initials,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      story.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeedTabBar extends StatefulWidget {
  const _FeedTabBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.pageController,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final PageController pageController;

  @override
  State<_FeedTabBar> createState() => _FeedTabBarState();
}

class _FeedTabBarState extends State<_FeedTabBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;

    final TextStyle baseStyle =
        theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    Widget buildLabel(String label, int index) {
      final bool isSelected = widget.selectedIndex == index;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            if (!isSelected) {
              widget.onChanged(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: baseStyle.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isSelected ? 0.98 : 0.65,
                ),
              ),
              child: Center(child: Text(label)),
            ),
          ),
        ),
      );
    }

    // Rebuild indicator position continuously while the PageView is being swiped.
    return AnimatedBuilder(
      animation: widget.pageController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double tabWidth = totalWidth / 2;

            final double t = () {
              if (widget.pageController.hasClients) {
                return (widget.pageController.page ??
                        widget.pageController.initialPage.toDouble())
                    .clamp(0.0, 1.0);
              }
              return widget.selectedIndex.toDouble().clamp(0.0, 1.0);
            }();

            // Indicator spans most of each tab, leaving a small inset so it
            // doesn't feel full-width, while still reaching closer to edges.
            const double inset = 8;
            final double indicatorWidth = tabWidth - (inset * 2);
            final double indicatorLeft = (tabWidth * t) + inset;

            return SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Row(
                    children: [
                      buildLabel('For You', 0),
                      buildLabel('Following', 1),
                    ],
                  ),
                  Positioned(
                    left: indicatorLeft,
                    bottom: 0,
                    child: RepaintBoundary(
                      child: Container(
                        height: 4,
                        width: indicatorWidth,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TwoLineMenuIcon extends StatelessWidget {
  const _TwoLineMenuIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [_MenuLine(), SizedBox(height: 6), _MenuLine()],
      ),
    );
  }
}

class _SearchIcon extends StatelessWidget {
  const _SearchIcon({
    this.size = 28,
    required this.color,
    this.strokeWidthFactor = 0.06,
  });

  final double size;
  final Color color;
  final double strokeWidthFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SearchIconPainter(
          color: color,
          strokeWidthFactor: strokeWidthFactor,
        ),
      ),
    );
  }
}

class _SearchIconPainter extends CustomPainter {
  _SearchIconPainter({required this.color, required this.strokeWidthFactor});

  final Color color;
  final double strokeWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double sw = s * strokeWidthFactor;
    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset center = Offset(s * 0.46, s * 0.46);
    final double radius = s * 0.26;
    canvas.drawCircle(center, radius, stroke);

    final Offset handleStart = Offset(s * 0.64, s * 0.64);
    final Offset handleEnd = Offset(s * 0.82, s * 0.82);
    canvas.drawLine(handleStart, handleEnd, stroke);
  }

  @override
  bool shouldRepaint(_SearchIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidthFactor != strokeWidthFactor;
}

class _MenuLine extends StatelessWidget {
  const _MenuLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Story {
  const _Story(this.label);

  final String label;

  String get initials => initialsFrom(label, fallback: 'IN');
}

