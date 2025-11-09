import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/quiz_repository.dart';
import 'quiz_drafts_screen.dart';
import 'quiz_results_screen.dart';
import 'quiz_take_screen.dart';

enum QuizVisibility { everyone, followers }

class QuizCreateScreen extends StatefulWidget {
  const QuizCreateScreen({super.key});

  @override
  State<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

class _QuizCreateScreenState extends State<QuizCreateScreen> {
  static const List<String> _stepTitles = ['Details', 'Settings', 'Questions'];

  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isTimed = true;
  double _timeLimitMinutes = 20;
  bool _hasDeadline = false;
  DateTime? _closingDate;
  int? _attemptLimit;
  bool _requiresPin = false;
  QuizVisibility _visibility = QuizVisibility.everyone;

  final List<_QuizQuestionFields> _questions = <_QuizQuestionFields>[];
  final TextEditingController _timeLimitController =
      TextEditingController(text: '20');
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _questions.add(_QuizQuestionFields());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _pinController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background = isDark ? const Color(0xFF0B0D11) : const Color(0xFFF5F5F5);

    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final bool isKeyboardVisible = keyboardInset > 0;

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
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: _StepProgress(
                    currentStep: _currentStep,
                    labels: _stepTitles,
                    onStepTap: _goToStep,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isKeyboardVisible ? 16 : 110),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _DetailsStep(
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                          onPreviewTap: _openQuizPreview,
                        ),
                        _SettingsStep(
                          isTimed: _isTimed,
                          timeLimitController: _timeLimitController,
                          hasDeadline: _hasDeadline,
                          closingDate: _closingDate,
                          attemptLimit: _attemptLimit,
                          onTimedChanged: (value) => setState(() {
                            _isTimed = value;
                            if (value && _timeLimitController.text.trim().isEmpty) {
                              _timeLimitController.text =
                                  (_timeLimitMinutes > 0 ? _timeLimitMinutes : 10).round().toString();
                            }
                          }),
                          onTimeLimitChanged: (value) => setState(() {
                            final double clamped = value.clamp(0, 360).toDouble();
                            _timeLimitMinutes = clamped;
                            if (clamped > 0 &&
                                _timeLimitController.text != clamped.round().toString()) {
                              _timeLimitController.text = clamped.round().toString();
                            }
                          }),
                          onDeadlineChanged: (enabled) => setState(() {
                            _hasDeadline = enabled;
                            if (!enabled) _closingDate = null;
                          }),
                          onPickDeadline: _pickDeadline,
                          onAttemptsChanged: (value) => setState(() => _attemptLimit = value),
                          requiresPin: _requiresPin,
                          onRequirePinChanged: (value) => setState(() {
                            _requiresPin = value;
                            if (!value) _pinController.clear();
                          }),
                          pinController: _pinController,
                          visibility: _visibility,
                          onVisibilityChanged: (value) => setState(() => _visibility = value),
                        ),
                        _QuestionsStep(
                          questions: _questions,
                          onAddQuestion: _addQuestion,
                          onRemoveQuestion: _removeQuestion,
                          onAddOption: _addOption,
                          onRemoveOption: _removeOption,
                          onSetCorrect: _setCorrectOption,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardInset,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  isKeyboardVisible ? 8 : 16,
                ),
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _currentStep == 0
                            ? () => Navigator.of(context).maybePop()
                            : _goToPreviousStep,
                        child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _saveDraft,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save draft'),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.extended(
                        heroTag: 'quiz_next',
                        onPressed: _currentStep == _stepTitles.length - 1
                            ? _publishQuiz
                            : _goToNextStep,
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        label: Text(_currentStep == _stepTitles.length - 1 ? 'Publish' : 'Next'),
                        icon: Icon(_currentStep == _stepTitles.length - 1
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _goToNextStep() {
    if (!_validateStep(_currentStep)) return;
    setState(() => _currentStep += 1);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToStep(int target) {
    if (target < 0 || target >= _stepTitles.length) return;
    if (target == _currentStep) return;
    if (target > _currentStep) {
      for (int step = _currentStep; step < target; step++) {
        if (!_validateStep(step)) {
          return;
        }
      }
    }
    setState(() => _currentStep = target);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final DateTime initialDate = _closingDate ?? now.add(const Duration(days: 1));
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final TimeOfDay initialTime = _closingDate != null
        ? TimeOfDay.fromDateTime(_closingDate!)
        : const TimeOfDay(hour: 9, minute: 0);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

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

  void _addQuestion() {
    setState(() {
      _questions.add(_QuizQuestionFields());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
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

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          _showSnack('Give your quiz a title to continue.');
          return false;
        }
        return true;
      case 1:
        if (_isTimed && _timeLimitMinutes < 1) {
          _showSnack('Set a timer of at least 1 minute.');
          return false;
        }
        if (_hasDeadline) {
          if (_closingDate == null) {
            _showSnack('Choose when the quiz should close.');
            return false;
          }
          if (_closingDate!.isBefore(DateTime.now())) {
            _showSnack('Closing time must be in the future.');
            return false;
          }
        }
        if (_requiresPin && (_pinController.text.trim().length < 4)) {
          _showSnack('PIN must be at least 4 digits.');
          return false;
        }
        return true;
      case 2:
        return _validateQuestions();
      default:
        return true;
    }
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
    if (!_validateStep(2)) return;

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
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.titleController,
    required this.descriptionController,
    required this.onPreviewTap,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const _HeroBanner(),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onPreviewTap,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Preview learner flow'),
          ),
        ),
        const SizedBox(height: 24),
        _LabeledField(
          label: 'Title',
          hintText: 'Cardiology round recap quiz',
          controller: titleController,
          textInputAction: TextInputAction.next,
          backgroundColor: cardColor,
        ),
        const SizedBox(height: 20),
        _LabeledField(
          label: 'Description',
          hintText: 'Give learners context or expectations for this quiz.',
          controller: descriptionController,
          maxLines: 3,
          autoExpand: true,
          backgroundColor: cardColor,
        ),
      ],
    );
  }
}

class _SettingsStep extends StatelessWidget {
  const _SettingsStep({
    required this.isTimed,
    required this.timeLimitController,
    required this.hasDeadline,
    required this.closingDate,
    required this.attemptLimit,
    required this.onTimedChanged,
    required this.onTimeLimitChanged,
    required this.onDeadlineChanged,
    required this.onPickDeadline,
    required this.onAttemptsChanged,
    required this.requiresPin,
    required this.onRequirePinChanged,
    required this.pinController,
    required this.visibility,
    required this.onVisibilityChanged,
  });

  final bool isTimed;
  final TextEditingController timeLimitController;
  final bool hasDeadline;
  final DateTime? closingDate;
  final int? attemptLimit;
  final ValueChanged<bool> onTimedChanged;
  final ValueChanged<double> onTimeLimitChanged;
  final ValueChanged<bool> onDeadlineChanged;
  final Future<void> Function() onPickDeadline;
  final ValueChanged<int?> onAttemptsChanged;
  final bool requiresPin;
  final ValueChanged<bool> onRequirePinChanged;
  final TextEditingController pinController;
  final QuizVisibility visibility;
  final ValueChanged<QuizVisibility> onVisibilityChanged;

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                value: isTimed,
                onChanged: onTimedChanged,
                title: const Text('Timed quiz'),
                subtitle: const Text('Set a time limit learners must complete within'),
                contentPadding: EdgeInsets.zero,
                activeColor: isDark ? Colors.white : Colors.black,
                activeTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              ),
              if (isTimed) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : Colors.black.withValues(alpha: 0.45),
                              width: 1.3,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          onTimeLimitChanged(parsed == null ? 0 : parsed.toDouble());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Learners must finish within this time limit.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 32),
              SwitchListTile.adaptive(
                value: hasDeadline,
                onChanged: onDeadlineChanged,
                title: const Text('Close automatically'),
                subtitle: const Text('Choose when the quiz stops accepting responses'),
                contentPadding: EdgeInsets.zero,
                activeColor: isDark ? Colors.white : Colors.black,
                activeTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasDeadline
                    ? Padding(
                        key: const ValueKey('deadline_picker'),
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: onPickDeadline,
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: outline),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  deadlineLabel,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attempts allowed',
                          style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          value: attemptLimit,
                          items: attemptItems,
                          onChanged: onAttemptsChanged,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              SwitchListTile.adaptive(
                value: requiresPin,
                onChanged: onRequirePinChanged,
                title: const Text('Require PIN to join'),
                subtitle: const Text('Participants must enter a PIN before starting'),
                contentPadding: EdgeInsets.zero,
                activeColor: isDark ? Colors.white : Colors.black,
                activeTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: requiresPin
                    ? Padding(
                        key: const ValueKey('pin_field'),
                        padding: const EdgeInsets.only(top: 12),
                        child: TextField(
                          controller: pinController,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN (4-6 digits)',
                            counterText: '',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: outline),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const Divider(height: 32),
              Text(
                'Visibility',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: QuizVisibility.values.map((option) {
                  final bool isSelected = option == visibility;
                  final String label = option == QuizVisibility.everyone
                      ? 'Everyone'
                      : 'Followers only';
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => onVisibilityChanged(option),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionsStep extends StatelessWidget {
  const _QuestionsStep({
    required this.questions,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSetCorrect,
  });

  final List<_QuizQuestionFields> questions;
  final VoidCallback onAddQuestion;
  final void Function(int index) onRemoveQuestion;
  final void Function(int questionIndex) onAddOption;
  final void Function(int questionIndex, int optionIndex) onRemoveOption;
  final void Function(int questionIndex, int optionIndex) onSetCorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        ...List.generate(questions.length, (index) {
          final question = questions[index];
          final label = 'Question ${index + 1}';
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (questions.length > 1)
                        IconButton(
                          tooltip: 'Remove question',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => onRemoveQuestion(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Prompt',
                    hintText: 'What parameter best reflects cardiac output?',
                    controller: question.prompt,
                    maxLines: 2,
                    autoExpand: true,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: List.generate(question.options.length, (optionIndex) {
                      final optionController = question.options[optionIndex];
                      final optionLabel = 'Option ${String.fromCharCode(65 + optionIndex)}';
                      final bool canRemove = question.options.length > 2;
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
                                    : 'Add a distractor that challenges recall',
                                controller: optionController,
                                backgroundColor: theme.colorScheme.surface,
                                textInputAction: TextInputAction.next,
                                maxLines: 2,
                                autoExpand: true,
                              ),
                            ),
                            if (canRemove)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 12),
                                child: IconButton(
                                  tooltip: 'Remove option',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => onRemoveOption(index, optionIndex),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => onAddOption(index),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add option'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Correct answer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(question.options.length, (optionIndex) {
                      final bool isSelected = question.correctIndex == optionIndex;
                      final Color selectedColor =
                          isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black;
                      final Color selectedText = isDark ? Colors.black : Colors.white;
                      final Color neutralBg =
                          isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
                      final Color neutralBorder =
                          isDark ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.15);
                      return ChoiceChip(
                        label: Text('Option ${String.fromCharCode(65 + optionIndex)}'),
                        selected: isSelected,
                        onSelected: (_) => onSetCorrect(index, optionIndex),
                        labelStyle: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? selectedText : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ) ??
                            TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                        selectedColor: selectedColor,
                        backgroundColor: neutralBg,
                        side: BorderSide(color: isSelected ? selectedColor : neutralBorder),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAddQuestion,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add another question'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

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
              'Step 1 · Outline',
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: focusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.currentStep,
    required this.labels,
    required this.onStepTap,
  });

  final int currentStep;
  final List<String> labels;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(labels.length, (index) {
        final bool isComplete = index < currentStep;
        final bool isActive = index == currentStep;
        final Color activeColor = theme.colorScheme.onSurface;
        final Color inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => onStepTap(index),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isComplete || isActive ? activeColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isComplete || isActive ? activeColor : inactiveColor, width: 2),
                      ),
                      child: Center(
                        child: isComplete
                            ? Icon(Icons.check_rounded, size: 18, color: Theme.of(context).scaffoldBackgroundColor)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Theme.of(context).scaffoldBackgroundColor : inactiveColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (index != labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: index < currentStep ? activeColor : inactiveColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => onStepTap(index),
                child: Text(
                  labels[index],
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive ? activeColor : inactiveColor,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

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
