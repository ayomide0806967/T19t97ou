import 'package:flutter/material.dart';
import '../../models/class_note.dart';

class TeacherNoteCreationScreen extends StatefulWidget {
  const TeacherNoteCreationScreen({
    super.key,
    required this.topic,
    required this.subtitle,
  });

  final String topic;
  final String subtitle;

  @override
  State<TeacherNoteCreationScreen> createState() =>
      _TeacherNoteCreationScreenState();
}

class _TeacherNoteCreationScreenState extends State<TeacherNoteCreationScreen> {
  final List<ClassNoteSection> _sections = [];
  
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
    
    final content = _bulletsController.text.trim();
    if (_wordCount(content) > _maxWordsPerStep) return; // Invalid
    
    if (_editingIndex != null) {
      // Update existing step
      final stepNum = _editingIndex! + 1;
      _sections[_editingIndex!] = ClassNoteSection(
        title: '$stepNum · $title',
        subtitle: _subtitleController.text.trim(),
        bullets: _parseBullets(content),
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
    
    final content = _bulletsController.text.trim();
    if (_wordCount(content) > _maxWordsPerStep) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep it concise! Limit is ~60 words.')),
      );
      return;
    }

    final newSection = ClassNoteSection(
      title: '${_sections.length + 1} · $title',
      subtitle: _subtitleController.text.trim(),
      bullets: _parseBullets(content),
    );

    setState(() {
      _sections.add(newSection);
      _titleController.clear();
      _subtitleController.clear();
      _bulletsController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
       _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    
    final content = _bulletsController.text.trim();
    if (_wordCount(content) > _maxWordsPerStep) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep it concise! Limit is ~60 words.')),
      );
      return;
    }
    
    // Save current
    final stepNum = _editingIndex! + 1;
    _sections[_editingIndex!] = ClassNoteSection(
      title: '$stepNum · $title',
      subtitle: _subtitleController.text.trim(),
      bullets: _parseBullets(content),
    );
    
    // Move to next step or new
    if (_editingIndex! < _sections.length - 1) {
      _openStepForEdit(_editingIndex! + 1);
    } else {
      _closeEditAndAddNew();
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class note created!')),
    );
     Navigator.of(context).popUntil((route) => route.isFirst);
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
                          onCancel: _closeEditAndAddNew,
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
                        onCancel: null,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Publish button
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: FilledButton(
                        onPressed: _sections.isEmpty ? null : _finish,
                        child: const Text('Publish'),
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
class _NoteEditingStep extends StatelessWidget {
  const _NoteEditingStep({
    required this.index,
    required this.isNewStep,
    required this.titleController,
    required this.subtitleController,
    required this.bulletsController,
    required this.onNext,
    this.onCancel,
  });

  final int index;
  final bool isNewStep;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController bulletsController;
  final VoidCallback onNext;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator - black filled for active
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (index != 0)
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
                  '${index + 1}',
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
                    isNewStep ? 'Step ${index + 1}' : 'Edit Step ${index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Section Heading'),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subtitleController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Subtitle (optional)'),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bulletsController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Write brief points here...\nEach line becomes a bullet.\nKeep it short (max ~60 words).',
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: onNext,
                        icon: Icon(isNewStep ? Icons.arrow_downward : Icons.check, size: 16),
                        label: Text(isNewStep ? 'Next Step' : 'Save'),
                      ),
                      if (onCancel != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onCancel,
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
