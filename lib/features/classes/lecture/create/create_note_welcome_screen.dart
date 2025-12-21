import 'package:flutter/material.dart';
import 'teacher_note_creation_screen.dart';

/// Shows a modal bottom sheet for creating a new lecture
/// Matches the design of the create note page
void showCreateLectureModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CreateLectureModal(),
  );
}

class _CreateLectureModal extends StatefulWidget {
  const _CreateLectureModal();

  @override
  State<_CreateLectureModal> createState() => _CreateLectureModalState();
}

class _CreateLectureModalState extends State<_CreateLectureModal> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _subtitleController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _startLecture() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(); // Close modal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TeacherNoteCreationScreen(
            topic: _topicController.text.trim(),
            subtitle: _subtitleController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Create a Lecture',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the context for your students',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Input fields in a card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
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
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.8,
                          ),
                        ),
                      ),
                      textSelectionTheme: const TextSelectionThemeData(
                        cursorColor: Colors.black,
                      ),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _topicController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Course Topic',
                            hintText: 'e.g., Medication safety in NICU',
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter a topic'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subtitleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Subtitle / Context',
                            hintText: 'e.g., NUR 301 · Week 4',
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter context'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Start button
                FilledButton(
                  onPressed: _startLecture,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Start Lecture'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
