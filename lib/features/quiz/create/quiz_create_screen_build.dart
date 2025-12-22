part of 'quiz_create_screen.dart';

mixin _QuizCreateScreenBuild
    on _QuizCreateScreenStateBase, _QuizCreateScreenActions {
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Create Quiz',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
                            key: i < _questionStepKeys.length
                                ? _questionStepKeys[i]
                                : null,
                            index: i,
                            question: _questions[i],
                            canRemove: _questions.length > 1,
                            onAddOption: () => _addOption(i),
                            onRemoveOption: (optIdx) =>
                                _removeOption(i, optIdx),
                            onSetCorrect: (optIdx) =>
                                _setCorrectOption(i, optIdx),
                            onRemove: () => _removeQuestion(i),
                            onPickPromptImage: (idx) => _pickPromptImage(idx),
                            onRemovePromptImage: (idx) =>
                                _removePromptImage(idx),
                            onPickOptionImage: (qIdx, optIdx) =>
                                _pickOptionImage(qIdx, optIdx),
                            onRemoveOptionImage: (qIdx, optIdx) =>
                                _removeOptionImage(qIdx, optIdx),
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
                            key: i < _questionStepKeys.length
                                ? _questionStepKeys[i]
                                : null,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
