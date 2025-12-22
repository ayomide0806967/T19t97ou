part of 'aiken_import_review_screen.dart';

mixin _AikenImportReviewScreenActions on _AikenImportReviewScreenStateBase {
  bool _hasAnyQuestionContent() {
    if (_questions.isEmpty) return false;
    for (final q in _questions) {
      if (q.prompt.text.trim().isNotEmpty) return true;
      if (q.promptImage != null) return true;
      for (final opt in q.options) {
        if (opt.text.trim().isNotEmpty) return true;
      }
      if (q.optionImages.any((img) => img != null)) return true;
    }
    return false;
  }

  Future<bool> _showLeaveDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Leave without saving?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve uploaded questions from your Aiken file. '
                  'If you close now, all of these questions and any edits on this page will be lost.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true); // discard
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Discard questions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(false); // keep editing
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Keep editing',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _handleClosePressed() async {
    if (!_hasAnyQuestionContent()) {
      Navigator.of(context).pop(null);
      return;
    }

    final shouldLeave = await _showLeaveDialog();
    if (shouldLeave && mounted) {
      Navigator.of(context).pop(null);
    }
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
      final controller = _questions[questionIndex].options.removeAt(
        optionIndex,
      );
      controller.dispose();
      if (_questions[questionIndex].correctIndex >=
          _questions[questionIndex].options.length) {
        _questions[questionIndex].correctIndex =
            _questions[questionIndex].options.length - 1;
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
          _showSnack(
            'Question ${i + 1}, Option ${String.fromCharCode(65 + j)} is empty.',
          );
          return false;
        }
      }
    }
    return true;
  }

  void _confirmImport({bool importMore = false}) {
    if (!_validate()) return;
    Navigator.of(
      context,
    ).pop(AikenImportResult(questions: _questions, importMore: importMore));
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _whatsAppTeal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: _whatsAppTeal,
                        ),
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
                    _confirmImport(importMore: true);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.upload_file_rounded,
                          color: Colors.black87,
                        ),
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
}
