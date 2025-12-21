import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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
import 'models/quiz_question_fields.dart';

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
      String normalizePrompt(String text) {
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

      // Prompts that already exist in the quiz builder
      final Set<String> existingPrompts = _questions
          .map((q) => normalizePrompt(q.prompt.text))
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
          content = docxToText(bytes);
        } catch (e) {
          _showSnack('Failed to read Word document. Try a .txt file.');
          return;
        }
      } else if (extension == 'pdf') {
        // Extract text from PDF document
        try {
          content = _extractTextFromPdf(bytes);
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
        for (final iq in combined) normalizePrompt(iq.prompt.text),
        ...existingPrompts,
      };
      for (final iq in parsed) {
        final normalized = normalizePrompt(iq.prompt.text);
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
          .map((q) => normalizePrompt(q.prompt.text))
          .where((t) => t.isNotEmpty)
          .toSet();
      for (final iq in reviewResult.questions) {
        final normalized = normalizePrompt(iq.prompt.text);
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

  String _extractTextFromPdf(Uint8List bytes) {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
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

// ============================================================================
// HERO BANNER
// ============================================================================

class _QuizHeroBanner extends StatelessWidget {
  const _QuizHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Create Quiz',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Craft a quiz that keeps your cohort sharp.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Break complex cases into quick checks and monitor understanding in real time.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPLETED STEP CARD (Collapsed)
// ============================================================================

class _CompletedStepCard extends StatelessWidget {
  const _CompletedStepCard({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool isActive;
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
                  child: Icon(Icons.check, size: 14, color: Colors.black),
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
              color: quizWhatsAppGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: quizWhatsAppTeal.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${index + 1} · $title',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

// ============================================================================
// LOCKED STEP CARD (Not yet accessible)
// ============================================================================

class _LockedStepCard extends StatelessWidget {
  const _LockedStepCard({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator - gray outline
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (index != 0)
                Container(width: 1, height: 8, color: Colors.black26),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: Colors.black26),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content panel
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: quizWhatsAppGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: quizWhatsAppTeal.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${index + 1} · $title',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DETAILS EDITING STEP
// ============================================================================

class _DetailsEditingStep extends StatelessWidget {
  const _DetailsEditingStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.onNext,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator - black filled for active
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(width: 2, height: 8, color: Colors.black),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
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
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 1 · Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: quizWhatsAppTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Give your quiz a name and context',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Title',
                  hintText: 'Cardiology round recap quiz',
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  backgroundColor: theme.colorScheme.surface,
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Description',
                  hintText: 'Give learners context or expectations for this quiz.',
                  controller: descriptionController,
                  maxLines: 3,
                  autoExpand: true,
                  backgroundColor: theme.colorScheme.surface,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: quizWhatsAppTeal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SETTINGS EDITING STEP
// ============================================================================

class _SettingsEditingStep extends StatelessWidget {
  const _SettingsEditingStep({
    super.key,
    required this.isTimed,
    required this.timeLimitController,
    required this.hasDeadline,
    required this.closingDate,
    required this.attemptLimit,
    required this.requiresPin,
    required this.pinController,
    required this.onTimedChanged,
    required this.onTimeLimitChanged,
    required this.onDeadlineChanged,
    required this.onPickDeadline,
    required this.onAttemptsChanged,
    required this.onRequirePinChanged,
    required this.onNext,
    required this.onBack,
  });

  final bool isTimed;
  final TextEditingController timeLimitController;
  final bool hasDeadline;
  final DateTime? closingDate;
  final int? attemptLimit;
  final bool requiresPin;
  final TextEditingController pinController;
  final ValueChanged<bool> onTimedChanged;
  final ValueChanged<double> onTimeLimitChanged;
  final ValueChanged<bool> onDeadlineChanged;
  final Future<void> Function() onPickDeadline;
  final ValueChanged<int?> onAttemptsChanged;
  final ValueChanged<bool> onRequirePinChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    String deadlineLabel;
    if (!hasDeadline || closingDate == null) {
      deadlineLabel = 'Set closing time';
    } else {
      final date = localizations.formatMediumDate(closingDate!);
      final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(closingDate!));
      deadlineLabel = '$date · $time';
    }

    final List<DropdownMenuItem<int?>> attemptItems = [
      const DropdownMenuItem<int?>(value: null, child: Text('Unlimited')),
      ...[1, 2, 3, 5].map(
        (value) => DropdownMenuItem<int?>(
          value: value,
          child: Text('$value attempt${value == 1 ? '' : 's'}'),
        ),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(width: 2, height: 8, color: Colors.black),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 2 · Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure timer, deadline, and access',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Timed quiz
                SwitchListTile.adaptive(
                  value: isTimed,
                  onChanged: onTimedChanged,
                  title: const Text('Timed quiz'),
                  subtitle: const Text('Set a time limit'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      final bool selected = states.contains(WidgetState.selected);
                      return selected ? Colors.white : Colors.black;
                    },
                  ),
                ),
                if (isTimed) ...[
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final int currentMinutes =
                          int.tryParse(timeLimitController.text) ?? 20;
                      final int hours = currentMinutes ~/ 60;
                      final int minutes = currentMinutes % 60;
                      final String durationLabel = hours > 0
                          ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
                          : '$minutes min';

                      Future<void> openTimerPicker() async {
                        Duration selected =
                            Duration(minutes: currentMinutes.clamp(1, 360));
                        await showModalBottomSheet<void>(
                          context: context,
                          useSafeArea: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (ctx, setModalState) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Timer duration',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 200,
                                        child: CupertinoTimerPicker(
                                          mode: CupertinoTimerPickerMode.hm,
                                          initialTimerDuration: selected,
                                          onTimerDurationChanged: (duration) {
                                            setModalState(
                                                () => selected = duration);
                                            final int mins = duration
                                                .inMinutes
                                                .clamp(1, 360);
                                            timeLimitController.text =
                                                mins.toString();
                                            onTimeLimitChanged(
                                                mins.toDouble());
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () async {
                                            final int initialHours =
                                                selected.inHours;
                                            final int initialMinutes =
                                                selected.inMinutes % 60;
                                            final TextEditingController
                                                hoursController =
                                                TextEditingController(
                                                    text: initialHours
                                                        .toString());
                                            final TextEditingController
                                                minutesController =
                                                TextEditingController(
                                                    text: initialMinutes
                                                        .toString());

                                            final Duration? manualResult =
                                                await showDialog<Duration>(
                                              context: ctx,
                                              builder: (dialogCtx) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: const Text(
                                                      'Set duration manually'),
                                                  content: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 100,
                                                        child: TextField(
                                                          controller:
                                                              hoursController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter
                                                                .digitsOnly,
                                                            LengthLimitingTextInputFormatter(
                                                                3),
                                                          ],
                                                          decoration:
                                                              InputDecoration(
                                                            labelText: 'HOUR',
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      SizedBox(
                                                        width: 100,
                                                        child: TextField(
                                                          controller:
                                                              minutesController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter
                                                                .digitsOnly,
                                                            LengthLimitingTextInputFormatter(
                                                                2),
                                                          ],
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'MINUTE',
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                                  dialogCtx)
                                                              .pop(),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        final int h =
                                                            int.tryParse(
                                                                    hoursController
                                                                        .text) ??
                                                                0;
                                                        final int m =
                                                            int.tryParse(
                                                                    minutesController
                                                                        .text) ??
                                                                0;
                                                        int total =
                                                            h * 60 + m;
                                                        if (total < 1) {
                                                          total = 1;
                                                        }
                                                        if (total > 360) {
                                                          total = 360;
                                                        }
                                                        Navigator.of(
                                                                dialogCtx)
                                                            .pop(Duration(
                                                                minutes:
                                                                    total));
                                                      },
                                                      child:
                                                          const Text('Apply'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (manualResult != null) {
                                              setModalState(() {
                                                selected = manualResult;
                                              });
                                              final int mins = manualResult
                                                  .inMinutes
                                                  .clamp(1, 360);
                                              timeLimitController.text =
                                                  mins.toString();
                                              onTimeLimitChanged(
                                                  mins.toDouble());
                                            }
                                          },
                                          child: const Text('Set manually'),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Done'),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }

                      return OutlinedButton(
                        onPressed: openTimerPicker,
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(durationLabel),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 8),
                
                // Deadline
                SwitchListTile.adaptive(
                  value: hasDeadline,
                  onChanged: onDeadlineChanged,
                  title: const Text('Close automatically'),
                  subtitle: const Text('Set a deadline'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      final bool selected = states.contains(WidgetState.selected);
                      return selected ? Colors.white : Colors.black;
                    },
                  ),
                ),
                if (hasDeadline) ...[
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: onPickDeadline,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(deadlineLabel),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Attempts
                Text(
                  'Attempts allowed',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: attemptLimit,  // Using 'value' is fine for this use case
                  items: attemptItems,
                  onChanged: onAttemptsChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                // PIN
                SwitchListTile.adaptive(
                  value: requiresPin,
                  onChanged: onRequirePinChanged,
                  title: const Text('Require PIN'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      final bool selected = states.contains(WidgetState.selected);
                      return selected ? Colors.white : Colors.black;
                    },
                  ),
                ),
                if (requiresPin) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: pinController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'PIN (4-6 digits)',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: outline),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: quizWhatsAppTeal,
                      ),
                      child: const Text('Back'),
                    ),
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Next'),
                      style: FilledButton.styleFrom(
                        backgroundColor: quizWhatsAppTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUESTION SETUP STEP (Manual vs Aiken)
// ============================================================================

class _QuestionSetupStep extends StatelessWidget {
  const _QuestionSetupStep({
    super.key,
    required this.mode,
    required this.onManualSelected,
    required this.onAikenSelected,
    required this.onBack,
  });

  final _QuizBuildMode mode;
  final VoidCallback onManualSelected;
  final Future<void> Function() onAikenSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(width: 2, height: 8, color: Colors.black),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 3 · Question setup',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to add questions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onManualSelected,
                  icon: Icon(
                    Icons.edit_note_rounded,
                    color: mode == _QuizBuildMode.manual
                        ? quizWhatsAppTeal
                        : Colors.black,
                  ),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manual quiz setup',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Write questions directly in the app.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    side: BorderSide(
                      color: Colors.black,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onAikenSelected,
                  icon: Icon(
                    Icons.upload_file_rounded,
                    color: mode == _QuizBuildMode.aiken
                        ? quizWhatsAppTeal
                        : Colors.black,
                  ),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Import Aiken file',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload a .txt file in Aiken format.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    side: BorderSide(
                      color: Colors.black,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: quizWhatsAppTeal,
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mode == _QuizBuildMode.aiken
                            ? 'Imported questions will appear next.'
                            : 'You\'ll write questions in the next step.',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUESTION EDITING STEP
// ============================================================================

class _QuestionEditingStep extends StatelessWidget {
  const _QuestionEditingStep({
    super.key,
    required this.index,
    required this.question,
    required this.canRemove,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSetCorrect,
    required this.onRemove,
    required this.onPickPromptImage,
    required this.onRemovePromptImage,
    required this.onPickOptionImage,
    required this.onRemoveOptionImage,
    required this.onDone,
    required this.onOptionChanged,
  });

  final int index;
  final QuizQuestionFields question;
  final bool canRemove;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final void Function(int) onSetCorrect;
  final VoidCallback onRemove;
  final VoidCallback onDone;
  final void Function(int) onPickPromptImage;
  final void Function(int) onRemovePromptImage;
  final void Function(int, int) onPickOptionImage;
  final void Function(int, int) onRemoveOptionImage;
  final VoidCallback onOptionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        SizedBox(
          width: 24,
          child: Column(
            children: [
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
                  '${index + 4}',
                  style: const TextStyle(
                    color: Colors.white,
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Multiple choice',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canRemove)
                      IconButton(
                        tooltip: 'Remove question',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: onRemove,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Prompt image preview (shown above the prompt box)
                if (question.promptImage != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(question.promptImage!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => onRemovePromptImage(index),
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
                  const SizedBox(height: 8),
                ],
                
                // Prompt (no label, icon inside field)
                _LabeledField(
                  label: '',
                  hintText: 'What parameter best reflects cardiac output?',
                  controller: question.prompt,
                  maxLines: 2,
                  autoExpand: true,
                  backgroundColor: theme.colorScheme.surface,
                  suffixIcon: InkWell(
                    onTap: () => onPickPromptImage(index),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        question.promptImage != null
                            ? Icons.image
                            : Icons.image_outlined,
                        size: 20,
                        color: question.promptImage != null
                            ? quizWhatsAppTeal
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Options
                ...List.generate(question.options.length, (optionIndex) {
                  final optionController = question.options[optionIndex];
                  final bool canRemoveOption = question.options.length > 2;
                  final bool hasOptionText =
                      optionController.text.trim().isNotEmpty;

                  return Column(
                    children: [
                      // Option image preview (shown above the option row)
                      if (optionIndex < question.optionImages.length &&
                          question.optionImages[optionIndex] != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 32, top: 4, right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(question.optionImages[optionIndex]!),
                                  height: 60,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () =>
                                      onRemoveOptionImage(index, optionIndex),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Option letter pill (A, B, C, D) that highlights
                            // when this option is marked as correct.
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: question.correctIndex == optionIndex
                                    ? quizWhatsAppTeal
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: question.correctIndex == optionIndex
                                      ? quizWhatsAppTeal
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.25),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                String.fromCharCode(65 + optionIndex),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: question.correctIndex == optionIndex
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: optionController,
                                minLines: 1,
                                maxLines: null, // auto-grow
                                textInputAction: TextInputAction.newline,
                                onChanged: (_) => onOptionChanged(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText: question.correctIndex == optionIndex
                                      ? 'Correct answer'
                                      : 'Add option',
                                  isDense: true,
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: quizWhatsAppTeal,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!hasOptionText)
                                  InkWell(
                                    onTap: () =>
                                        onPickOptionImage(index, optionIndex),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 2, top: 4, bottom: 4),
                                      child: Icon(
                                        (optionIndex <
                                                    question.optionImages
                                                        .length &&
                                                question.optionImages[
                                                        optionIndex] !=
                                                    null)
                                            ? Icons.image
                                            : Icons.image_outlined,
                                        size: 22,
                                        color: (optionIndex <
                                                    question.optionImages
                                                        .length &&
                                                question.optionImages[
                                                        optionIndex] !=
                                                    null)
                                            ? quizWhatsAppTeal
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                InkWell(
                                  onTap: () => onSetCorrect(optionIndex),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 2, top: 4, bottom: 4),
                                    child: Icon(
                                      question.correctIndex == optionIndex
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      size: 24,
                                      color: question.correctIndex == optionIndex
                                          ? quizWhatsAppTeal
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                if (canRemoveOption) ...[
                                  InkWell(
                                    onTap: () => onRemoveOption(optionIndex),
                                    borderRadius: BorderRadius.circular(999),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 2, right: 4, top: 4, bottom: 4),
                                      child: Icon(Icons.close_rounded, size: 22),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (optionIndex != question.options.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.7,
                          color: theme.dividerColor.withValues(alpha: 0.6),
                        ),
                    ],
                  );
                }),
                
                const Divider(height: 16),
                TextButton.icon(
                  onPressed: onAddOption,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add option'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// COMPLETED QUESTION CARD
// ============================================================================

class _CompletedQuestionCard extends StatelessWidget {
  const _CompletedQuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.onTap,
  });

  final int index;
  final QuizQuestionFields question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String prompt = question.prompt.text.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
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
                    '${index + 4}',
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (prompt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            prompt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${question.options.length} options',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.6),
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

// ============================================================================
// LABELED FIELD
// ============================================================================

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
    this.textInputAction,
    this.backgroundColor,
    this.autoExpand = true,
    this.trailing,
    this.suffixIcon,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;
  final TextInputAction? textInputAction;
  final Color? backgroundColor;
  final bool autoExpand;
  final Widget? trailing;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final Color fieldBackground = backgroundColor ?? theme.colorScheme.surface;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color outlineBase = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.35 : 0.25,
    );
    final Color focusColor =
        isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty || trailing != null) ...[
          Row(
            children: [
              if (label.isNotEmpty)
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: quizWhatsAppTeal,
                  ),
                ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: autoExpand ? null : maxLines,
          minLines: autoExpand ? maxLines : null,
          textInputAction: textInputAction,
          inputFormatters:
              maxLines == 1 ? [FilteringTextInputFormatter.singleLineFormatter] : null,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: fieldBackground,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBase, width: 1.3),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBase, width: 1.3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUIZ QUESTION FIELDS
// ============================================================================
