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
    required this.logoColor,
  });

  final String text;
  final Color accent;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color logoColor;

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = titleStyle.fontSize ?? 34;
    final double titleHeight = titleStyle.height ?? 1.05;
    final double subtitleFontSize = subtitleStyle.fontSize ?? 18;
    final double subtitleHeight = subtitleStyle.height ?? 1.25;

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
              style: baseStyle.copyWith(color: Colors.white),
            ),
            TextSpan(
              text: 'INSTITUTION',
              style: baseStyle.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    final bool hideSubtitle =
        text.toLowerCase() == "the world's first social media school";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: titleStyle.copyWith(color: accent),
          strutStyle: StrutStyle(
            fontFamily: titleStyle.fontFamily,
            fontSize: titleFontSize,
            height: titleHeight,
            forceStrutHeight: true,
          ),
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
        const SizedBox(height: 8),
        Visibility(
          visible: !hideSubtitle,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: Text(
            'IN INSTITUTION',
            textAlign: TextAlign.center,
            style: subtitleStyle,
            strutStyle: StrutStyle(
              fontFamily: subtitleStyle.fontFamily,
              fontSize: subtitleFontSize,
              height: subtitleHeight,
              forceStrutHeight: true,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
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
