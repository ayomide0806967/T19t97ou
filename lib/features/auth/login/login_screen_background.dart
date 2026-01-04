part of 'login_screen.dart';

class _InstitutionBackground extends StatefulWidget {
  const _InstitutionBackground({required this.cardCollapsed});

  final bool cardCollapsed;

  @override
  State<_InstitutionBackground> createState() => _InstitutionBackgroundState();
}

class _InstitutionBackgroundState extends State<_InstitutionBackground>
    with SingleTickerProviderStateMixin {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _softGrey = Color(0xFF9CA3AF);
  static const Color _dimGrey = Color(0xFF6B7280);

  static const _messages = <_InstitutionHeroMessage>[
    _InstitutionHeroMessage(text: 'IN INSTITUTION', accent: _white),
    _InstitutionHeroMessage(
      text: "The world's first social media school",
      accent: _softGrey,
    ),
    _InstitutionHeroMessage(
      text: 'You own a full class',
      accent: _softGrey,
    ),
    _InstitutionHeroMessage(
      text: 'Create a live quiz exam',
      accent: _white,
    ),
    _InstitutionHeroMessage(
      text: 'Create class notes',
      accent: _softGrey,
    ),
    _InstitutionHeroMessage(
      text: 'Monitor live quiz exam',
      accent: _white,
    ),
    _InstitutionHeroMessage(
      text: 'Post your ideas and go viral',
      accent: _softGrey,
    ),
    _InstitutionHeroMessage(
      text: 'Enjoy global visibility',
      accent: _white,
    ),
  ];

  Timer? _timer;
  late final AnimationController _controller;

  int _index = 0;
  int _nextIndex = 1;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 880),
      vsync: this,
    );
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      _beginTransition();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _beginTransition() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    _nextIndex = (_index + 1) % _messages.length;
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _index = _nextIndex;
        _isTransitioning = false;
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const base = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF070A0E)],
        ),
      ),
    );

    final bool showStronger = widget.cardCollapsed;
    final double textOpacity = showStronger ? 0.96 : 0.88;
    final Color accent = _currentAccent();
    final TextStyle titleStyle =
        Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontSize: 26,
          color: Colors.white.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w700,
          height: 1.08,
          letterSpacing: 0.0,
        ) ??
        TextStyle(
          fontSize: 26,
          color: Colors.white.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w700,
          height: 1.08,
        );
    final TextStyle subtitleStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 13,
          color: _dimGrey.withValues(alpha: 0.92),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.25,
        ) ??
        TextStyle(
          fontSize: 13,
          color: _dimGrey.withValues(alpha: 0.92),
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
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              alignment:
                  showStronger ? Alignment.center : const Alignment(0, -0.40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  height: 148,
                  child: Align(
                    alignment: Alignment.center,
                    child: _InstitutionHeroCyclingText(
                      controller: _controller,
                      messages: _messages,
                      index: _index,
                      nextIndex: _nextIndex,
                      isTransitioning: _isTransitioning,
                      titleStyle: titleStyle,
                      subtitleStyle: subtitleStyle,
                      logoColor: _softGrey,
                      defaultTextOpacity: textOpacity,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _currentAccent() {
    final current = _messages[_index].accent;
    if (!_isTransitioning) return current;
    final next = _messages[_nextIndex].accent;
    final t = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 1.0, curve: Curves.easeInOutCubic),
    ).value;
    return Color.lerp(current, next, t) ?? next;
  }
}

class _InstitutionHeroCyclingText extends StatelessWidget {
  const _InstitutionHeroCyclingText({
    required this.controller,
    required this.messages,
    required this.index,
    required this.nextIndex,
    required this.isTransitioning,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.logoColor,
    required this.defaultTextOpacity,
  });

  final Animation<double> controller;
  final List<_InstitutionHeroMessage> messages;
  final int index;
  final int nextIndex;
  final bool isTransitioning;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color logoColor;
  final double defaultTextOpacity;

  @override
  Widget build(BuildContext context) {
    final current = messages[index];
    final next = messages[nextIndex];

    if (!isTransitioning) {
      return _InstitutionHeroText(
        text: current.text,
        accent: current.accent,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        logoColor: logoColor,
      );
    }

    final focusIn = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOutCubic),
    );
    final focusOut = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.32, 0.62, curve: Curves.easeInCubic),
    );
    final focusOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(focusIn);
    final focusFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(focusOut);

    final focusScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.32, curve: Curves.easeOutBack),
      ),
    );

    final textT = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.22, 1.0, curve: Curves.easeInOutCubic),
    );

    final outgoingOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.22, 0.72, curve: Curves.easeInCubic),
      ),
    );
    final incomingOpacity = Tween<double>(begin: 0, end: 1).animate(textT);

    final outgoingScale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.22, 0.72, curve: Curves.easeInCubic),
      ),
    );
    final incomingScale = Tween<double>(begin: 1.02, end: 1.0).animate(textT);

    final animatedAccent = ColorTween(
      begin: current.accent.withValues(alpha: defaultTextOpacity),
      end: next.accent.withValues(alpha: defaultTextOpacity),
    ).animate(textT);

    final focusColor = ColorTween(
      begin: current.accent.withValues(alpha: 0.10),
      end: next.accent.withValues(alpha: 0.14),
    ).animate(textT);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final focusAlpha = focusOpacity.value * focusFade.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: focusScale.value,
              child: Opacity(
                opacity: focusAlpha.clamp(0.0, 1.0),
                child: _FocusRect(
                  color: focusColor.value ?? next.accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            ScaleTransition(
              scale: outgoingScale,
              child: FadeTransition(
                opacity: outgoingOpacity,
                child: _InstitutionHeroText(
                  text: current.text,
                  accent: current.accent,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                  logoColor: logoColor,
                ),
              ),
            ),
            ScaleTransition(
              scale: incomingScale,
              child: FadeTransition(
                opacity: incomingOpacity,
                child: _InstitutionHeroText(
                  text: next.text,
                  accent: animatedAccent.value ?? next.accent,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                  logoColor: logoColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FocusRect extends StatelessWidget {
  const _FocusRect({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 520,
        minHeight: 86,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }
}
