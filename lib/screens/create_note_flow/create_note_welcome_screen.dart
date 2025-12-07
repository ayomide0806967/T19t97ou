import 'package:flutter/material.dart';
import 'teacher_note_creation_screen.dart';

class CreateNoteWelcomeScreen extends StatefulWidget {
  const CreateNoteWelcomeScreen({super.key});

  @override
  State<CreateNoteWelcomeScreen> createState() => _CreateNoteWelcomeScreenState();
}

class _CreateNoteWelcomeScreenState extends State<CreateNoteWelcomeScreen> {
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('New Class Note')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What are you teaching today?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the context for your students.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _topicController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Course Topic',
                    hintText: 'e.g., Medication safety in NICU',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a topic' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _subtitleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Subtitle / Context',
                    hintText: 'e.g., NUR 301 · Week 4',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter context' : null,
                ),
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: _startLecture,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Lecture'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
