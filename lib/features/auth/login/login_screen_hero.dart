part of 'login_screen.dart';

class _InstitutionHeroMessage {
  const _InstitutionHeroMessage({required this.text, required this.accent});

  final String text;
  final Color accent;
}

class _InstitutionHeroText extends StatelessWidget {
  const _InstitutionHeroText({
    required this.text,
    required this.accent,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final String text;
  final Color accent;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    if (text.toUpperCase() == 'IN INSTITUTION') {
      final baseFontSize = titleStyle.fontSize ?? 34;
      final baseStyle = titleStyle.copyWith(
        fontSize: baseFontSize * 0.9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      );
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'IN ',
              style: baseStyle.copyWith(color: const Color(0xFFFF7A1A)),
            ),
            TextSpan(
              text: 'INSTITUTION',
              style: baseStyle.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    final words = text.split(' ');
    final String highlight = words.isNotEmpty ? words.first : text;
    final String rest = words.length > 1
        ? text.substring(highlight.length)
        : '';

    final bool hideSubtitle =
        text.toLowerCase() == "the world's first social media school";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: highlight,
                style: titleStyle.copyWith(
                  color: accent.withValues(alpha: 0.98),
                ),
              ),
              TextSpan(text: rest, style: titleStyle),
            ],
          ),
        ),
        if (!hideSubtitle) ...[
          const SizedBox(height: 8),
          Text(
            'IN INSTITUTION',
            textAlign: TextAlign.center,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText({
    required this.text,
    required this.fill,
    required this.stroke,
    required this.style,
  });

  final String text;
  final Color fill;
  final Color stroke;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final strokeStyle = style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = stroke.withValues(alpha: 0.75),
    );

    final fillStyle = style.copyWith(color: fill, foreground: null);

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, textAlign: TextAlign.center, style: strokeStyle),
        Text(text, textAlign: TextAlign.center, style: fillStyle),
      ],
    );
  }
}
