import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

part 'tagged_text_input_controller.dart';
part 'tagged_text_input_suggestions.dart';

class TaggedTextInput extends StatefulWidget {
  const TaggedTextInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.style,
    this.hintStyle,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLines;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextStyle? hintStyle;

  @override
  State<TaggedTextInput> createState() => _TaggedTextInputState();
}

class _TaggedTextInputState extends State<TaggedTextInput> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;
  String _currentMention = '';
  int _mentionStart = 0;
  int _mentionEnd = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _showSuggestions) {
      _showSuggestionsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: _MentionSuggestions(
            query: _currentMention,
            onSelected: _onSuggestionSelected,
            onClose: () {
              setState(() {
                _showSuggestions = false;
                _currentMention = '';
              });
              _removeOverlay();
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSuggestionSelected(String suggestion) {
    final text = widget.controller.text;
    final beforeMention = text.substring(0, _mentionStart);
    final afterMention = text.substring(_mentionEnd);

    widget.controller.text = '$beforeMention$suggestion $afterMention';
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: beforeMention.length + suggestion.length + 1),
    );

    setState(() {
      _showSuggestions = false;
      _currentMention = '';
    });
    _removeOverlay();

    widget.onChanged?.call(widget.controller.text);
  }

  void _handleTextChange(String text) {
    final cursorPosition = widget.controller.selection.baseOffset;
    if (cursorPosition < 0) return;

    // Check for @ mentions
    if (cursorPosition > 0 && text[cursorPosition - 1] == '@') {
      // Start of a new mention
      setState(() {
        _showSuggestions = true;
        _currentMention = '';
        _mentionStart = cursorPosition - 1;
        _mentionEnd = cursorPosition;
      });
      _showSuggestionsOverlay();
    } else if (_showSuggestions && cursorPosition > _mentionStart + 1) {
      // Continuing an existing mention
      final mentionText = text.substring(_mentionStart, cursorPosition);
      if (mentionText.contains(' ') || mentionText.contains('\n')) {
        // Mention ended
        setState(() {
          _showSuggestions = false;
          _currentMention = '';
        });
        _removeOverlay();
      } else {
        // Update suggestion query
        setState(() {
          _currentMention = mentionText.substring(1); // Remove @
          _mentionEnd = cursorPosition;
        });
        _showSuggestionsOverlay();
      }
    }

    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final TextStyle baseTextStyle =
        ((widget.style ?? theme.textTheme.bodyLarge) ?? const TextStyle())
            .copyWith(height: 1.4, color: Colors.black);
    final TextStyle defaultHintStyle = TextStyle(
      color: Colors.black.withValues(alpha: 0.45),
      fontSize: baseTextStyle.fontSize ?? 16,
      height: 1.4,
    );
    final Color backgroundColor = isDark
        ? const Color(0xFFF4F1EC)
        : Colors.white;
    final Color borderColor = isDark
        ? Colors.black.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus ? AppTheme.accent : borderColor,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            style: baseTextStyle,
            cursorColor: AppTheme.accent,
            onChanged: _handleTextChange,
            onTap: widget.onTap,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ?? defaultHintStyle,
              filled: false,
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (_showSuggestions && _focusNode.hasFocus)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSuggestions = false;
                  _currentMention = '';
                });
                _removeOverlay();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }
}
