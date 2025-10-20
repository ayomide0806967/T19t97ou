import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TweetComposerCard extends StatefulWidget {
  const TweetComposerCard({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSubmit,
    this.replyingTo,
    this.onCancelReply,
    this.hintText = 'What\'s happening?',
    this.margin,
    this.padding,
    this.backgroundColor,
    this.boxShadow,
    this.footer,
    this.onImageTap,
    this.onGifTap,
    this.textInputAction = TextInputAction.send,
    this.isSubmitting = false,
    this.onChanged,
    this.maxCollapsedLines = 1,
    this.expandedMaxLines = 6,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmit;
  final String? replyingTo;
  final VoidCallback? onCancelReply;
  final String hintText;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Widget? footer;
  final VoidCallback? onImageTap;
  final VoidCallback? onGifTap;
  final TextInputAction textInputAction;
  final bool isSubmitting;
  final ValueChanged<String>? onChanged;
  final int maxCollapsedLines;
  final int expandedMaxLines;

  @override
  State<TweetComposerCard> createState() => _TweetComposerCardState();
}

class _TweetComposerCardState extends State<TweetComposerCard> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _expanded = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _initFocusNode();
    widget.controller.addListener(_handleTextChange);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  void _initFocusNode() {
    final focusNode = widget.focusNode;
    if (focusNode != null) {
      _focusNode = focusNode;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  void didUpdateWidget(covariant TweetComposerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
      _hasText = widget.controller.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTextChange() {
    final bool hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
        if (!hasText) {
          _expanded = false;
        }
      });
    }
    widget.onChanged?.call(widget.controller.text);
  }

  void _handleSubmit() {
    if (widget.isSubmitting) return;
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color containerColor = widget.backgroundColor ??
        (isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.white);
    final List<BoxShadow> shadows = widget.boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ];
    final Color iconColorInactive =
        theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final Color iconColorActive = theme.colorScheme.onSurface;
    final Color hintColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.35);

    final Widget composer = Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 28),
      padding:
          widget.padding ?? const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: shadows,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: widget.replyingTo == null
                    ? const SizedBox(
                        key: ValueKey('composer_reply_chip_none'),
                        height: 0,
                      )
                    : Padding(
                        key: const ValueKey('composer_reply_chip'),
                        padding: const EdgeInsets.only(bottom: 10, right: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Replying to @${widget.replyingTo}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.onCancelReply != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: widget.onCancelReply,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: !widget.isSubmitting,
                      minLines: widget.maxCollapsedLines,
                      maxLines: _hasText
                          ? widget.expandedMaxLines
                          : (_expanded ? widget.expandedMaxLines : widget.maxCollapsedLines),
                      textInputAction: widget.textInputAction,
                      keyboardType: TextInputType.multiline,
                      onSubmitted: widget.onSubmit == null
                          ? null
                          : (_) => _handleSubmit(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.hintText,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: hintColor,
                        ),
                        filled: false,
                      ),
                    ),
                  ),
                  if (_shouldShowActions)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: _hasText
                          ? const SizedBox(
                              key: ValueKey('composer_actions_none'),
                              width: 0,
                              height: 0,
                            )
                          : _ComposerHorizontalActions(
                              key: const ValueKey('composer_icons_horizontal'),
                              iconColor: iconColorInactive,
                              onImageTap: widget.onImageTap,
                              onGifTap: widget.onGifTap,
                              onToggleExpanded: _toggleExpanded,
                              expanded: _expanded,
                            ),
                    ),
                ],
              ),
            ],
          ),
          if (_shouldShowActions)
            Positioned(
              right: 4,
              top: -120,
              child: IgnorePointer(
                ignoring: !_hasText,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  opacity: _hasText ? 1 : 0,
                  child: SizedBox(
                    height: 148,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _ComposerVerticalActions(
                        key: const ValueKey('composer_icons_vertical'),
                        iconColor: iconColorActive,
                        onImageTap: widget.onImageTap,
                        onGifTap: widget.onGifTap,
                        onToggleExpanded: _toggleExpanded,
                        expanded: _expanded,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.footer == null) {
      return composer;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        composer,
        const SizedBox(height: 16),
        widget.footer!,
      ],
    );
  }

  bool get _shouldShowActions {
    return widget.onImageTap != null || widget.onGifTap != null;
  }
}

class _ComposerHorizontalActions extends StatelessWidget {
  const _ComposerHorizontalActions({
    super.key,
    required this.iconColor,
    required this.onImageTap,
    required this.onGifTap,
    required this.onToggleExpanded,
    required this.expanded,
  });

  final Color iconColor;
  final VoidCallback? onImageTap;
  final VoidCallback? onGifTap;
  final VoidCallback onToggleExpanded;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final IconData expandIcon =
        expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onImageTap != null) ...[
            _ComposerIconButton(
              icon: Icons.add_photo_alternate_outlined,
              color: iconColor,
              onTap: onImageTap!,
            ),
            const SizedBox(width: 10),
          ],
          if (onGifTap != null) ...[
            _ComposerIconButton(
              icon: Icons.gif_box_outlined,
              color: iconColor,
              onTap: onGifTap!,
            ),
            const SizedBox(width: 10),
          ],
          _ComposerIconButton(
            icon: expandIcon,
            color: iconColor,
            onTap: onToggleExpanded,
          ),
        ],
      ),
    );
  }
}

class _ComposerVerticalActions extends StatelessWidget {
  const _ComposerVerticalActions({
    super.key,
    required this.iconColor,
    required this.onImageTap,
    required this.onGifTap,
    required this.onToggleExpanded,
    required this.expanded,
  });

  final Color iconColor;
  final VoidCallback? onImageTap;
  final VoidCallback? onGifTap;
  final VoidCallback onToggleExpanded;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final IconData expandIcon =
        expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onImageTap != null) ...[
            _ComposerIconButton(
              icon: Icons.add_photo_alternate_outlined,
              color: iconColor,
              onTap: onImageTap!,
            ),
            const SizedBox(height: 12),
          ],
          if (onGifTap != null) ...[
            _ComposerIconButton(
              icon: Icons.gif_box_outlined,
              color: iconColor,
              onTap: onGifTap!,
            ),
            const SizedBox(height: 12),
          ],
          _ComposerIconButton(
            icon: expandIcon,
            color: iconColor,
            onTap: onToggleExpanded,
          ),
        ],
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
