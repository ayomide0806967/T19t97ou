part of 'login_screen.dart';

class _CometBackground extends StatelessWidget {
  const _CometBackground({required this.cardCollapsed});

  final bool cardCollapsed;

  @override
  Widget build(BuildContext context) {
    final alignment = cardCollapsed
        ? const Alignment(0, -0.05)
        : const Alignment(0, -0.42);

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF060A10),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _StarfieldPainter(
              starCount: 140,
              seed: 7,
            ),
          ),
        ),
        // Soft nebula glow.
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.2, -0.5),
                  radius: 1.2,
                  colors: [
                    Color(0x332B6CB0),
                    Color(0x00111111),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -18,
          left: -30,
          child: _Planet(
            diameter: 110,
            baseColor: const Color(0xFFB7791F),
            accentColor: const Color(0xFF2B6CB0),
            highlight: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          left: -120,
          right: -120,
          bottom: -260,
          child: _Planet(
            diameter: 620,
            baseColor: const Color(0xFFB7791F),
            accentColor: const Color(0xFF2B6CB0),
            highlight: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                const Spacer(),
                _PageDots(
                  count: 4,
                  activeIndex: 0,
                ),
                const Spacer(),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white.withValues(alpha: 0.72),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 74),
                    const SizedBox(height: 16),
                    Text(
                      'institution',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: 54,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                            letterSpacing: -1.2,
                            height: 0.95,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'From classroom notes to viral posts',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
                            height: 1.35,
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
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final bool active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _Planet extends StatelessWidget {
  const _Planet({
    required this.diameter,
    required this.baseColor,
    required this.accentColor,
    required this.highlight,
  });

  final double diameter;
  final Color baseColor;
  final Color accentColor;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.25, -0.35),
            radius: 0.92,
            colors: [
              baseColor.withValues(alpha: 0.95),
              baseColor.withValues(alpha: 0.58),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: ClipOval(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PlanetBandsPainter(
                    accentColor: accentColor,
                    highlight: highlight,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.1, -0.2),
                      radius: 0.95,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanetBandsPainter extends CustomPainter {
  _PlanetBandsPainter({required this.accentColor, required this.highlight});

  final Color accentColor;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;

    void band({
      required double dy,
      required double thickness,
      required Color color,
      required double rotation,
      required double opacity,
    }) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(rotation);
      canvas.translate(-size.width / 2, -size.height / 2);
      paint.color = color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-size.width * 0.2, dy, size.width * 1.4, thickness),
          Radius.circular(thickness),
        ),
        paint,
      );
      canvas.restore();
    }

    band(
      dy: size.height * 0.42,
      thickness: size.height * 0.16,
      color: accentColor,
      rotation: -0.25,
      opacity: 0.35,
    );
    band(
      dy: size.height * 0.52,
      thickness: size.height * 0.10,
      color: highlight,
      rotation: -0.25,
      opacity: 0.55,
    );
    band(
      dy: size.height * 0.62,
      thickness: size.height * 0.12,
      color: accentColor,
      rotation: -0.25,
      opacity: 0.22,
    );

    // Subtle vignette.
    paint.shader = const RadialGradient(
      center: Alignment(0.25, 0.25),
      radius: 1.05,
      colors: [Color(0x00000000), Color(0xAA000000)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _PlanetBandsPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.highlight != highlight;
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.starCount, required this.seed});

  final int starCount;
  final int seed;

  double _hash(int n) {
    // Deterministic pseudo-random in [0, 1).
    final x = math.sin((n + seed) * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    for (var i = 0; i < starCount; i++) {
      final fx = _hash(i * 3);
      final fy = _hash(i * 3 + 1);
      final fr = _hash(i * 3 + 2);

      final x = fx * w;
      final y = fy * h;
      final r = 0.6 + fr * 1.4;
      final a = 0.10 + fr * 0.55;

      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // A few "bright" stars.
    for (var i = 0; i < 10; i++) {
      final fx = _hash(999 + i * 4);
      final fy = _hash(999 + i * 4 + 1);
      final fr = _hash(999 + i * 4 + 2);
      final x = fx * w;
      final y = fy * h;
      final r = 1.6 + fr * 1.6;

      paint.color = Colors.white.withValues(alpha: 0.72);
      canvas.drawCircle(Offset(x, y), r, paint);
      paint.color = Colors.white.withValues(alpha: 0.12);
      canvas.drawCircle(Offset(x, y), r * 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.starCount != starCount || oldDelegate.seed != seed;
  }
}
