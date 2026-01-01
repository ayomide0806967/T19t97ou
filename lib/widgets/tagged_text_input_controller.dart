part of 'tagged_text_input.dart';

class TaggedTextEditingController extends TextEditingController {
  TaggedTextEditingController({
    super.text,
    this.highlightStyle,
    RegExp? highlightPattern,
  }) : _highlightPattern = highlightPattern ?? _defaultPattern;

  static final RegExp _defaultPattern = RegExp(r'(@\w+|#\w+)');

  final TextStyle? highlightStyle;
  final RegExp _highlightPattern;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle baseStyle = style ?? DefaultTextStyle.of(context).style;
    final TextStyle accentStyle =
        (highlightStyle ??
        baseStyle.copyWith(
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
        ));

    final String text = value.text;
    if (text.isEmpty) {
      if (!withComposing || !value.isComposingRangeValid) {
        return TextSpan(style: baseStyle);
      }
      return TextSpan(
        style: baseStyle.merge(
          const TextStyle(decoration: TextDecoration.underline),
        ),
      );
    }

    final List<TextSpan> spans = _collectHighlightedSpans(
      text,
      baseStyle,
      accentStyle,
    );

    if (!withComposing || !value.isComposingRangeValid) {
      return TextSpan(style: baseStyle, children: spans);
    }

    final TextStyle composingStyle = const TextStyle(
      decoration: TextDecoration.underline,
    );
    final List<InlineSpan> composed = _applyComposing(
      spans,
      baseStyle,
      composingStyle,
    );
    return TextSpan(style: baseStyle, children: composed);
  }

  List<TextSpan> _collectHighlightedSpans(
    String text,
    TextStyle baseStyle,
    TextStyle highlight,
  ) {
    final List<TextSpan> spans = <TextSpan>[];
    int lastIndex = 0;
    for (final RegExpMatch match in _highlightPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }
      final String matched = match.group(0) ?? '';
      if (matched.isNotEmpty) {
        spans.add(TextSpan(text: matched, style: highlight));
      }
      lastIndex = match.end;
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
      return spans;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return spans;
  }

  List<InlineSpan> _applyComposing(
    List<TextSpan> spans,
    TextStyle baseStyle,
    TextStyle composingStyle,
  ) {
    final TextRange composing = value.composing;
    final List<InlineSpan> result = <InlineSpan>[];
    int globalStart = 0;

    for (final TextSpan span in spans) {
      final String spanText = span.text ?? '';
      final int spanLength = spanText.length;

      if (spanLength == 0) {
        result.add(span);
        continue;
      }

      final int spanStart = globalStart;
      final int spanEnd = spanStart + spanLength;

      if (composing.end <= spanStart || composing.start >= spanEnd) {
        result.add(span);
      } else {
        final int composeStart = composing.start.clamp(spanStart, spanEnd);
        final int composeEnd = composing.end.clamp(spanStart, spanEnd);

        if (composeStart == composeEnd) {
          result.add(span);
        } else {
          if (composeStart > spanStart) {
            result.add(
              TextSpan(
                text: spanText.substring(0, composeStart - spanStart),
                style: span.style,
              ),
            );
          }

          final TextStyle spanBaseStyle = span.style ?? baseStyle;
          result.add(
            TextSpan(
              text: spanText.substring(
                composeStart - spanStart,
                composeEnd - spanStart,
              ),
              style: spanBaseStyle.merge(composingStyle),
            ),
          );

          if (composeEnd < spanEnd) {
            result.add(
              TextSpan(
                text: spanText.substring(composeEnd - spanStart),
                style: span.style,
              ),
            );
          }
        }
      }

      globalStart += spanLength;
    }

    return result.isEmpty ? spans : result;
  }
}
