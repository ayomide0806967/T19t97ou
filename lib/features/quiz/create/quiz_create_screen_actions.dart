part of 'quiz_create_screen.dart';

mixin _QuizCreateScreenActions on _QuizCreateScreenStateBase {
  void _scrollToCenter(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.4, // roughly center of the screen
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _completeDetailsAndNext() {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Give your quiz a title to continue.');
      return;
    }
    setState(() {
      _detailsCompleted = true;
      _activeStep = 1;
    });
    _scrollToCenter(_settingsStepKey);
  }

  void _completeSettingsAndNext() {
    if (_isTimed && _timeLimitMinutes < 1) {
      _showSnack('Set a timer of at least 1 minute.');
      return;
    }
    if (_hasDeadline) {
      if (_closingDate == null) {
        _showSnack('Choose when the quiz should close.');
        return;
      }
      if (_closingDate!.isBefore(DateTime.now())) {
        _showSnack('Closing time must be in the future.');
        return;
      }
    }
    if (_requiresPin && (_pinController.text.trim().length < 4)) {
      _showSnack('PIN must be at least 4 digits.');
      return;
    }
    setState(() {
      _settingsCompleted = true;
      _activeStep = 2;
    });
    _scrollToCenter(_setupStepKey);
  }

  void _editDetailsStep() {
    setState(() => _activeStep = 0);
    _scrollToCenter(_detailsStepKey);
  }

  void _editSettingsStep() {
    setState(() => _activeStep = 1);
    _scrollToCenter(_settingsStepKey);
  }

  void _editSetupStep() {
    if (!_settingsCompleted) return;
    setState(() => _activeStep = 2);
    _scrollToCenter(_setupStepKey);
  }

  void _editQuestion(int index) {
    setState(() => _activeStep = 3 + index);
    if (index < _questionStepKeys.length) {
      _scrollToCenter(_questionStepKeys[index]);
    }
  }

  void _addQuestion() {
    final newKey = GlobalKey();
    setState(() {
      _questions.add(QuizQuestionFields());
      _questionStepKeys.add(newKey);
      _activeStep = 3 + _questions.length - 1;
    });
    // Wait for the next frame to ensure the widget is built with the new key
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Then scroll to center
      _scrollToCenter(newKey);
    });
    _showSnack('Question ${_questions.length} added', success: true);
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
      if (_activeStep > 3 + _questions.length - 1) {
        _activeStep = 3 + _questions.length - 1;
      }
    });
  }

  void _addOption(int questionIndex) {
    final question = _questions[questionIndex];
    setState(() {
      question.options.add(TextEditingController());
      question.optionImages.add(null);
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    final question = _questions[questionIndex];
    if (question.options.length <= 2) return;
    setState(() {
      final controller = question.options.removeAt(optionIndex);
      controller.dispose();
      if (optionIndex < question.optionImages.length) {
        question.optionImages.removeAt(optionIndex);
      }
      if (question.correctIndex >= question.options.length) {
        question.correctIndex = question.options.length - 1;
      }
    });
  }

  void _setCorrectOption(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex].correctIndex = optionIndex;
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

  void _removePromptImage(int questionIndex) {
    setState(() {
      _questions[questionIndex].promptImage = null;
    });
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
          final question = _questions[questionIndex];
          while (question.optionImages.length <= optionIndex) {
            question.optionImages.add(null);
          }
          question.optionImages[optionIndex] = image.path;
        });
      }
    } catch (e) {
      _showSnack('Failed to pick image');
    }
  }

  void _removeOptionImage(int questionIndex, int optionIndex) {
    setState(() {
      final question = _questions[questionIndex];
      if (optionIndex < question.optionImages.length) {
        question.optionImages[optionIndex] = null;
      }
    });
  }

  void _startManualQuestionSetup() {
    if (!_settingsCompleted) return;
    setState(() {
      _buildMode = _QuizBuildMode.manual;
      _questionSetupCompleted = true;
      if (_questions.isEmpty) {
        _questions.add(QuizQuestionFields());
      }
      _activeStep = 3;
    });
    _scrollToCenter(_firstQuestionStepKey);
  }

  Future<void> _importQuestionsFromAiken({
    List<ImportedQuestion>? accumulated,
  }) async {
    if (!_settingsCompleted) return;
    try {
      // Prompts that already exist in the quiz builder
      final Set<String> existingPrompts = _questions
          .map((q) => normalizeAikenPrompt(q.prompt.text))
          .where((t) => t.isNotEmpty)
          .toSet();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'docx', 'doc', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showSnack('Selected file has no readable data.');
        return;
      }

      String content;
      final extension = file.extension?.toLowerCase() ?? '';

      if (extension == 'docx' || extension == 'doc') {
        // Extract text from Word document
        try {
          content = extractTextFromWord(bytes);
        } catch (e) {
          _showSnack('Failed to read Word document. Try a .txt file.');
          return;
        }
      } else if (extension == 'pdf') {
        // Extract text from PDF document
        try {
          content = extractTextFromPdf(bytes);
        } catch (e) {
          _showSnack('Failed to read PDF. Try a .txt file.');
          return;
        }
      } else {
        // Plain text file
        content = utf8.decode(bytes);
      }

      final List<ImportedQuestion> parsed = parseAikenQuestions(content);

      if (parsed.isEmpty && (accumulated == null || accumulated.isEmpty)) {
        _showSnack('No valid questions found in the Aiken file.');
        return;
      }

      // Combine any previously imported (but not yet applied) questions
      // with the newly parsed ones, while removing duplicates across
      // all sources (existing quiz + accumulated + this file).
      final List<ImportedQuestion> combined = [
        if (accumulated != null) ...accumulated,
      ];
      final Set<String> seenCombined = {
        for (final iq in combined) normalizeAikenPrompt(iq.prompt.text),
        ...existingPrompts,
      };
      for (final iq in parsed) {
        final normalized = normalizeAikenPrompt(iq.prompt.text);
        if (normalized.isEmpty || seenCombined.contains(normalized)) {
          iq.dispose();
          continue;
        }
        seenCombined.add(normalized);
        combined.add(iq);
      }

      if (combined.isEmpty) {
        _showSnack('All imported questions were duplicates of existing ones.');
        return;
      }

      // Navigate to review screen
      if (!mounted) return;
      final AikenImportResult? reviewResult = await Navigator.of(context)
          .push<AikenImportResult>(
            MaterialPageRoute(
              builder: (_) => AikenImportReviewScreen(questions: combined),
            ),
          );

      // If user cancelled, dispose any combined questions and return
      if (reviewResult == null) {
        for (final iq in combined) {
          iq.dispose();
        }
        return;
      }

      // If user chose "Import more Aiken file", recurse with the
      // edited questions so far (they stay visible on the next review).
      if (reviewResult.importMore) {
        await _importQuestionsFromAiken(accumulated: reviewResult.questions);
        return;
      }

      // Filter out duplicates again against the quiz questions at the
      // moment of final confirmation, and de-duplicate inside the
      // reviewed list itself.
      final List<ImportedQuestion> uniqueReviewed = [];
      final Set<String> seenInImport = {};
      final Set<String> finalExistingPrompts = _questions
          .map((q) => normalizeAikenPrompt(q.prompt.text))
          .where((t) => t.isNotEmpty)
          .toSet();
      for (final iq in reviewResult.questions) {
        final normalized = normalizeAikenPrompt(iq.prompt.text);
        if (normalized.isEmpty ||
            finalExistingPrompts.contains(normalized) ||
            seenInImport.contains(normalized)) {
          iq.dispose();
          continue;
        }
        seenInImport.add(normalized);
        uniqueReviewed.add(iq);
      }

      if (uniqueReviewed.isEmpty) {
        _showSnack('All imported questions were duplicates of existing ones.');
        return;
      }

      // Convert ImportedQuestion to QuizQuestionFields
      final List<QuizQuestionFields> imported = [];
      for (final iq in uniqueReviewed) {
        final q = QuizQuestionFields();
        q.prompt.text = iq.prompt.text;
        q.promptImage = iq.promptImage;

        // Clear default options and add imported ones
        for (final c in q.options) {
          c.dispose();
        }
        q.options.clear();
        q.optionImages
          ..clear()
          ..addAll(iq.optionImages);
        for (final opt in iq.options) {
          q.options.add(TextEditingController(text: opt.text));
        }
        q.correctIndex = iq.correctIndex;
        imported.add(q);

        // Dispose the ImportedQuestion
        iq.dispose();
      }

      setState(() {
        // If we still only have the initial empty placeholder question
        // (no prompt text and default options), clear it so imported
        // questions become the only ones shown.
        if (_questions.length == 1 &&
            _questions.first.prompt.text.trim().isEmpty &&
            _questions.first.options.every((c) => c.text.trim().isEmpty) &&
            _questions.first.promptImage == null &&
            _questions.first.optionImages.every((img) => img == null)) {
          _questions.first.dispose();
          _questions.clear();
          _questionStepKeys.clear();
        }

        _questions.addAll(imported);
        // Ensure we have keys for all questions (existing + newly imported).
        while (_questionStepKeys.length < _questions.length) {
          _questionStepKeys.add(GlobalKey());
        }
        _buildMode = _QuizBuildMode.aiken;
        _questionSetupCompleted = true;
        // Keep all question cards collapsed after import.
        _activeStep = 0;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_questionStepKeys.isNotEmpty) {
          final int targetIndex = _questions.isNotEmpty
              ? _questions.length - 1
              : 0;
          final GlobalKey key = targetIndex < _questionStepKeys.length
              ? _questionStepKeys[targetIndex]
              : _questionStepKeys.last;
          _scrollToCenter(key);
        } else {
          _scrollToCenter(_firstQuestionStepKey);
        }
      });
      _showSnack(
        'Imported ${imported.length} questions from Aiken file.',
        success: true,
      );
    } catch (e) {
      _showSnack('Failed to import Aiken file: ${e.toString()}');
    }
  }

  Future<void> _pickDeadline() async {
    final BuildContext ctx = context;
    final now = DateTime.now();
    final DateTime initialDate =
        _closingDate ?? now.add(const Duration(days: 1));
    final DateTime? pickedDate = await showDatePicker(
      context: ctx,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    if (!ctx.mounted) return;

    final TimeOfDay initialTime = _closingDate != null
        ? TimeOfDay.fromDateTime(_closingDate!)
        : const TimeOfDay(hour: 9, minute: 0);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: ctx,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;
    if (!ctx.mounted) return;

    setState(() {
      _closingDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  bool _validateQuestions() {
    if (_questions.isEmpty) {
      _showSnack('Add at least one question before publishing.');
      return false;
    }
    for (final question in _questions) {
      if (question.prompt.text.trim().isEmpty) {
        _showSnack('Every question needs a prompt.');
        return false;
      }
      for (final option in question.options) {
        if (option.text.trim().isEmpty) {
          _showSnack('Fill out each option to keep the quiz complete.');
          return false;
        }
      }
    }
    return true;
  }

  void _publishQuiz() async {
    if (!_detailsCompleted) {
      _showSnack('Complete the details step first.');
      return;
    }
    if (!_settingsCompleted) {
      _showSnack('Complete the settings step first.');
      return;
    }
    if (!_validateQuestions()) return;

    final title = _titleController.text.trim().isEmpty
        ? 'Untitled quiz'
        : _titleController.text.trim();
    final List<QuizTakeQuestion> takeQuestions = _questions.map((q) {
      final prompt = q.prompt.text.trim();
      final List<String> options = q.options.map((c) => c.text.trim()).toList();
      int answerIndex = q.correctIndex;
      if (options.isEmpty) {
        // Should not happen due to validation, but keep safe.
        options.addAll(['Option A', 'Option B']);
        answerIndex = 0;
      } else if (answerIndex < 0 || answerIndex >= options.length) {
        answerIndex = 0;
      }
      return QuizTakeQuestion(
        prompt: prompt,
        options: options,
        answerIndex: answerIndex,
      );
    }).toList();

    QuizRepository.recordPublishedQuiz(title: title, questions: takeQuestions);

    // If we were launched from the note-creation flow, just return
    // the title to the caller without sharing or navigating.
    if (widget.returnToCallerOnPublish) {
      if (!mounted) return;
      Navigator.of(context).pop<String>(title);
      return;
    }

    final shareMessage =
        'I just created a new quiz: "$title". '
        'Tap to try it and test your knowledge.';
    bool shareSupported = true;
    try {
      await Share.share(shareMessage, subject: 'New quiz: $title');
    } catch (e) {
      shareSupported = false;
    }

    if (!mounted) return;

    if (widget.returnToCallerOnPublish) {
      Navigator.of(context).pop<String>(title);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const QuizResultsScreen()),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSnack(
        shareSupported
            ? 'Quiz published and ready to share.'
            : 'Quiz published, but sharing isn\'t available on this device.',
        success: true,
      );
    });
  }

  void _showSnack(String message, {bool success = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: success ? quizWhatsAppTeal : const Color(0xFFDC2626),
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

  void _saveDraft() {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled quiz'
        : _titleController.text.trim();
    final draft = QuizDraft(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      updatedAt: DateTime.now(),
      questionCount: _questions.length,
      isTimed: _isTimed,
      timerMinutes: _isTimed ? (_timeLimitMinutes.clamp(1, 360).round()) : null,
      closingDate: _hasDeadline ? _closingDate : null,
      requirePin: _requiresPin,
      pin: _requiresPin ? _pinController.text.trim() : null,
      visibility: _visibility.name,
    );
    QuizRepository.saveDraft(draft);
    _showSnack('Draft saved', success: true);
  }
}
