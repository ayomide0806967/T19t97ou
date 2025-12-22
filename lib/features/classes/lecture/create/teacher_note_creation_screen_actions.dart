part of 'teacher_note_creation_screen.dart';

mixin _TeacherNoteCreationActions on _TeacherNoteCreationScreenStateBase {
  Future<void> _handleAddImageForStep(int stepIndex) async {
    final existing = List<String>.from(
      _imagePathsByStep[stepIndex] ??
          (stepIndex < _sections.length
              ? _sections[stepIndex].imagePaths
              : const <String>[]),
    );
    if (existing.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 3 images per step.')),
      );
      return;
    }
    final picker = ImagePicker();
    final int remaining = 3 - existing.length;
    try {
      final List<XFile> picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;
      final Iterable<XFile> limited = picked.take(remaining);

      setState(() {
        final updated = existing..addAll(limited.map((x) => x.path));
        _imagePathsByStep[stepIndex] = updated;
        if (stepIndex < _sections.length) {
          final s = _sections[stepIndex];
          _sections[stepIndex] = ClassNoteSection(
            title: s.title,
            subtitle: s.subtitle,
            bullets: const <String>[],
            imagePaths: updated,
          );
        }
        if (_editingIndex == stepIndex) {
          _bulletsController.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open gallery. Please try again.'),
        ),
      );
    }
  }

  List<String> _parseBullets(String text) {
    if (text.trim().isEmpty) return [];
    return text.split('\n').where((s) => s.trim().isNotEmpty).toList();
  }

  int _wordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Open an existing step for editing
  void _openStepForEdit(int index) {
    // First save any current edits
    _saveCurrentEdits();

    // Load the step data into controllers
    final section = _sections[index];
    // Remove the "N · " prefix from title for editing
    final titleText = section.title.contains(' · ')
        ? section.title.split(' · ').skip(1).join(' · ')
        : section.title;
    _titleController.text = titleText;
    _subtitleController.text = section.subtitle;
    _bulletsController.text = section.bullets.join('\n');

    setState(() {
      _editingIndex = index;
    });

    // Scroll to the step being edited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToStep(index);
    });
  }

  /// Close current edit and go back to adding new step
  void _closeEditAndAddNew() {
    _saveCurrentEdits();
    _titleController.clear();
    _subtitleController.clear();
    _bulletsController.clear();

    setState(() {
      _editingIndex = null;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Save current edits (whether editing existing or adding new)
  void _saveCurrentEdits() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return; // Nothing to save

    // Enforce concise headings/subtitles.
    if (_wordCount(title) > _maxHeadingWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keep section heading under $_maxHeadingWords words'),
        ),
      );
      return;
    }
    final subtitle = _subtitleController.text.trim();
    if (_wordCount(subtitle) > _maxSubtitleWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keep subtitle under $_maxSubtitleWords words')),
      );
      return;
    }

    final content = _bulletsController.text.trim();
    if (_editingIndex != null) {
      final int stepIndex = _editingIndex!;
      final List<String> imagePaths =
          _imagePathsByStep[stepIndex] ?? _sections[stepIndex].imagePaths;
      if (imagePaths.isEmpty && _wordCount(content) > _maxWordsPerStep) {
        return; // Invalid – leave as-is
      }
      final List<String> bullets = imagePaths.isNotEmpty
          ? <String>[]
          : _parseBullets(content);

      // Update existing step
      final stepNum = _editingIndex! + 1;
      _sections[_editingIndex!] = ClassNoteSection(
        title: '$stepNum · $title',
        subtitle: subtitle,
        bullets: bullets,
        imagePaths: imagePaths,
      );
    }
  }

  /// Add a new step (when editing new step at end)
  void _addStep() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a section heading')),
      );
      return;
    }
    if (_wordCount(title) > _maxHeadingWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keep section heading under $_maxHeadingWords words'),
        ),
      );
      return;
    }

    final subtitle = _subtitleController.text.trim();
    if (_wordCount(subtitle) > _maxSubtitleWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keep subtitle under $_maxSubtitleWords words')),
      );
      return;
    }

    final int stepIndex = _sections.length;
    final List<String> imagePaths =
        _imagePathsByStep[stepIndex] ?? const <String>[];
    final content = _bulletsController.text.trim();
    final bullets = imagePaths.isNotEmpty ? <String>[] : _parseBullets(content);

    // Check if content exceeds word limit
    if (imagePaths.isEmpty && _wordCount(content) > _maxWordsPerStep) {
      // Auto-split into multiple sections
      _autoSplitAndAddSections(title, subtitle, bullets);
    } else {
      // Add single section normally
      final newSection = ClassNoteSection(
        title: '${_sections.length + 1} · $title',
        subtitle: subtitle,
        bullets: bullets,
        imagePaths: imagePaths,
      );

      setState(() {
        _sections.add(newSection);
        _titleController.clear();
        _subtitleController.clear();
        _bulletsController.clear();
        _imagePathsByStep.remove(stepIndex);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Auto-split content into multiple sections when exceeding word limit
  void _autoSplitAndAddSections(
    String baseTitle,
    String subtitle,
    List<String> allBullets,
  ) {
    final List<List<String>> splitBullets = [];
    List<String> currentChunk = [];
    int currentWordCount = 0;

    // Split bullets into chunks that don't exceed word limit
    for (final bullet in allBullets) {
      final bulletWords = _wordCount(bullet);

      if (currentWordCount + bulletWords > _maxWordsPerStep &&
          currentChunk.isNotEmpty) {
        // Start new chunk
        splitBullets.add(List.from(currentChunk));
        currentChunk = [bullet];
        currentWordCount = bulletWords;
      } else {
        currentChunk.add(bullet);
        currentWordCount += bulletWords;
      }
    }

    // Add remaining bullets
    if (currentChunk.isNotEmpty) {
      splitBullets.add(currentChunk);
    }

    // Create sections with continuation markers
    setState(() {
      for (int i = 0; i < splitBullets.length; i++) {
        final stepNum = _sections.length + 1;
        String sectionTitle;

        if (i == 0) {
          sectionTitle = '$stepNum · $baseTitle';
        } else if (i == 1) {
          sectionTitle = '$stepNum · $baseTitle (cont.)';
        } else {
          sectionTitle = '$stepNum · $baseTitle (cont. $i)';
        }

        _sections.add(
          ClassNoteSection(
            title: sectionTitle,
            subtitle: i == 0 ? subtitle : '',
            bullets: splitBullets[i],
          ),
        );
      }

      _titleController.clear();
      _subtitleController.clear();
      _bulletsController.clear();
    });

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Content split into ${splitBullets.length} sections (60 word limit)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAttachedQuizToast(BuildContext context, String title) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final entry = OverlayEntry(
      builder: (ctx) {
        final double top =
            MediaQuery.of(ctx).padding.top + 12; // just under status/app bar
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // WhatsApp chat bubble green
                color: const Color(0xFFDCF8C6),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF075E54),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quiz "$title" attached to this note.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF075E54),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  /// Save current edit and move to next step (for editing mode)
  void _saveAndNext() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a section heading')),
      );
      return;
    }
    if (_wordCount(title) > _maxHeadingWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keep section heading under $_maxHeadingWords words'),
        ),
      );
      return;
    }

    final subtitle = _subtitleController.text.trim();
    if (_wordCount(subtitle) > _maxSubtitleWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keep subtitle under $_maxSubtitleWords words')),
      );
      return;
    }

    final int stepIndex = _editingIndex!;
    final List<String> imagePaths =
        _imagePathsByStep[stepIndex] ?? _sections[stepIndex].imagePaths;
    final content = _bulletsController.text.trim();
    final bullets = imagePaths.isNotEmpty ? <String>[] : _parseBullets(content);

    // Check if content exceeds word limit
    if (imagePaths.isEmpty && _wordCount(content) > _maxWordsPerStep) {
      // Auto-split when editing
      _autoSplitAndReplaceSection(_editingIndex!, title, subtitle, bullets);
      _closeEditAndAddNew();
      return;
    }

    // Save current normally
    final stepNum = _editingIndex! + 1;
    _sections[_editingIndex!] = ClassNoteSection(
      title: '$stepNum · $title',
      subtitle: subtitle,
      bullets: bullets,
      imagePaths: imagePaths,
    );

    // Move to next step or new
    if (_editingIndex! < _sections.length - 1) {
      _openStepForEdit(_editingIndex! + 1);
    } else {
      _closeEditAndAddNew();
    }
  }

  /// Auto-split and replace section when editing
  void _autoSplitAndReplaceSection(
    int index,
    String baseTitle,
    String subtitle,
    List<String> allBullets,
  ) {
    final List<List<String>> splitBullets = [];
    List<String> currentChunk = [];
    int currentWordCount = 0;

    // Split bullets into chunks
    for (final bullet in allBullets) {
      final bulletWords = _wordCount(bullet);

      if (currentWordCount + bulletWords > _maxWordsPerStep &&
          currentChunk.isNotEmpty) {
        splitBullets.add(List.from(currentChunk));
        currentChunk = [bullet];
        currentWordCount = bulletWords;
      } else {
        currentChunk.add(bullet);
        currentWordCount += bulletWords;
      }
    }

    if (currentChunk.isNotEmpty) {
      splitBullets.add(currentChunk);
    }

    setState(() {
      // Replace current section and insert continuations after it
      for (int i = 0; i < splitBullets.length; i++) {
        final stepNum = index + i + 1;
        String sectionTitle;

        if (i == 0) {
          sectionTitle = '$stepNum · $baseTitle';
        } else if (i == 1) {
          sectionTitle = '$stepNum · $baseTitle (cont.)';
        } else {
          sectionTitle = '$stepNum · $baseTitle (cont. $i)';
        }

        final newSection = ClassNoteSection(
          title: sectionTitle,
          subtitle: i == 0 ? subtitle : '',
          bullets: splitBullets[i],
        );

        if (i == 0) {
          _sections[index] = newSection;
        } else {
          _sections.insert(index + i, newSection);
        }
      }

      // Renumber all subsequent sections
      for (int j = index + splitBullets.length; j < _sections.length; j++) {
        final oldSection = _sections[j];
        final oldTitle = oldSection.title;
        // Extract title after the "N · " prefix
        final titleParts = oldTitle.split(' · ');
        if (titleParts.length > 1) {
          final titleWithoutNum = titleParts.skip(1).join(' · ');
          _sections[j] = ClassNoteSection(
            title: '${j + 1} · $titleWithoutNum',
            subtitle: oldSection.subtitle,
            bullets: oldSection.bullets,
            imagePaths: oldSection.imagePaths,
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Content split into ${splitBullets.length} sections (60 word limit)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scrollToStep(int index) {
    // Estimate position based on step height
    final estimatedPosition = index * 180.0;
    _scrollController.animateTo(
      estimatedPosition.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    _saveCurrentEdits();
    if (_sections.isEmpty) return;
    final summary = ClassNoteSummary(
      title: widget.topic,
      subtitle: widget.subtitle,
      steps: _sections.length,
      estimatedMinutes: (_sections.length * 2).clamp(1, 30),
      createdAt: widget.initialCreatedAt ?? DateTime.now(),
      commentCount: widget.initialCommentCount,
      sections: List<ClassNoteSection>.unmodifiable(_sections),
      attachedQuizTitle: _attachedQuizTitle,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Class note created!')));
    Navigator.of(context).pop<ClassNoteSummary>(summary);
  }
}
