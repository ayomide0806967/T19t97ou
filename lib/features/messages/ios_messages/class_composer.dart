part of '../ios_messages_screen.dart';

class _ClassComposer extends StatefulWidget {
  const _ClassComposer({
    required this.controller,
    required this.onSend,
    required this.hintText,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final FocusNode? focusNode;

  @override
  State<_ClassComposer> createState() => _ClassComposerState();
}

class _ClassComposerState extends State<_ClassComposer> {
  final ImagePicker _picker = ImagePicker();
  final List<_Attachment> _attachments = <_Attachment>[];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _ClassComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _openEmojiPicker() async {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.7 : 0.55);
    
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // Text input row with send button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                          child: TextField(
                            controller: widget.controller,
                            maxLines: 2,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: Colors.white,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              height: 1.3,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: false,
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: subtle,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              widget.onSend();
                            },
                            child: const Center(
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Emoji picker
                EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji emoji) {
                    _insertEmoji(emoji.emoji);
                  },
                  config: Config(
                    height: 280,
                    checkPlatformCompatibility: false,
                    viewOrderConfig: const ViewOrderConfig(
                      top: EmojiPickerItem.categoryBar,
                      middle: EmojiPickerItem.emojiView,
                      bottom: EmojiPickerItem.searchBar,
                    ),
                    emojiViewConfig: EmojiViewConfig(
                      columns: 8,
                      emojiSizeMax: 30,
                      backgroundColor: theme.colorScheme.surface,
                      verticalSpacing: 8,
                      horizontalSpacing: 8,
                      gridPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      buttonMode: ButtonMode.CUPERTINO,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      initCategory: Category.SMILEYS,
                      recentTabBehavior: RecentTabBehavior.RECENT,
                      backgroundColor: theme.colorScheme.surface,
                      iconColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                      iconColorSelected: theme.colorScheme.primary,
                      indicatorColor: theme.colorScheme.primary,
                      backspaceColor: theme.colorScheme.primary,
                      dividerColor: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      enabled: false,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: theme.colorScheme.surface.withValues(
                        alpha: 0.98,
                      ),
                      buttonIconColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                      hintText: 'Search emoji',
                      hintTextStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      inputTextStyle: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _handleAttachImage() async {
    // Prefer multi-image selection if available
    final List<XFile> files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty) return;
    final List<_Attachment> items = [];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      items.add(_Attachment(bytes: bytes, name: f.name, mimeType: 'image/*'));
    }
    setState(() => _attachments.addAll(items));
  }

  Future<void> _handleAttachFile() async {
    // Fallback path that doesn't require `file_picker` package.
    // Inform the user how to enable real file picking.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'File attach requires the file_picker package. Run "flutter pub add file_picker" and restart.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openAttachMenu() async {
    final theme = Theme.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo or video'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: const Text('File'),
              onTap: () => Navigator.of(ctx).pop('file'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'gallery') {
      await _handleAttachImage();
    } else if (choice == 'file') {
      await _handleAttachFile();
    }
  }

  void _removeAttachmentAt(int index) {
    setState(() => _attachments.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.55);
    // Show the camera shortcut only when there's no text yet.
    final bool showCamera = widget.controller.text.trim().isEmpty;

    final double cardRadius = 16;
    final Color cardColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;

    final input = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: 3,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.newline,
      cursorColor: Colors.white,
      textAlignVertical: TextAlignVertical.center,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontSize: 14,
        height: 1.3,
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: false,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: subtle,
          fontSize: 14,
          height: 1.25,
          letterSpacing: 0.1,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        prefixIcon: IconButton(
          tooltip: 'Emoji',
          onPressed: _openEmojiPicker,
          icon: Icon(Icons.emoji_emotions_outlined, color: subtle, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          visualDensity: VisualDensity(horizontal: -2, vertical: -2),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Attach',
              onPressed: _openAttachMenu,
              icon: Icon(Icons.attach_file_rounded, color: subtle, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              visualDensity: VisualDensity(horizontal: -2, vertical: -2),
            ),
            if (showCamera)
              IconButton(
                tooltip: 'Camera',
                onPressed: _handleAttachImage,
                icon: Icon(
                  Icons.photo_camera_outlined,
                  color: subtle,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity: VisualDensity(horizontal: -2, vertical: -2),
              ),
          ],
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      onSubmitted: (_) => widget.onSend(),
    );

    final Widget textCard = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: input,
      ),
    );

    // Standalone pill send button to the right of the input.
    final Widget sendButton = SizedBox(
      height: 48,
      width: 48,
      child: Material(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            widget.onSend();
            if (_attachments.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sent with ${_attachments.length} attachment${_attachments.length == 1 ? '' : 's'}',
                  ),
                ),
              );
              setState(() => _attachments.clear());
            }
          },
          child: const Center(
            child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );

    // Make the send button visually detached to the right.
    final compactInput = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: textCard,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: sendButton,
        ),
      ],
    );

    if (_attachments.isEmpty) return compactInput;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) {
              final a = _attachments[i];
              Widget preview;
              if (a.isImage) {
                preview = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    a.bytes,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                final ext = (a.name ?? '').split('.').last.toUpperCase();
                preview = Container(
                  width: 120,
                  height: 76,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.name ?? 'File',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ext.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            ext,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  preview,
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      onTap: () => _removeAttachmentAt(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _attachments.length,
          ),
        ),
        const SizedBox(height: 8),
        compactInput,
      ],
    );
  }
}
