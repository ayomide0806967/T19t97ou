import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/quiz_repository.dart';
import 'quiz_drafts_screen.dart';
import 'quiz_results_screen.dart';
import 'quiz_take_screen.dart';

enum QuizVisibility { everyone, followers }

/// Revamped Quiz Creation Screen with rail-based vertical stepper
/// Design inspired by the note creation flow
class QuizCreateScreen extends StatefulWidget {
  const QuizCreateScreen({super.key});

  @override
  State<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

class _QuizCreateScreenState extends State<QuizCreateScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Which step is currently being edited (0 = Details, 1 = Settings, 2+ = Questions)
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
  
  // Questions
  final List<_QuizQuestionFields> _questions = <_QuizQuestionFields>[];
  
  // Track which steps have been completed
  bool _detailsCompleted = false;
  bool _settingsCompleted = false;

  @override
  void initState() {
    super.initState();
    _questions.add(_QuizQuestionFields());
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
  
  void _completeDetailsAndNext() {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Give your quiz a title to continue.');
      return;
    }
    setState(() {
      _detailsCompleted = true;
      _activeStep = 1;
    });
    _scrollToStep(1);
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
    _scrollToStep(2);
  }
  
  void _editDetailsStep() {
    setState(() => _activeStep = 0);
    _scrollToStep(0);
  }
  
  void _editSettingsStep() {
    setState(() => _activeStep = 1);
    _scrollToStep(1);
  }
  
  void _editQuestion(int index) {
    setState(() => _activeStep = 2 + index);
    _scrollToStep(2 + index);
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuizQuestionFields());
      _activeStep = 2 + _questions.length - 1;
    });
    _scrollToStep(_activeStep);
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
      if (_activeStep > 2 + _questions.length - 1) {
        _activeStep = 2 + _questions.length - 1;
      }
    });
  }

  void _addOption(int questionIndex) {
    final question = _questions[questionIndex];
    setState(() {
      question.options.add(TextEditingController());
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    final question = _questions[questionIndex];
    if (question.options.length <= 2) return;
    setState(() {
      final controller = question.options.removeAt(optionIndex);
      controller.dispose();
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

  void _publishQuiz() {
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
    QuizRepository.recordPublishedQuiz(title: title, questions: _questions.length);
    _showSnack('Quiz saved! Share it with your learners.', success: true);
    Navigator.of(context).maybePop();
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
        backgroundColor: success ? Colors.black : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizTakeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background = isDark ? const Color(0xFF0B0D11) : const Color(0xFFF5F5F5);

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
        actions: [
          IconButton(
            tooltip: 'Drafts',
            icon: const Icon(Icons.folder_outlined),
            onPressed: _openDrafts,
          ),
          IconButton(
            tooltip: 'Results',
            icon: const Icon(Icons.insights_outlined),
            onPressed: _openResults,
          ),
          IconButton(
            tooltip: 'Preview as learner',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _openQuizPreview,
          ),
          const SizedBox(width: 4),
        ],
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
                    // Hero header
                    const _QuizHeroBanner(),
                    const SizedBox(height: 24),
                    
                    // Step 1: Details
                    if (_activeStep == 0)
                      _DetailsEditingStep(
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        onNext: _completeDetailsAndNext,
                        onPreview: _openQuizPreview,
                      )
                    else
                      _CompletedStepCard(
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
                        isTimed: _isTimed,
                        timeLimitController: _timeLimitController,
                        hasDeadline: _hasDeadline,
                        closingDate: _closingDate,
                        attemptLimit: _attemptLimit,
                        requiresPin: _requiresPin,
                        pinController: _pinController,
                        visibility: _visibility,
                        onTimedChanged: (v) => setState(() {
                          _isTimed = v;
                          if (v && _timeLimitController.text.trim().isEmpty) {
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
                        onAttemptsChanged: (v) => setState(() => _attemptLimit = v),
                        onRequirePinChanged: (v) => setState(() {
                          _requiresPin = v;
                          if (!v) _pinController.clear();
                        }),
                        onVisibilityChanged: (v) => setState(() => _visibility = v),
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
                    
                    // Step 3+: Questions
                    if (_settingsCompleted) ...[
                      for (int i = 0; i < _questions.length; i++) ...[
                        if (_activeStep == 2 + i)
                          _QuestionEditingStep(
                            index: i,
                            question: _questions[i],
                            canRemove: _questions.length > 1,
                            onAddOption: () => _addOption(i),
                            onRemoveOption: (optIdx) => _removeOption(i, optIdx),
                            onSetCorrect: (optIdx) => _setCorrectOption(i, optIdx),
                            onRemove: () => _removeQuestion(i),
                            onDone: () {
                              // Move to next question or stay
                              if (i < _questions.length - 1) {
                                _editQuestion(i + 1);
                              }
                            },
                          )
                        else
                          _CompletedQuestionCard(
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
                        index: 2,
                        title: 'Questions',
                        subtitle: 'Complete settings first',
                      ),
                    ] else ...[
                      _LockedStepCard(
                        index: 2,
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
                            ),
                            child: const Text('Save draft'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _publishQuiz,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Publish'),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
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
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
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
    required this.titleController,
    required this.descriptionController,
    required this.onNext,
    required this.onPreview,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onNext;
  final VoidCallback onPreview;

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
            padding: const EdgeInsets.all(16),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Give your quiz a name and context',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Preview learner flow'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
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
    required this.isTimed,
    required this.timeLimitController,
    required this.hasDeadline,
    required this.closingDate,
    required this.attemptLimit,
    required this.requiresPin,
    required this.pinController,
    required this.visibility,
    required this.onTimedChanged,
    required this.onTimeLimitChanged,
    required this.onDeadlineChanged,
    required this.onPickDeadline,
    required this.onAttemptsChanged,
    required this.onRequirePinChanged,
    required this.onVisibilityChanged,
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
  final QuizVisibility visibility;
  final ValueChanged<bool> onTimedChanged;
  final ValueChanged<double> onTimeLimitChanged;
  final ValueChanged<bool> onDeadlineChanged;
  final Future<void> Function() onPickDeadline;
  final ValueChanged<int?> onAttemptsChanged;
  final ValueChanged<bool> onRequirePinChanged;
  final ValueChanged<QuizVisibility> onVisibilityChanged;
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
                  activeTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                ),
                if (isTimed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: timeLimitController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Minutes',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: outline),
                            ),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            onTimeLimitChanged(parsed?.toDouble() ?? 0);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                
                // Deadline
                SwitchListTile.adaptive(
                  value: hasDeadline,
                  onChanged: onDeadlineChanged,
                  title: const Text('Close automatically'),
                  subtitle: const Text('Set a deadline'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                ),
                if (hasDeadline) ...[
                  const SizedBox(height: 8),
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
                const Divider(height: 24),
                
                // Attempts
                Text(
                  'Attempts allowed',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: attemptLimit,  // Using 'value' is fine for this use case
                  items: attemptItems,
                  onChanged: onAttemptsChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline),
                    ),
                  ),
                ),
                const Divider(height: 24),
                
                // PIN
                SwitchListTile.adaptive(
                  value: requiresPin,
                  onChanged: onRequirePinChanged,
                  title: const Text('Require PIN'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                ),
                if (requiresPin) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'PIN (4-6 digits)',
                      counterText: '',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: outline),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                
                // Visibility
                Text(
                  'Visibility',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: QuizVisibility.values.map((option) {
                    final bool isSelected = option == visibility;
                    final String label = option == QuizVisibility.everyone ? 'Everyone' : 'Followers only';
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => onVisibilityChanged(option),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onBack,
                      child: const Text('Back'),
                    ),
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Next'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
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
    required this.index,
    required this.question,
    required this.canRemove,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSetCorrect,
    required this.onRemove,
    required this.onDone,
  });

  final int index;
  final _QuizQuestionFields question;
  final bool canRemove;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final void Function(int) onSetCorrect;
  final VoidCallback onRemove;
  final VoidCallback onDone;

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
                  '${index + 3}',
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
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: onRemove,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Prompt
                _LabeledField(
                  label: 'Prompt',
                  hintText: 'What parameter best reflects cardiac output?',
                  controller: question.prompt,
                  maxLines: 2,
                  autoExpand: true,
                  backgroundColor: theme.colorScheme.surface,
                ),
                const SizedBox(height: 16),
                
                // Options
                ...List.generate(question.options.length, (optionIndex) {
                  final optionController = question.options[optionIndex];
                  final optionLabel = 'Option ${String.fromCharCode(65 + optionIndex)}';
                  final bool canRemoveOption = question.options.length > 2;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: optionIndex == question.options.length - 1 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: optionLabel,
                            hintText: optionIndex == 0
                                ? 'Stroke volume × heart rate'
                                : 'Add a distractor',
                            controller: optionController,
                            backgroundColor: theme.colorScheme.surface,
                            maxLines: 2,
                            autoExpand: true,
                          ),
                        ),
                        if (canRemoveOption)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 20),
                            child: IconButton(
                              tooltip: 'Remove option',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => onRemoveOption(optionIndex),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onAddOption,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add option'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                ),
                
                const Divider(height: 24),
                
                // Correct answer
                Text(
                  'Correct answer',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(question.options.length, (optionIndex) {
                    final bool isSelected = question.correctIndex == optionIndex;
                    return ChoiceChip(
                      label: Text('Option ${String.fromCharCode(65 + optionIndex)}'),
                      selected: isSelected,
                      onSelected: (_) => onSetCorrect(optionIndex),
                      selectedColor: isDark ? Colors.white : Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
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
    required this.index,
    required this.question,
    required this.onTap,
  });

  final int index;
  final _QuizQuestionFields question;
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
                    '${index + 3}',
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
                          'Question ${index + 1}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (prompt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            prompt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${question.options.length} options',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
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
    this.autoExpand = false,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;
  final TextInputAction? textInputAction;
  final Color? backgroundColor;
  final bool autoExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final Color fieldBackground = backgroundColor ?? theme.colorScheme.surface;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color focusColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: subtle,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: autoExpand ? null : maxLines,
          minLines: autoExpand ? maxLines : null,
          textInputAction: textInputAction,
          inputFormatters: maxLines == 1 ? [FilteringTextInputFormatter.singleLineFormatter] : null,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: fieldBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
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

class _QuizQuestionFields {
  _QuizQuestionFields()
      : prompt = TextEditingController(),
        options = List<TextEditingController>.generate(4, (_) => TextEditingController());

  final TextEditingController prompt;
  final List<TextEditingController> options;
  int correctIndex = 0;

  void dispose() {
    prompt.dispose();
    for (final controller in options) {
      controller.dispose();
    }
  }
}
