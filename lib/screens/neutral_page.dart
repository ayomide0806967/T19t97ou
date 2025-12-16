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

    return ClipRRect(
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
          painter: _NeutralArtworkPainter(isDark: isDark),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _NeutralArtworkPainter extends CustomPainter {
  const _NeutralArtworkPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Color base = isDark ? const Color(0xFF0B0D12) : Colors.white;
    final Paint basePaint = Paint()..color = base;
    canvas.drawRect(rect, basePaint);

    final Paint glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.18 : 0.22),
          const Color(0xFF34D399).withValues(alpha: isDark ? 0.14 : 0.18),
          const Color(0xFFA78BFA).withValues(alpha: isDark ? 0.10 : 0.14),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      glow,
    );

    final Paint wave = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.03
      ..strokeCap = StrokeCap.round;

    final Path p1 = Path()
      ..moveTo(size.width * -0.1, size.height * 0.72)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.50,
        size.width * 0.44,
        size.height * 0.90,
        size.width * 0.72,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.40,
        size.width * 1.05,
        size.height * 0.70,
        size.width * 1.12,
        size.height * 0.48,
      );
    canvas.drawPath(p1, wave);

    final Paint wave2 = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.018
      ..strokeCap = StrokeCap.round;

    final Path p2 = Path()
      ..moveTo(size.width * -0.1, size.height * 0.36)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.20,
        size.width * 0.42,
        size.height * 0.48,
        size.width * 0.62,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.10,
        size.width * 1.06,
        size.height * 0.36,
        size.width * 1.14,
        size.height * 0.16,
      );
    canvas.drawPath(p2, wave2);

    final Paint dot = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    void drawDot(double dx, double dy, double r) {
      canvas.drawCircle(Offset(dx, dy), r, dot);
    }

    final double r1 = (size.shortestSide * 0.020).clamp(2.0, 6.0);
    final double r2 = (size.shortestSide * 0.012).clamp(1.5, 4.0);
    drawDot(size.width * 0.18, size.height * 0.22, r2);
    drawDot(size.width * 0.30, size.height * 0.42, r1);
    drawDot(size.width * 0.52, size.height * 0.20, r2);
    drawDot(size.width * 0.70, size.height * 0.34, r1);
    drawDot(size.width * 0.84, size.height * 0.18, r2);

    final Paint chip = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);
    final RRect pill = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.70),
        width: size.width * 0.62,
        height: size.height * 0.18,
      ),
      const Radius.circular(999),
    );
    canvas.drawRRect(pill, chip);
  }

  @override
  bool shouldRepaint(_NeutralArtworkPainter oldDelegate) =>
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
