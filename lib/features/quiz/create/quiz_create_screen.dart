import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import '../../../services/quiz_repository.dart';
import '../aiken/aiken_import_models.dart';
import '../aiken/aiken_import_review_screen.dart';
import '../dashboard/quiz_dashboard_screen.dart';
import '../drafts/quiz_drafts_screen.dart';
import '../results/quiz_results_screen.dart';
import '../take/quiz_take_screen.dart';

import '../ui/quiz_palette.dart';
import '../ui/quiz_labeled_field.dart';
import 'models/quiz_question_fields.dart';
import 'import/pdf_text_extractor.dart';
import 'import/word_text_extractor.dart';

part 'quiz_create_screen_cards.dart';
part 'quiz_create_screen_steps.dart';

enum QuizVisibility { everyone, followers }
enum _QuizBuildMode { manual, aiken }

/// Revamped Quiz Creation Screen with rail-based vertical stepper
/// Design inspired by the note creation flow
class QuizCreateScreen extends StatefulWidget {
  const QuizCreateScreen({
    super.key,
    this.returnToCallerOnPublish = false,
    this.initialTitle,
    this.initialQuestions,
  });

  final bool returnToCallerOnPublish;
  final String? initialTitle;
  final List<QuizTakeQuestion>? initialQuestions;

  @override
  State<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

class _QuizCreateScreenState extends State<QuizCreateScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Which step is currently being edited
  // 0 = Details, 1 = Settings, 2 = Question setup, 3+ = Questions
  int _activeStep = 0;
  
  // Controllers for Details step
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Settings step state
  bool _isTimed = true;
  double _timeLimitMinutes = 20;
  bool _hasDeadline = false;
  DateTime? _closingDate;
  int? _attemptLimit;
  bool _requiresPin = false;
  final TextEditingController _timeLimitController = TextEditingController(text: '20');
  final TextEditingController _pinController = TextEditingController();
  QuizVisibility _visibility = QuizVisibility.everyone;
  _QuizBuildMode _buildMode = _QuizBuildMode.manual;
  
  // Questions
  final List<QuizQuestionFields> _questions = <QuizQuestionFields>[];
  
  // Track which steps have been completed
  bool _detailsCompleted = false;
  bool _settingsCompleted = false;
  bool _questionSetupCompleted = false;

  // Keys for scrolling/focusing specific steps
  final GlobalKey _detailsStepKey = GlobalKey();
  final GlobalKey _settingsStepKey = GlobalKey();
  final GlobalKey _setupStepKey = GlobalKey();
  final GlobalKey _firstQuestionStepKey = GlobalKey();
  final List<GlobalKey> _questionStepKeys = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null &&
        widget.initialTitle!.trim().isNotEmpty) {
      _titleController.text = widget.initialTitle!.trim();
      _detailsCompleted = true;
    }
    if (widget.initialQuestions != null &&
        widget.initialQuestions!.isNotEmpty) {
      for (final QuizTakeQuestion q in widget.initialQuestions!) {
        final fields = QuizQuestionFields();
        fields.prompt.text = q.prompt;
        for (int i = 0;
            i < fields.options.length && i < q.options.length;
            i++) {
          fields.options[i].text = q.options[i];
        }
        if (q.answerIndex >= 0 &&
            q.answerIndex < fields.options.length) {
          fields.correctIndex = q.answerIndex;
        } else {
          fields.correctIndex = 0;
        }
        _questions.add(fields);
        _questionStepKeys.add(GlobalKey());
      }
      _detailsCompleted = true;
      _settingsCompleted = true;
      _questionSetupCompleted = true;
      _activeStep = 3;
    } else {
      _questions.add(QuizQuestionFields());
      _questionStepKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _pinController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }
  
  void _scrollToStep(int stepIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estimatedPosition = stepIndex * 200.0;
      _scrollController.animateTo(
        estimatedPosition.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

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

  Future<void> _importQuestionsFromAiken({List<ImportedQuestion>? accumulated}) async {
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
      final AikenImportResult? reviewResult =
          await Navigator.of(context).push<AikenImportResult>(
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
            _questions.first.options.every(
              (c) => c.text.trim().isEmpty,
            ) &&
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
          final int targetIndex =
              _questions.isNotEmpty ? _questions.length - 1 : 0;
          final GlobalKey key = targetIndex < _questionStepKeys.length
              ? _questionStepKeys[targetIndex]
              : _questionStepKeys.last;
          _scrollToCenter(key);
        } else {
          _scrollToCenter(_firstQuestionStepKey);
        }
      });
      _showSnack('Imported ${imported.length} questions from Aiken file.',
          success: true);
    } catch (e) {
      _showSnack('Failed to import Aiken file: ${e.toString()}');
    }
  }

  Future<void> _pickDeadline() async {
    final BuildContext ctx = context;
    final now = DateTime.now();
    final DateTime initialDate = _closingDate ?? now.add(const Duration(days: 1));
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
      final List<String> options =
          q.options.map((c) => c.text.trim()).toList();
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

    final shareMessage = 'I just created a new quiz: "$title". '
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
      MaterialPageRoute(
        builder: (_) => const QuizResultsScreen(),
      ),
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

  Future<void> _openDrafts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizDraftsScreen()),
    );
    setState(() {});
  }

  Future<void> _openResults() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizResultsScreen()),
    );
  }

  Future<void> _openQuizPreview() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Preview quiz'
        : _titleController.text.trim();
    final description = _descriptionController.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizTakeScreen(
          title: title,
          subtitle: description.isEmpty ? null : description,
        ),
      ),
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Create Quiz',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: const [],
      ),
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
                    // Step 1: Details
                    if (_activeStep == 0)
                      _DetailsEditingStep(
                        key: _detailsStepKey,
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        onNext: _completeDetailsAndNext,
                      )
                    else
                      _CompletedStepCard(
                        key: _detailsStepKey,
                        index: 0,
                        title: 'Details',
                        subtitle: _titleController.text.trim().isNotEmpty 
                            ? _titleController.text.trim()
                            : 'Quiz title and description',
                        isActive: false,
                        onTap: _editDetailsStep,
                      ),
                    const SizedBox(height: 16),
                    
                    // Step 2: Settings
                    if (_activeStep == 1)
                      _SettingsEditingStep(
                        key: _settingsStepKey,
                        isTimed: _isTimed,
                        timeLimitController: _timeLimitController,
                        hasDeadline: _hasDeadline,
                        closingDate: _closingDate,
                        attemptLimit: _attemptLimit,
                        requiresPin: _requiresPin,
                        pinController: _pinController,
                        onTimedChanged: (v) => setState(() {
                          _isTimed = v;
                          if (v &&
                              _timeLimitController.text.trim().isEmpty) {
                            _timeLimitController.text = '20';
                          }
                        }),
                        onTimeLimitChanged: (v) => setState(() {
                          _timeLimitMinutes = v.clamp(0, 360).toDouble();
                        }),
                        onDeadlineChanged: (v) => setState(() {
                          _hasDeadline = v;
                          if (!v) _closingDate = null;
                        }),
                        onPickDeadline: _pickDeadline,
                        onAttemptsChanged: (v) =>
                            setState(() => _attemptLimit = v),
                        onRequirePinChanged: (v) => setState(() {
                          _requiresPin = v;
                          if (!v) _pinController.clear();
                        }),
                        onNext: _completeSettingsAndNext,
                        onBack: _editDetailsStep,
                      )
                    else if (_detailsCompleted)
                      _CompletedStepCard(
                        index: 1,
                        title: 'Settings',
                        subtitle: _settingsCompleted 
                            ? '${_isTimed ? "${_timeLimitMinutes.round()} min" : "No timer"}${_hasDeadline ? " · Deadline set" : ""}'
                            : 'Timer, deadline, and access',
                        isActive: false,
                        onTap: _editSettingsStep,
                      )
                    else
                      _LockedStepCard(
                        index: 1,
                        title: 'Settings',
                        subtitle: 'Complete details first',
                      ),
                    const SizedBox(height: 16),

                    // Step 3: Question setup (Manual vs Aiken)
                    if (_settingsCompleted) ...[
                      if (_activeStep == 2)
                        _QuestionSetupStep(
                          key: _setupStepKey,
                          mode: _buildMode,
                          onManualSelected: _startManualQuestionSetup,
                          onAikenSelected: _importQuestionsFromAiken,
                          onBack: _editSettingsStep,
                        )
                      else if (_questionSetupCompleted)
                        _CompletedStepCard(
                          index: 2,
                          title: 'Question setup',
                          subtitle: _buildMode == _QuizBuildMode.manual
                              ? 'Write questions manually'
                              : 'Imported from Aiken file',
                          isActive: false,
                          onTap: _editSetupStep,
                        )
                      else
                        _LockedStepCard(
                          index: 2,
                          title: 'Question setup',
                          subtitle: 'Choose how to add questions',
                        ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Step 4+: Questions
                    if (_questionSetupCompleted) ...[
                      for (int i = 0; i < _questions.length; i++) ...[
                    if (_activeStep == 3 + i)
                      _QuestionEditingStep(
                        key: i < _questionStepKeys.length ? _questionStepKeys[i] : null,
                        index: i,
                        question: _questions[i],
                        canRemove: _questions.length > 1,
                        onAddOption: () => _addOption(i),
                        onRemoveOption: (optIdx) => _removeOption(i, optIdx),
                        onSetCorrect: (optIdx) => _setCorrectOption(i, optIdx),
                        onRemove: () => _removeQuestion(i),
                        onPickPromptImage: (idx) => _pickPromptImage(idx),
                        onRemovePromptImage: (idx) => _removePromptImage(idx),
                        onPickOptionImage: (qIdx, optIdx) => _pickOptionImage(qIdx, optIdx),
                        onRemoveOptionImage: (qIdx, optIdx) => _removeOptionImage(qIdx, optIdx),
                        onOptionChanged: () => setState(() {}),
                        onDone: () {
                          // Move to next question or stay
                          if (i < _questions.length - 1) {
                            _editQuestion(i + 1);
                          }
                            },
                          )
                        else
                          _CompletedQuestionCard(
                            key: i < _questionStepKeys.length ? _questionStepKeys[i] : null,
                            index: i,
                            question: _questions[i],
                            onTap: () => _editQuestion(i),
                          ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Add question button
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: TextButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add another question'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ] else if (_detailsCompleted) ...[
                      _LockedStepCard(
                        index: 3,
                        title: 'Questions',
                        subtitle: 'Complete setup first',
                      ),
                    ] else ...[
                      _LockedStepCard(
                        index: 3,
                        title: 'Questions',
                        subtitle: 'Complete previous steps',
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Bottom action bar
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _saveDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: quizWhatsAppTeal),
                  foregroundColor: quizWhatsAppTeal,
                ),
                child: const Text('Save draft'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                            onPressed: _publishQuiz,
                            icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Publish'),
                style: FilledButton.styleFrom(
                  backgroundColor: quizWhatsAppTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100),
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
