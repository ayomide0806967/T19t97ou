import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const Color _whatsAppTeal = Color(0xFF075E54);

/// A dedicated screen for reviewing and editing imported Aiken questions
class AikenImportReviewScreen extends StatefulWidget {
  const AikenImportReviewScreen({
    super.key,
    required this.questions,
  });

  final List<ImportedQuestion> questions;

  @override
  State<AikenImportReviewScreen> createState() => _AikenImportReviewScreenState();
}

class _AikenImportReviewScreenState extends State<AikenImportReviewScreen> {
  late List<ImportedQuestion> _questions;
  int? _expandedIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _questions = widget.questions.map((q) => q.copy()).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpand(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex].options.add(TextEditingController());
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    if (_questions[questionIndex].options.length <= 2) return;
    setState(() {
      final controller = _questions[questionIndex].options.removeAt(optionIndex);
      controller.dispose();
      if (_questions[questionIndex].correctIndex >= _questions[questionIndex].options.length) {
        _questions[questionIndex].correctIndex = _questions[questionIndex].options.length - 1;
      }
    });
  }

  void _setCorrect(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex].correctIndex = optionIndex;
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      _showSnack('You must have at least one question.');
      return;
    }
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });
  }

  void _addQuestion() {
    setState(() {
      _questions.add(ImportedQuestion.empty());
      _expandedIndex = _questions.length - 1;
    });
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickPromptImage(int questionIndex) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _questions[questionIndex].promptImage = image.path;
        });
      }
    } catch (e) {
      _showSnack('Failed to pick image');
    }
  }

  Future<void> _pickOptionImage(int questionIndex, int optionIndex) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          // Ensure optionImages list is long enough
          while (_questions[questionIndex].optionImages.length <= optionIndex) {
            _questions[questionIndex].optionImages.add(null);
          }
          _questions[questionIndex].optionImages[optionIndex] = image.path;
        });
      }
    } catch (e) {
      _showSnack('Failed to pick image');
    }
  }

  void _removePromptImage(int questionIndex) {
    setState(() {
      _questions[questionIndex].promptImage = null;
    });
  }

  void _removeOptionImage(int questionIndex, int optionIndex) {
    setState(() {
      if (optionIndex < _questions[questionIndex].optionImages.length) {
        _questions[questionIndex].optionImages[optionIndex] = null;
      }
    });
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: success ? _whatsAppTeal : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  bool _validate() {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.prompt.text.trim().isEmpty) {
        _showSnack('Question ${i + 1} needs a prompt.');
        return false;
      }
      for (int j = 0; j < q.options.length; j++) {
        if (q.options[j].text.trim().isEmpty) {
          _showSnack('Question ${i + 1}, Option ${String.fromCharCode(65 + j)} is empty.');
          return false;
        }
      }
    }
    return true;
  }

  void _confirmImport() {
    if (!_validate()) return;
    Navigator.of(context).pop(_questions);
  }

  void _showActionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 12),
                // Add question manually
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _addQuestion();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _whatsAppTeal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: _whatsAppTeal),
                        const SizedBox(width: 10),
                        const Text(
                          'Add question manually',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Import more Aiken file
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(<ImportedQuestion>[]);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file_rounded, color: Colors.black87),
                        const SizedBox(width: 10),
                        const Text(
                          'Import more Aiken file',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background = isDark ? const Color(0xFF0B0D11) : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(null),
          tooltip: 'Cancel',
        ),
        title: Text(
          'Review Imported Questions',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Summary header + search
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _whatsAppTeal, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: _whatsAppTeal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_questions.length} question${_questions.length == 1 ? '' : 's'} imported. Tap to expand and edit.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search imported questions',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          // Light grey pill for the search input itself
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(999)),
                            borderSide: BorderSide(
                              color: _whatsAppTeal,
                              width: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _confirmImport,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Questions list (filtered by search)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (() {
                final visible = List<int>.generate(_questions.length, (i) => i)
                    .where((i) {
                      if (_searchQuery.trim().isEmpty) return true;
                      final q = _questions[i];
                      final query = _searchQuery.toLowerCase();
                      final prompt = q.prompt.text.toLowerCase();
                      if (prompt.contains(query)) return true;
                      for (final opt in q.options) {
                        if (opt.text.toLowerCase().contains(query)) return true;
                      }
                      return false;
                    })
                    .toList();
                // +2 for "add question manually" and "import more"
                return visible.length + 2;
              })(),
              itemBuilder: (context, index) {
                // Recompute visible indices for this builder
                final visible = List<int>.generate(_questions.length, (i) => i)
                    .where((i) {
                      if (_searchQuery.trim().isEmpty) return true;
                      final q = _questions[i];
                      final query = _searchQuery.toLowerCase();
                      final prompt = q.prompt.text.toLowerCase();
                      if (prompt.contains(query)) return true;
                      for (final opt in q.options) {
                        if (opt.text.toLowerCase().contains(query)) return true;
                      }
                      return false;
                    })
                    .toList();

                if (index == visible.length) {
                  // Add question button
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add question manually'),
                      style: TextButton.styleFrom(
                        foregroundColor: _whatsAppTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: _whatsAppTeal.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (index == visible.length + 1) {
                  // Import more Aiken file button
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(<ImportedQuestion>[]);
                      },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Import more Aiken file'),
                      style: TextButton.styleFrom(
                        foregroundColor: _whatsAppTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: _whatsAppTeal.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final questionIndex = visible[index];
                final q = _questions[questionIndex];
                final isExpanded = _expandedIndex == questionIndex;

                return _QuestionCard(
                  index: questionIndex,
                  question: q,
                  isExpanded: isExpanded,
                  onToggleExpand: () => _toggleExpand(questionIndex),
                  onAddOption: () => _addOption(questionIndex),
                  onRemoveOption: (optIdx) => _removeOption(questionIndex, optIdx),
                  onSetCorrect: (optIdx) => _setCorrect(questionIndex, optIdx),
                  onRemove: () => _removeQuestion(questionIndex),
                  onPickPromptImage: () => _pickPromptImage(questionIndex),
                  onRemovePromptImage: () => _removePromptImage(questionIndex),
                  onPickOptionImage: (optIdx) => _pickOptionImage(questionIndex, optIdx),
                  onRemoveOptionImage: (optIdx) => _removeOptionImage(questionIndex, optIdx),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionsSheet,
        backgroundColor: _whatsAppTeal,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSetCorrect,
    required this.onRemove,
    required this.onPickPromptImage,
    required this.onRemovePromptImage,
    required this.onPickOptionImage,
    required this.onRemoveOptionImage,
  });

  final int index;
  final ImportedQuestion question;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final void Function(int) onSetCorrect;
  final VoidCallback onRemove;
  final VoidCallback onPickPromptImage;
  final VoidCallback onRemovePromptImage;
  final void Function(int) onPickOptionImage;
  final void Function(int) onRemoveOptionImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String promptText = question.prompt.text.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded
            ? (isDark ? theme.colorScheme.surface : Colors.white)
            : Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: isExpanded
            ? Border.all(color: _whatsAppTeal.withValues(alpha: 0.3))
            : null,
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded ? _whatsAppTeal : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isExpanded ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isExpanded ? theme.colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        if (promptText.isNotEmpty && !isExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            promptText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isExpanded) ...[
                    Text(
                      '${question.options.length} options',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show prompt image if exists
                  if (question.promptImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(question.promptImage!),
                            height: 90,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: onRemovePromptImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  TextField(
                    controller: question.prompt,
                    maxLines: null,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter question prompt...',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _whatsAppTeal, width: 1.5),
                      ),
                      suffixIcon: InkWell(
                        onTap: onPickPromptImage,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            question.promptImage != null
                                ? Icons.image
                                : Icons.image_outlined,
                            size: 20,
                            color: question.promptImage != null
                                ? _whatsAppTeal
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Options
                  Text(
                    'Options',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _whatsAppTeal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(question.options.length, (optIdx) {
                    final isCorrect = question.correctIndex == optIdx;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Letter indicator
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCorrect ? _whatsAppTeal : theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCorrect ? _whatsAppTeal : theme.dividerColor,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: TextStyle(
                                    color: isCorrect ? Colors.white : theme.colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Option text field
                              Expanded(
                                child: TextField(
                                  controller: question.options[optIdx],
                                  minLines: 1,
                                  maxLines: null, // auto-grow
                                  textInputAction: TextInputAction.newline,
                                  decoration: InputDecoration(
                                    hintText: 'Option ${String.fromCharCode(65 + optIdx)}',
                                    isDense: true,
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: _whatsAppTeal, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              // Actions (image, correct, remove) aligned on the right
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => onPickOptionImage(optIdx),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2, top: 4, bottom: 4),
                                      child: Icon(
                                        (optIdx < question.optionImages.length &&
                                                question.optionImages[optIdx] != null)
                                            ? Icons.image
                                            : Icons.image_outlined,
                                        size: 20,
                                        color: (optIdx < question.optionImages.length &&
                                                question.optionImages[optIdx] != null)
                                            ? _whatsAppTeal
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => onSetCorrect(optIdx),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2, top: 4, bottom: 4),
                                      child: Icon(
                                        isCorrect
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked,
                                        size: 24,
                                        color: isCorrect
                                            ? _whatsAppTeal
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  if (question.options.length > 2) ...[
                                    InkWell(
                                      onTap: () => onRemoveOption(optIdx),
                                      borderRadius: BorderRadius.circular(999),
                                      child: const Padding(
                                        padding: EdgeInsets.only(
                                          left: 2,
                                          right: 4,
                                          top: 4,
                                          bottom: 4,
                                        ),
                                        child: Icon(Icons.close_rounded, size: 22),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          // Show option image preview if exists
                          if (optIdx < question.optionImages.length &&
                              question.optionImages[optIdx] != null)
                            Column(
                              children: [
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(question.optionImages[optIdx]!),
                                          height: 48,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: InkWell(
                                          onTap: () => onRemoveOptionImage(optIdx),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                  // Bottom actions row
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: onAddOption,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add option'),
                        style: TextButton.styleFrom(
                          foregroundColor: _whatsAppTeal,
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        tooltip: 'Remove question',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Represents an imported question with editable controllers
class ImportedQuestion {
  ImportedQuestion({
    required this.prompt,
    required this.options,
    this.correctIndex = 0,
    this.promptImage,
    List<String?>? optionImages,
  }) : optionImages = optionImages ?? List.filled(options.length, null);

  factory ImportedQuestion.empty() {
    return ImportedQuestion(
      prompt: TextEditingController(),
      options: List.generate(4, (_) => TextEditingController()),
      optionImages: List.generate(4, (_) => null),
    );
  }

  final TextEditingController prompt;
  final List<TextEditingController> options;
  int correctIndex;
  String? promptImage;
  List<String?> optionImages;

  ImportedQuestion copy() {
    return ImportedQuestion(
      prompt: TextEditingController(text: prompt.text),
      options: options.map((c) => TextEditingController(text: c.text)).toList(),
      correctIndex: correctIndex,
      promptImage: promptImage,
      optionImages: List.from(optionImages),
    );
  }

  void dispose() {
    prompt.dispose();
    for (final c in options) {
      c.dispose();
    }
  }
}

/// Parses Aiken format text into a list of ImportedQuestion
/// Supports various Aiken format variations:
/// - A) B) C) D) style
/// - A. B. C. D. style
/// - a) b) c) d) lowercase
/// - With or without question numbers
/// - Multi-line questions
/// - Various ANSWER formats
List<ImportedQuestion> parseAikenQuestions(String raw) {
  final List<ImportedQuestion> result = [];
  final List<String> lines = raw.split(RegExp(r'\r?\n'));

  String? currentPrompt;
  List<String> options = [];
  String? correctLetter;

  String normalizePrompt(String text) {
    // Strip leading numbering like "1.", "Q1)", "(2)" etc, collapse spaces,
    // and lowercase so duplicates are easier to detect.
    final trimmed = text.trim();
    final withoutNumber = trimmed.replaceFirst(
      RegExp(
        r'^(?:Q(?:uestion)?\s*)?[\(\[]?\s*\d+\s*[\)\.\:\]]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    return withoutNumber.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  final Set<String> seenPrompts = {};

  void commitQuestion() {
    if (currentPrompt == null || currentPrompt!.trim().isEmpty) {
      currentPrompt = null;
      options = [];
      correctLetter = null;
      return;
    }
    // If no explicit options were parsed (very minimal formats), treat
    // the prompt itself as a single correct option so that bare
    // questions like "What is a noun?" are still imported.
    if (options.isEmpty) {
      options = [currentPrompt!.trim()];
    }

    final normalizedPrompt = normalizePrompt(currentPrompt!);
    if (normalizedPrompt.isEmpty || seenPrompts.contains(normalizedPrompt)) {
      // Skip duplicate or empty questions.
      currentPrompt = null;
      options = [];
      correctLetter = null;
      return;
    }
    seenPrompts.add(normalizedPrompt);

    // Create the question
    final q = ImportedQuestion(
      prompt: TextEditingController(text: currentPrompt!.trim()),
      options: options.map((o) => TextEditingController(text: o.trim())).toList(),
      correctIndex: 0,
    );
    
    // Set correct answer
    if (correctLetter != null) {
      const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      final idx = letters.indexOf(correctLetter!.toUpperCase());
      if (idx >= 0 && idx < options.length) {
        q.correctIndex = idx;
      }
    }
    
    // Ensure at least 2 options
    while (q.options.length < 2) {
      q.options.add(TextEditingController());
    }
    
    result.add(q);
    
    // Reset for next question
    currentPrompt = null;
    options = [];
    correctLetter = null;
  }

  // Regex patterns for various Aiken formats
  // Very forgiving answer line matcher.
  // Examples it accepts (case-insensitive, extra punctuation allowed):
  // "ANSWER: A", "Answer : a)", "ANS = c.", "KEY   B", "Correct answer: d"
  final answerRegex = RegExp(
    r'^(?:ANSWER|ANS|KEY|CORRECT(?:\s+ANSWER)?)\b.*?([A-Ha-h])[^A-Za-z0-9]*$',
    caseSensitive: false,
  );
  
  // Matches option lines like: A) text, A. text, a) text, (A) text, A: text, A - text
  final optionRegex = RegExp(
    r'^\s*[\(\[]?\s*([A-Ha-h])\s*[\)\.\:\]\-]?\s*(.+)$',
  );
  
  // Matches question numbers at start: 1. Question, 1) Question, (1) Question, Q1:, Question 1:
  final questionNumberRegex = RegExp(
    r'^\s*(?:Q(?:uestion)?\s*)?[\(\[]?\s*\d+\s*[\)\.\:\]]?\s*(.+)$',
    caseSensitive: false,
  );

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];
    String trimmedLine = line.trim();
    
    // Skip empty lines
    if (trimmedLine.isEmpty) continue;

    // Handle very simple "Q: Q" format where the prompt and correct
    // answer are the same, e.g. "What is a noun: What is a noun".
    // This is only applied when we are not already in the middle of
    // collecting a question (no currentPrompt/options yet).
    if (currentPrompt == null && options.isEmpty) {
      final int colonIndex = trimmedLine.indexOf(':');
      if (colonIndex != -1 && colonIndex < trimmedLine.length - 1) {
        final String left = trimmedLine.substring(0, colonIndex).trim();
        final String right = trimmedLine.substring(colonIndex + 1).trim();
        final String normLeft = normalizePrompt(left);
        final String normRight = normalizePrompt(right);
        if (normLeft.isNotEmpty &&
            normLeft == normRight &&
            !seenPrompts.contains(normLeft)) {
          final q = ImportedQuestion(
            prompt: TextEditingController(text: left),
            options: [
              TextEditingController(text: right),
            ],
            correctIndex: 0,
          );
          // Ensure at least 2 options for consistency with editor.
          while (q.options.length < 2) {
            q.options.add(TextEditingController());
          }
          result.add(q);
          seenPrompts.add(normLeft);
          continue;
        }
      }
    }
    
    // Check for answer line first (this commits the current question)
    final answerMatch = answerRegex.firstMatch(trimmedLine);
    if (answerMatch != null) {
      correctLetter = answerMatch.group(1)!.toUpperCase();
      commitQuestion();
      continue;
    }
    
    // Check for option line
    final optMatch = optionRegex.firstMatch(trimmedLine);
    if (optMatch != null) {
      final letter = optMatch.group(1)!.toUpperCase();
      final optionText = optMatch.group(2)!.trim();
      
      // If this looks like an option (A-H), add it
      const validLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      if (validLetters.contains(letter)) {
        // Check if this is a continuation of options or a new question
        final expectedIdx = options.length;
        final letterIdx = validLetters.indexOf(letter);
        
        // Accept if it's the expected next option OR if options is empty
        // Also accept if it seems to follow the sequence (with some tolerance)
        if (expectedIdx == letterIdx || 
            options.isEmpty || 
            (letterIdx >= expectedIdx && letterIdx <= expectedIdx + 1)) {
          options.add(optionText);
          continue;
        }
      }
    }
    
    // Check if this is a numbered question start (like "1. What is..." or "Q1: What is...")
    final numMatch = questionNumberRegex.firstMatch(trimmedLine);
    if (numMatch != null && options.isEmpty) {
      // If we have a previous question without an answer line, commit it
      if (currentPrompt != null && currentPrompt!.trim().isNotEmpty) {
        // Check if the previous content had options somehow
        // This handles files without explicit ANSWER lines
      }
      currentPrompt = numMatch.group(1)!.trim();
      continue;
    }
    
    // If we haven't started collecting options yet, this is part of the question prompt
    if (options.isEmpty) {
      if (currentPrompt == null) {
        currentPrompt = trimmedLine;
      } else {
        // Multi-line question - append with newline
        currentPrompt = '$currentPrompt\n$trimmedLine';
      }
    }
    // If we have options but no answer yet, and this doesn't match option pattern,
    // it might be continuation of the last option (rare) or we should commit and start new
  }
  
  // Commit any remaining question at the end of file
  commitQuestion();

  return result;
}
