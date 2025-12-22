part of 'teacher_note_creation_screen.dart';

mixin _TeacherNoteCreationBuild
    on _TeacherNoteCreationScreenStateBase, _TeacherNoteCreationActions {
  Widget _buildScreen(BuildContext context) {
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
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
                          imagePaths:
                              _imagePathsByStep[i] ?? _sections[i].imagePaths,
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
                        imagePaths:
                            _imagePathsByStep[_sections.length] ??
                            const <String>[],
                        onAddImage: () =>
                            _handleAddImageForStep(_sections.length),
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
                                if (_sections.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: const Text(
                                          'Add at least one step before attaching a quiz.',
                                        ),
                                      ),
                                    );
                                  return;
                                }
                                final String? title =
                                    await Navigator.of(context).push<String>(
                                      MaterialPageRoute(
                                        builder: (_) => QuizCreateScreen(
                                          returnToCallerOnPublish: true,
                                          initialTitle: widget.topic,
                                        ),
                                      ),
                                    );
                                if (!context.mounted || title == null) return;
                                setState(() {
                                  _attachedQuizTitle = title;
                                });
                                _showAttachedQuizToast(context, title);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                backgroundColor: _sections.isEmpty
                                    ? Colors.grey.shade300
                                    : (_attachedQuizTitle == null
                                          ? Colors.transparent
                                          : Colors.white),
                                foregroundColor: _sections.isEmpty
                                    ? Colors.grey.shade600
                                    : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                side: BorderSide(
                                  color: _sections.isEmpty
                                      ? Colors.grey.shade400
                                      : Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                              icon: Icon(
                                _attachedQuizTitle == null
                                    ? Icons.quiz_outlined
                                    : Icons.check_circle_rounded,
                                size: 20,
                                color: _sections.isEmpty
                                    ? Colors.grey.shade600
                                    : (_attachedQuizTitle == null
                                          ? null
                                          : const Color(0xFF075E54)),
                              ),
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
