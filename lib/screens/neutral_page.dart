import 'package:flutter/material.dart';

import 'create_class_screen.dart';
import 'ios_messages_screen.dart';
import 'quiz_create_screen.dart';

class NeutralPage extends StatelessWidget {
  const NeutralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface =
        isDark ? const Color(0xFF0E0F12) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Neutral page'),
        backgroundColor: surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            _HubCard(
              title: 'Continue to inbox',
              subtitle: 'Open your conversations and class channels.',
              icon: Icons.mail_outline_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const IosMinimalistMessagePage(
                    openInboxOnStart: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _HubCard(
              title: 'Create new class',
              subtitle: 'Set up a new class space.',
              icon: Icons.class_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateClassScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HubCard(
              title: 'Create new quiz',
              subtitle: 'Launch the step-by-step builder for a fresh quiz.',
              icon: Icons.create_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuizCreateScreen()),
              ),
            ),
            const SizedBox(height: 18),
            const Expanded(child: _NeutralArtwork()),
          ],
        ),
      ),
    );
  }
}

class _NeutralArtwork extends StatelessWidget {
  const _NeutralArtwork();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;

    final double screenWidth = MediaQuery.sizeOf(context).width;

    // This page uses horizontal padding for the cards; the artwork below is
    // meant to go edge-to-edge, so we allow it to overflow the padded width.
    return OverflowBox(
      alignment: Alignment.topCenter,
      minWidth: screenWidth,
      maxWidth: screenWidth,
      child: Padding(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: CustomPaint(
              painter: _EducationArtworkPainter(isDark: isDark),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _EducationArtworkPainter extends CustomPainter {
  const _EducationArtworkPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Notebook paper background.
    final Color paper = isDark ? const Color(0xFF0B0D12) : const Color(0xFFFAFAFA);
    canvas.drawRect(rect, Paint()..color = paper);

    final Color lineColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.06 : 0.05);
    final double lineGap = (size.height / 10).clamp(18.0, 40.0);
    final Paint lines = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double y = lineGap; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }

    // Margin line.
    final Paint margin = Paint()
      ..color = const Color(0xFFF87171).withValues(alpha: isDark ? 0.16 : 0.22)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.12, size.height),
      margin,
    );

    // Soft chalkboard vignette.
    final Paint vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.2),
        radius: 1.2,
        colors: [
          const Color(0xFF22C55E).withValues(alpha: isDark ? 0.10 : 0.06),
          const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.10 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    final Color ink =
        (isDark ? Colors.white : const Color(0xFF111827)).withValues(alpha: 0.55);
    final Paint stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.shortestSide * 0.012).clamp(1.5, 3.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fineStroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (stroke.strokeWidth * 0.75)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint accent = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF111827))
          .withValues(alpha: isDark ? 0.10 : 0.08)
      ..style = PaintingStyle.fill;

    // Doodle: open book.
    final Offset bookCenter = Offset(size.width * 0.30, size.height * 0.58);
    final double bw = size.width * 0.28;
    final double bh = size.height * 0.22;
    final Rect left = Rect.fromCenter(
      center: Offset(bookCenter.dx - bw * 0.18, bookCenter.dy),
      width: bw * 0.48,
      height: bh,
    );
    final Rect right = Rect.fromCenter(
      center: Offset(bookCenter.dx + bw * 0.18, bookCenter.dy),
      width: bw * 0.48,
      height: bh,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(left, const Radius.circular(14)), accent);
    canvas.drawRRect(RRect.fromRectAndRadius(right, const Radius.circular(14)), accent);
    canvas.drawRRect(RRect.fromRectAndRadius(left, const Radius.circular(14)), stroke);
    canvas.drawRRect(RRect.fromRectAndRadius(right, const Radius.circular(14)), stroke);
    canvas.drawLine(
      Offset(bookCenter.dx, bookCenter.dy - bh * 0.46),
      Offset(bookCenter.dx, bookCenter.dy + bh * 0.46),
      stroke,
    );
    for (int i = 0; i < 4; i++) {
      final dy = (-0.25 + i * 0.16) * bh;
      canvas.drawLine(
        Offset(left.left + bw * 0.06, bookCenter.dy + dy),
        Offset(bookCenter.dx - bw * 0.06, bookCenter.dy + dy),
        fineStroke,
      );
      canvas.drawLine(
        Offset(bookCenter.dx + bw * 0.06, bookCenter.dy + dy),
        Offset(right.right - bw * 0.06, bookCenter.dy + dy),
        fineStroke,
      );
    }

    // Doodle: graduation cap (replaces pencil).
    stroke.strokeWidth = (size.shortestSide * 0.012).clamp(1.5, 3.0);
    final Offset capCenter = Offset(size.width * 0.80, size.height * 0.44);
    final double capW = size.width * 0.26;
    final double capH = size.height * 0.10;

    final Path board = Path()
      ..moveTo(capCenter.dx, capCenter.dy - capH * 0.55)
      ..lineTo(capCenter.dx + capW * 0.48, capCenter.dy)
      ..lineTo(capCenter.dx, capCenter.dy + capH * 0.55)
      ..lineTo(capCenter.dx - capW * 0.48, capCenter.dy)
      ..close();
    canvas.drawPath(board, accent);
    canvas.drawPath(board, stroke);

    final Rect band = Rect.fromCenter(
      center: Offset(capCenter.dx, capCenter.dy + capH * 0.78),
      width: capW * 0.42,
      height: capH * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(10)),
      accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(10)),
      stroke,
    );

    final Offset tasselAnchor =
        Offset(capCenter.dx + capW * 0.18, capCenter.dy + capH * 0.16);
    final Offset tasselEnd =
        Offset(capCenter.dx + capW * 0.30, capCenter.dy + capH * 1.15);
    canvas.drawLine(tasselAnchor, tasselEnd, fineStroke);
    canvas.drawCircle(
      tasselEnd,
      (size.shortestSide * 0.012).clamp(2.0, 4.0),
      Paint()..color = ink.withValues(alpha: 0.65),
    );

    // Doodle: atom.
    final Offset atomCenter = Offset(size.width * 0.72, size.height * 0.78);
    final double r = (size.shortestSide * 0.12).clamp(22.0, 44.0);
    for (final angle in <double>[0, 1.05, -1.05]) {
      canvas.save();
      canvas.translate(atomCenter.dx, atomCenter.dy);
      canvas.rotate(angle);
      final Rect oval = Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 1.2);
      canvas.drawOval(oval, stroke);
      canvas.restore();
    }
    canvas.drawCircle(atomCenter, r * 0.12, Paint()..color = ink.withValues(alpha: 0.75));

    // Small math doodles.
    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'E=mc²   ∑   π',
        style: TextStyle(
          color: ink.withValues(alpha: 0.55),
          fontSize: (size.shortestSide * 0.08).clamp(14.0, 22.0),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset(size.width * 0.16, size.height * 0.12));
  }

  @override
  bool shouldRepaint(_EducationArtworkPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.2);
    final Color subtitleColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
