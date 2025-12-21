import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../screens/compose_screen.dart';
import '../screens/ios_messages_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/quiz_dashboard_screen.dart';
import 'hexagon_compose_button.dart';

class ComposeFab extends StatefulWidget {
  const ComposeFab({super.key});

  @override
  State<ComposeFab> createState() => _ComposeFabState();
}

class _ComposeFabState extends State<ComposeFab> {
  final GlobalKey _fabKey = GlobalKey();
  bool _isMenuOpen = false;

  Future<void> _openQuickComposer() async {
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(builder: (_) => const ComposeScreen()));
  }

  Future<void> _showFabMenu() async {
    if (_isMenuOpen) return;

    final renderObject = _fabKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final Offset topLeft = renderObject.localToGlobal(Offset.zero);
    final Size size = renderObject.size;
    final Rect fabRect = topLeft & size;
    final Size screenSize = MediaQuery.sizeOf(context);
    final double right = screenSize.width - fabRect.right;
    final double bottom = screenSize.height - fabRect.bottom;

    if (mounted) {
      setState(() => _isMenuOpen = true);
    }

    final navigator = Navigator.of(context);
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Compose menu',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void close() => Navigator.of(dialogContext).pop();

        return _ComposeFabMenuOverlay(
          anchorRight: right,
          anchorBottom: bottom,
          onClose: close,
          actions: [
            _ComposeFabAction(
              label: 'Go Class',
              icon: Icons.school_rounded,
              animationOrder: 2,
              onTap: () {
                close();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const IosMinimalistMessagePage(),
                  ),
                );
              },
            ),
            _ComposeFabAction(
              label: 'Quizzes',
              icon: Icons.quiz_outlined,
              animationOrder: 1,
              onTap: () {
                close();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const QuizDashboardScreen(),
                  ),
                );
              },
            ),
            _ComposeFabAction(
              label: 'Photos',
              icon: Icons.photo_outlined,
              animationOrder: 0,
              showPlus: true,
              onTap: () {
                close();
                _openQuickComposer();
              },
            ),
          ],
          onCompose: () {
            close();
            _openQuickComposer();
          },
        );
      },
    );

    if (!mounted) return;
    setState(() => _isMenuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return HexagonComposeButton(
      key: _fabKey,
      onTap: _showFabMenu,
      showPlus: _isMenuOpen,
    );
  }
}

class _ComposeFabAction {
  const _ComposeFabAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showPlus = false,
    this.animationOrder = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool showPlus;
  final int animationOrder;
}

class _ComposeFabMenuOverlay extends StatefulWidget {
  const _ComposeFabMenuOverlay({
    required this.anchorRight,
    required this.anchorBottom,
    required this.onClose,
    required this.onCompose,
    required this.actions,
  });

  final double anchorRight;
  final double anchorBottom;
  final VoidCallback onClose;
  final VoidCallback onCompose;
  final List<_ComposeFabAction> actions;

  @override
  State<_ComposeFabMenuOverlay> createState() =>
      _ComposeFabMenuOverlayState();
}

class _ComposeFabMenuOverlayState extends State<_ComposeFabMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double t = _animation.value;
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onClose,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 2 * t, sigmaY: 2 * t),
                    child: Container(
                      color: Colors.white.withOpacity(0.94 * t),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: widget.anchorRight,
                bottom: widget.anchorBottom,
                child: _ComposeFabMenu(
                  animation: _animation,
                  onClose: widget.onClose,
                  onCompose: widget.onCompose,
                  actions: widget.actions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComposeFabMenu extends StatelessWidget {
  const _ComposeFabMenu({
    required this.animation,
    required this.onClose,
    required this.onCompose,
    required this.actions,
  });

  final Animation<double> animation;
  final VoidCallback onClose;
  final VoidCallback onCompose;
  final List<_ComposeFabAction> actions;

  @override
  Widget build(BuildContext context) {
    const double itemGap = 18;
    final theme = Theme.of(context);
    final Animation<double> buttonScale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int index = 0; index < actions.length; index++) ...[
          _ComposeFabStaggeredEntry(
            animation: animation,
            index: actions[index].animationOrder,
            child: _FabMenuItem(
              label: actions[index].label,
              icon: actions[index].icon,
              showPlus: actions[index].showPlus,
              onTap: actions[index].onTap,
            ),
          ),
          if (index != actions.length - 1) const SizedBox(height: itemGap),
        ],
        const SizedBox(height: 14),
        _ComposeFabStaggeredEntry(
          animation: animation,
          index: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(
                  'Post',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ScaleTransition(
                scale: buttonScale,
                child: HexagonComposeButton(onTap: onCompose, showPlus: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposeFabStaggeredEntry extends StatelessWidget {
  const _ComposeFabStaggeredEntry({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double start = 0.10 + (index * 0.18);
    final double end = (start + 0.40).clamp(0.0, 1.0);
    final Animation<double> entry = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      reverseCurve: Threshold(0.999),
    );

    return FadeTransition(
      opacity: entry,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.20),
          end: Offset.zero,
        ).animate(entry),
        child: RotationTransition(
          turns: Tween<double>(
            begin: 0.5,
            end: 0.0,
          ).animate(entry),
          child: child,
        ),
      ),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showPlus = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background = isDark
        ? Colors.white.withOpacity(0.98)
        : Colors.white.withOpacity(0.98);
    final Color textColor = Colors.black;
    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.black),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (showPlus) ...[
                const SizedBox(width: 8),
                const Icon(Icons.add_rounded, size: 16, color: Colors.black),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
