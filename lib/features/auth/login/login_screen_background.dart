part of 'login_screen.dart';

class _CometBackground extends StatelessWidget {
  const _CometBackground({required this.cardCollapsed});

  final bool cardCollapsed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ultra-dark, flat space background with subtle blue undertone.
        const Positioned.fill(
          child: ColoredBox(
            color: Color(0xFF0F151A),
          ),
        ),
        // Very fine film-grain style noise for depth.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(
                seed: 11,
                density: 0.85,
              ),
            ),
          ),
        ),
        // Sparse, tiny star speckles (no glow, low opacity).
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StarfieldPainter(
                starCount: 110,
                seed: 7,
              ),
            ),
          ),
        ),
        // Soft vignette toward the edges to frame content.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 80, 18, 0),
            child: Row(
              children: [
                const Spacer(),
                _PageDots(
                  count: 4,
                  activeIndex: cardCollapsed ? 0 : 1,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        // Foreground content is rendered by the login screen overlay to keep
        // it perfectly aligned with the slider/policy block.
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

class _HorizonSpherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final baseBg = const Color(0xFF0E1418);
    final teal = const Color(0xD96FAFA6); // ≈85%
    final olive = const Color(0xCC8F8A4E); // ≈80%
    final charcoal = const Color(0xE61E2422); // ≈90%

    // Large rounded rectangle rising from the bottom; only top band visible.
    final width = size.width * 1.4;
    final height = size.height * 0.9;
    final rect = Rect.fromLTWH(
      (size.width - width) / 2,
      size.height - height * 0.42,
      width,
      height,
    );
    final outerRadius = Radius.circular(height * 0.55);
    final outerRRect = RRect.fromRectAndRadius(rect, outerRadius);

    final paint = Paint()..isAntiAlias = true;
    final clip = Path()..addRRect(outerRRect);

    // Draw into a clipped layer so feathering/noise stays inside the shape.
    canvas.save();
    canvas.clipPath(clip);

    // Base charcoal field (matte).
    paint
      ..shader = null
      ..maskFilter = null
      ..color = charcoal;
    canvas.drawRRect(outerRRect, paint);

    // Overlapping matte color fields with feathered boundaries.
    // Use a blur mask for soft edges (no highlights / no gloss).
    const featherSigma = 18.0;
    paint.maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, featherSigma);

    final corner = Radius.circular((height * 0.22).clamp(16.0, 44.0));

    // Left rectangular field (muted teal).
    paint
      ..shader = null
      ..color = teal;
    final leftRect = Rect.fromLTWH(
      rect.left + rect.width * -0.05,
      rect.top + rect.height * -0.02,
      rect.width * 0.58,
      rect.height * 1.05,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(leftRect, corner), paint);

    // Right rectangular field (olive-gold).
    paint.color = olive;
    final rightRect = Rect.fromLTWH(
      rect.left + rect.width * 0.47,
      rect.top + rect.height * -0.02,
      rect.width * 0.60,
      rect.height * 1.05,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rightRect, corner), paint);

    // Central overlap field (deep charcoal), drawn last to keep overlap dark.
    paint.color = charcoal;
    final midRect = Rect.fromLTWH(
      rect.left + rect.width * 0.32,
      rect.top + rect.height * -0.03,
      rect.width * 0.36,
      rect.height * 1.04,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(midRect, corner), paint);

    // Very fine monochrome grain on the sphere (4–6% opacity).
    paint
      ..maskFilter = null
      ..shader = null
      ..isAntiAlias = false;
    final area = rect.width * rect.height;
    final count = (area / 1400).round().clamp(800, 5200);
    for (var i = 0; i < count; i++) {
      final fx = _hash(i * 3);
      final fy = _hash(i * 3 + 1);
      final fr = _hash(i * 3 + 2);
      final x = rect.left + fx * rect.width;
      final y = rect.top + fy * rect.height;
      final alpha = 0.04 + fr * 0.02; // 4–6%
      final isLight = fr > 0.5;
      paint.color =
          (isLight ? Colors.white : Colors.black).withValues(alpha: alpha);
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }

    canvas.restore();

    // Soft edge blur around the shape perimeter (~15px feather), blending into background.
    final edgeFeatherPx = 15.0;
    final maxExtent = (rect.width + rect.height) / 2;
    final edgeStop = (1.0 - (edgeFeatherPx / maxExtent)).clamp(0.0, 1.0);
    paint
      ..isAntiAlias = true
      ..maskFilter = null
      ..shader = RadialGradient(
        center: Alignment(0, -0.1),
        radius: 1.0,
        colors: [
          Colors.transparent,
          baseBg,
        ],
        stops: [edgeStop, 1.0],
      ).createShader(rect);
    canvas.drawRRect(outerRRect, paint);
  }

  @override
  bool shouldRepaint(covariant _HorizonSpherePainter oldDelegate) => false;

  double _hash(int n) {
    final x = math.sin(n * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
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
      final r = 0.4 + fr * 0.9;
      final a = 0.10 + fr * 0.30;

      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.starCount != starCount || oldDelegate.seed != seed;
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({
    required this.seed,
    required this.density,
  });

  final int seed;
  final double density; // 0–1, controls how many samples to draw.

  double _hash(int n) {
    final x = math.sin((n + seed) * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final area = size.width * size.height;
    final count = (area / 900 * density).round().clamp(200, 2200);

    for (var i = 0; i < count; i++) {
      final fx = _hash(i * 2);
      final fy = _hash(i * 2 + 1);
      final fr = _hash(i * 2 + 2);

      final dx = fx * size.width;
      final dy = fy * size.height;
      final a = 0.03 + fr * 0.06;

      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawRect(
        Rect.fromLTWH(dx, dy, 1, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.density != density;
  }
}
