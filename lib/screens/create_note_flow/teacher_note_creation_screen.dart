import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/class_note.dart';
import '../quiz_create_screen.dart';

class TeacherNoteCreationScreen extends StatefulWidget {
  const TeacherNoteCreationScreen({
    super.key,
    required this.topic,
    required this.subtitle,
    this.attachQuizForNote = false,
    this.initialSections = const <ClassNoteSection>[],
    this.initialCreatedAt,
    this.initialCommentCount = 0,
  });

  final String topic;
  final String subtitle;
  final bool attachQuizForNote;
  final List<ClassNoteSection> initialSections;
  final DateTime? initialCreatedAt;
  final int initialCommentCount;

  @override
  State<TeacherNoteCreationScreen> createState() =>
      _TeacherNoteCreationScreenState();
}

class _TeacherNoteCreationScreenState extends State<TeacherNoteCreationScreen> {
  late List<ClassNoteSection> _sections;
  
  // Which step is currently being edited. 
  // If null, we're adding a new step at the end.
  // If set to an index, we're editing that existing step.
  int? _editingIndex;
  
  // Controllers for editing
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _bulletsController = TextEditingController();

  final _scrollController = ScrollController();

  static const int _maxWordsPerStep = 60;
  static const int _maxHeadingWords = 10;
  static const int _maxSubtitleWords = 5;
  final Map<int, List<String>> _imagePathsByStep = <int, List<String>>{};
  String? _attachedQuizTitle;

  Future<void> _handleAddImageForStep(int stepIndex) async {
    final existing = List<String>.from(
      _imagePathsByStep[stepIndex] ??
          (stepIndex < _sections.length ? _sections[stepIndex].imagePaths : const <String>[]),
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
        const SnackBar(content: Text('Could not open gallery. Please try again.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _sections = List<ClassNoteSection>.from(widget.initialSections);
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].imagePaths.isNotEmpty) {
        _imagePathsByStep[i] = List<String>.from(_sections[i].imagePaths);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _bulletsController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        SnackBar(
          content: Text('Keep subtitle under $_maxSubtitleWords words'),
        ),
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
      final List<String> bullets =
          imagePaths.isNotEmpty ? <String>[] : _parseBullets(content);

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
        SnackBar(
          content: Text('Keep subtitle under $_maxSubtitleWords words'),
        ),
      );
      return;
    }
    
    final int stepIndex = _sections.length;
    final List<String> imagePaths = _imagePathsByStep[stepIndex] ?? const <String>[];
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
  void _autoSplitAndAddSections(String baseTitle, String subtitle, List<String> allBullets) {
    final List<List<String>> splitBullets = [];
    List<String> currentChunk = [];
    int currentWordCount = 0;
    
    // Split bullets into chunks that don't exceed word limit
    for (final bullet in allBullets) {
      final bulletWords = _wordCount(bullet);
      
      if (currentWordCount + bulletWords > _maxWordsPerStep && currentChunk.isNotEmpty) {
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
        content: Text('Content split into ${splitBullets.length} sections (60 word limit)'),
        duration: const Duration(seconds: 2),
      ),
    );
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
        SnackBar(
          content: Text('Keep subtitle under $_maxSubtitleWords words'),
        ),
      );
      return;
    }
    
    final int stepIndex = _editingIndex!;
    final List<String> imagePaths = _imagePathsByStep[stepIndex] ?? _sections[stepIndex].imagePaths;
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
  void _autoSplitAndReplaceSection(int index, String baseTitle, String subtitle, List<String> allBullets) {
    final List<List<String>> splitBullets = [];
    List<String> currentChunk = [];
    int currentWordCount = 0;
    
    // Split bullets into chunks
    for (final bullet in allBullets) {
      final bulletWords = _wordCount(bullet);
      
      if (currentWordCount + bulletWords > _maxWordsPerStep && currentChunk.isNotEmpty) {
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
        content: Text('Content split into ${splitBullets.length} sections (60 word limit)'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class note created!')),
    );
    Navigator.of(context).pop<ClassNoteSummary>(summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditingNew = _editingIndex == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Note')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            child: Stack(
              children: [
                // Vertical rail line
                Positioned(
                  left: 12,
                  top: 12,
                  bottom: 0,
                  child: Container(width: 1, color: Colors.black26),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(left: 36, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.topic,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Steps
                    for (int i = 0; i < _sections.length; i++) ...[
                      if (_editingIndex == i)
                        // This step is being edited
                        _NoteEditingStep(
                          index: i,
                          isNewStep: false,
                          titleController: _titleController,
                          subtitleController: _subtitleController,
                          bulletsController: _bulletsController,
                          onNext: _saveAndNext,
                          headingWordLimit: _maxHeadingWords,
                          subtitleWordLimit: _maxSubtitleWords,
                          onCancel: _closeEditAndAddNew,
                          imagePaths: _imagePathsByStep[i] ?? _sections[i].imagePaths,
                          onAddImage: () => _handleAddImageForStep(i),
                        )
                      else
                        // Show as completed/collapsed
                        _CompletedNoteStep(
                          index: i,
                          total: _sections.length + (isEditingNew ? 1 : 0),
                          section: _sections[i],
                          onTap: () => _openStepForEdit(i),
                        ),
                      const SizedBox(height: 16),
                    ],
                    
                    // New step input (only show if not editing an existing step)
                    if (isEditingNew)
                      _NoteEditingStep(
                        index: _sections.length,
                        isNewStep: true,
                        titleController: _titleController,
                        subtitleController: _subtitleController,
                        bulletsController: _bulletsController,
                        onNext: _addStep,
                        headingWordLimit: _maxHeadingWords,
                        subtitleWordLimit: _maxSubtitleWords,
                        onCancel: null,
                        imagePaths: _imagePathsByStep[_sections.length] ?? const <String>[],
                        onAddImage: () => _handleAddImageForStep(_sections.length),
                      ),
                    
                    const SizedBox(height: 24),

                    // Publish + optional Add quiz button
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Row(
                        children: [
                          if (widget.attachQuizForNote) ...[
                            OutlinedButton.icon(
                              onPressed: () async {
                                final String? title =
                                    await Navigator.of(context).push<String>(
                                  MaterialPageRoute(
                                    builder: (_) => const QuizCreateScreen(
                                      returnToCallerOnPublish: true,
                                    ),
                                  ),
                                );
                                if (!mounted || title == null) return;
                                setState(() {
                                  _attachedQuizTitle = title;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Quiz "$title" attached to this note.',
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              icon: const Icon(Icons.quiz_outlined, size: 20),
                              label: Text(
                                _attachedQuizTitle == null
                                    ? 'Add quiz'
                                    : 'Quiz attached',
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          FilledButton(
                            onPressed: _sections.isEmpty ? null : _finish,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF075E54),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Publish'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 200),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Completed/collapsed step - tap to edit
class _CompletedNoteStep extends StatelessWidget {
  const _CompletedNoteStep({
    required this.index,
    required this.total,
    required this.section,
    required this.onTap,
  });

  final int index;
  final int total;
  final ClassNoteSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator - white circle for completed
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (index != 0)
                  Container(width: 2, height: 8, color: Colors.black),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(width: 2, height: 20, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (section.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            section.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (section.bullets.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${section.bullets.length} point${section.bullets.length > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Active editing step
class _NoteEditingStep extends StatefulWidget {
  const _NoteEditingStep({
    required this.index,
    required this.isNewStep,
    required this.titleController,
    required this.subtitleController,
    required this.bulletsController,
    required this.onNext,
    required this.headingWordLimit,
    required this.subtitleWordLimit,
    this.onCancel,
    required this.imagePaths,
    required this.onAddImage,
  });

  final int index;
  final bool isNewStep;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController bulletsController;
  final VoidCallback onNext;
  final VoidCallback? onCancel;
  final int headingWordLimit;
  final int subtitleWordLimit;
  final List<String> imagePaths;
  final VoidCallback onAddImage;

  @override
  State<_NoteEditingStep> createState() => _NoteEditingStepState();
}

class _NoteEditingStepState extends State<_NoteEditingStep> {
  List<String> _words(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> imagePaths = widget.imagePaths;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator - black filled for active
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (widget.index != 0)
                Container(width: 2, height: 8, color: Colors.black),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Input panel
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: theme.copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 1.8),
                  ),
                ),
                textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isNewStep
                        ? 'Step ${widget.index + 1}'
                        : 'Edit Step ${widget.index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: widget.titleController,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration:
                        const InputDecoration(labelText: 'Section Heading'),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      final words = _words(value);
                      if (words.length > widget.headingWordLimit) {
                        final truncated =
                            words.take(widget.headingWordLimit).join(' ');
                        widget.titleController.value = TextEditingValue(
                          text: truncated,
                          selection: TextSelection.collapsed(
                            offset: truncated.length,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Keep section heading under ${widget.headingWordLimit} words',
                              ),
                            ),
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: widget.subtitleController,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration:
                        const InputDecoration(labelText: 'Subtitle (optional)'),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      final words = _words(value);
                      if (words.length > widget.subtitleWordLimit) {
                        final truncated =
                            words.take(widget.subtitleWordLimit).join(' ');
                        widget.subtitleController.value = TextEditingValue(
                          text: truncated,
                          selection: TextSelection.collapsed(
                            offset: truncated.length,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Keep subtitle under ${widget.subtitleWordLimit} words',
                              ),
                            ),
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  imagePaths.isNotEmpty
                      ? SizedBox(
                          height: 160,
                          child: PageView.builder(
                            itemCount: imagePaths.length,
                            controller:
                                PageController(viewportFraction: 0.9),
                            itemBuilder: (context, index) {
                              final String path = imagePaths[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black12,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Image ${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : TextFormField(
                          controller: widget.bulletsController,
                          maxLines: null,
                          minLines: 4,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Content',
                            hintText:
                                'Write brief points here...\nEach line becomes a bullet.\nKeep it short (max ~60 words).',
                            alignLabelWithHint: true,
                            suffixIcon: widget.bulletsController.text
                                        .trim()
                                        .isEmpty &&
                                    widget.imagePaths.isEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.image_outlined),
                                    onPressed: widget.onAddImage,
                                  )
                                : null,
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: widget.onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF075E54),
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          widget.isNewStep ? Icons.arrow_downward : Icons.check,
                          size: 16,
                        ),
                        label: Text(
                            widget.isNewStep ? 'Next Step' : 'Save'),
                      ),
                      if (widget.onCancel != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
