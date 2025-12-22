part of 'login_screen.dart';

class _InstitutionBackground extends StatefulWidget {
  const _InstitutionBackground({required this.cardCollapsed});

  final bool cardCollapsed;

  @override
  State<_InstitutionBackground> createState() => _InstitutionBackgroundState();
}

class _InstitutionBackgroundState extends State<_InstitutionBackground> {
  static const _messages = <_InstitutionHeroMessage>[
    _InstitutionHeroMessage(text: 'IN INSTITUTION', accent: Color(0xFFFFFFFF)),
    _InstitutionHeroMessage(
      text: "The world's first social media school",
      accent: Color(0xFF5EEAD4),
    ),
    _InstitutionHeroMessage(
      text: 'You own a full class',
      accent: Color(0xFF93C5FD),
    ),
    _InstitutionHeroMessage(
      text: 'Create a live quiz exam',
      accent: Color(0xFFFCA5A5),
    ),
    _InstitutionHeroMessage(
      text: 'Create class notes',
      accent: Color(0xFFC4B5FD),
    ),
    _InstitutionHeroMessage(
      text: 'Monitor live quiz exam',
      accent: Color(0xFF67E8F9),
    ),
    _InstitutionHeroMessage(
      text: 'Post your ideas and go viral',
      accent: Color(0xFFFDE68A),
    ),
    _InstitutionHeroMessage(
      text: 'Enjoy global visibility',
      accent: Color(0xFF93C5FD),
    ),
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111827), Color(0xFF0B1220)],
        ),
      ),
    );

    final bool showStronger = widget.cardCollapsed;
    final message = _messages[_index];
    final double textOpacity = showStronger ? 0.96 : 0.88;
    final Color accent = message.accent;
    final TextStyle titleStyle =
        Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: Colors.white.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0.2,
        ) ??
        TextStyle(
          fontSize: 34,
          color: Colors.white.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w800,
          height: 1.05,
        );
    final TextStyle subtitleStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.25,
        ) ??
        TextStyle(
          fontSize: 18,
          color: Colors.white.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
          height: 1.25,
        );

    return Stack(
      children: [
        Positioned.fill(child: base),
        // Soft accent glows (mature, low-contrast) that shift with the message.
        Positioned(
          top: -120,
          left: -140,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.20), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -160,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.16), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: showStronger
                  ? const Alignment(0, -0.34)
                  : const Alignment(0, -0.48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 88),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide =
                        Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: Column(
                    key: ValueKey(_index),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.text.toUpperCase() == 'IN INSTITUTION')
                        SwissBankIcon(
                          size: 76,
                          color: accent.withValues(alpha: 0.92),
                          strokeWidthFactor: 0.085,
                        ),
                      if (message.text.toUpperCase() == 'IN INSTITUTION')
                        const SizedBox(height: 12),
                      _InstitutionHeroText(
                        text: message.text,
                        accent: accent,
                        titleStyle: titleStyle,
                        subtitleStyle: subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
