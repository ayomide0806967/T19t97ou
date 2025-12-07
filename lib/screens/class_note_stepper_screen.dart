import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ios_messages_screen.dart' show ClassDiscussionThreadPage;
import '../models/class_note.dart';
import '../widgets/note_rail_step.dart';

class ClassNoteStepperScreen extends StatefulWidget {
  const ClassNoteStepperScreen({super.key});

  @override
  State<ClassNoteStepperScreen> createState() => _ClassNoteStepperScreenState();
}

class _ClassNoteStepperScreenState extends State<ClassNoteStepperScreen> {
  int _activeIndex = 0;

  // Example data – a single note broken into short rails/sections.
  final List<ClassNoteSection> _sections = const [
    ClassNoteSection(
      title: '1 · Overview',
      subtitle: 'Why this topic matters today',
      bullets: [
        'Defines the clinical problem in one or two sentences.',
        'Connects it to a real ward situation students will recognise.',
        'States the outcome: what you should be able to do after this note.',
      ],
    ),
    ClassNoteSection(
      title: '2 · Key facts',
      subtitle: 'Numbers and red‑flag thresholds',
      bullets: [
        '3–5 key facts only – no paragraphs.',
        'Highlight red‑flags in bold in the final copy.',
        'Keep each line readable on one screen without scrolling sideways.',
      ],
    ),
    ClassNoteSection(
      title: '3 · Simple example',
      subtitle: 'Short story from the ward',
      bullets: [
        'One patient story, 3–4 sentences max.',
        'Focus on the decision points, not every detail.',
        'End with: “What would you do next?” to keep them thinking.',
      ],
    ),
    ClassNoteSection(
      title: '4 · Checklist',
      subtitle: 'Steps to follow in practice',
      bullets: [
        'Turn the protocol into 4–6 clear steps.',
        'Use verbs at the start: “Check…”, “Confirm…”, “Document…”.',
        'Highlight any “never” behaviours in a different colour in real notes.',
      ],
    ),
    ClassNoteSection(
      title: '5 · Self‑check',
      subtitle: 'Tiny quiz to close the loop',
      bullets: [
        '2–3 short questions or scenarios.',
        'Ask students to predict, then reveal the answer in class or later.',
      ],
    ),
  ];

  void _setActive(int index) {
    if (index < 0 || index >= _sections.length) return;
    setState(() => _activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final progress = (_activeIndex + 1) / _sections.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class note'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medication safety in NICU',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'NUR 301 · Week 4',
                style: theme.textTheme.bodySmall?.copyWith(color: subtle),
              ),
              const SizedBox(height: 16),
              // Overall note progress using the same 3‑colour logic
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Container(
                              color: onSurface.withValues(alpha: 0.12),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              alignment: Alignment.centerLeft,
                              child: Container(
                                color: _progressColor(theme, progress),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: subtle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final isActive = index == _activeIndex;
                    // Only the active step is "open" – others stay collapsed.
                    final isRevealed = isActive;
                    return NoteRailStep(
                      index: index,
                      total: _sections.length,
                      section: section,
                      isActive: isActive,
                      isRevealed: isRevealed,
                      onTap: () => _setActive(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Dedicated discussion entry point (separate page)
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: const Text('Open class discussion'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassNoteDiscussionScreen(
                            sections: _sections,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _progressColor(ThemeData theme, double value) {
  // Keep the 3‑colour progress logic: red → dark cyan → green.
  final p = value.clamp(0.0, 1.0);
  if (p <= 0.30) {
    return Colors.red;
  }
  if (p <= 0.60) {
    return const Color(0xFF00838F); // dark cyan
  }
  return Colors.green;
}

/// Simple, dedicated discussion page for class notes.
class ClassNoteDiscussionScreen extends StatelessWidget {
  const ClassNoteDiscussionScreen({
    super.key,
    required this.sections,
  });

  final List<ClassNoteSection> sections;

  @override
  Widget build(BuildContext context) {
    return ClassDiscussionThreadPage(
      title: 'Medication safety in NICU',
      subtitle: 'Discussion space for this note',
    );
  }
}
