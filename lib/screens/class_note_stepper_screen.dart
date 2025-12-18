import 'package:flutter/material.dart';
import 'ios_messages_screen.dart' show ClassDiscussionThreadPage;
import '../models/class_note.dart';
import '../widgets/note_rail_step.dart';

class ClassNoteStepperScreen extends StatefulWidget {
  const ClassNoteStepperScreen({super.key, this.summary});

  final ClassNoteSummary? summary;

  @override
  State<ClassNoteStepperScreen> createState() => _ClassNoteStepperScreenState();
}

class _ClassNoteStepperScreenState extends State<ClassNoteStepperScreen> {
  int _activeIndex = 0;
  final List<GlobalKey> _stepKeys = <GlobalKey>[];
  NoteStepBackgroundMode _activeBackgroundMode = NoteStepBackgroundMode.auto;

  // Example data – a single note broken into short rails/sections.
  late final List<ClassNoteSection> _sections = widget.summary?.sections.isNotEmpty == true
      ? List<ClassNoteSection>.from(widget.summary!.sections)
      : const <ClassNoteSection>[
    ClassNoteSection(
      title: '1 · Overview',
      subtitle: 'Why this topic matters today',
      bullets: <String>[
        'Defines the clinical problem in one or two sentences.',
        'Connects it to a real ward situation students will recognise.',
        'States the outcome: what you should be able to do after this note.',
      ],
    ),
    ClassNoteSection(
      title: '2 · Key facts',
      subtitle: 'Numbers and red‑flag thresholds',
      bullets: <String>[
        '3–5 key facts only – no paragraphs.',
        'Highlight red‑flags in bold in the final copy.',
        'Keep each line readable on one screen without scrolling sideways.',
      ],
    ),
    ClassNoteSection(
      title: '3 · Simple example',
      subtitle: 'Short story from the ward',
      bullets: <String>[
        'One patient story, 3–4 sentences max.',
        'Focus on the decision points, not every detail.',
        'End with: “What would you do next?” to keep them thinking.',
      ],
    ),
    ClassNoteSection(
      title: '4 · Checklist',
      subtitle: 'Steps to follow in practice',
      bullets: <String>[
        'Turn the protocol into 4–6 clear steps.',
        'Use verbs at the start: “Check…”, “Confirm…”, “Document…”.',
        'Highlight any “never” behaviours in a different colour in real notes.',
      ],
    ),
    ClassNoteSection(
      title: '5 · Self‑check',
      subtitle: 'Tiny quiz to close the loop',
      bullets: <String>[
        '2–3 short questions or scenarios.',
        'Ask students to predict, then reveal the answer in class or later.',
      ],
    ),
      ];

  @override
  void initState() {
    super.initState();
    _stepKeys.addAll(List<GlobalKey>.generate(_sections.length, (_) => GlobalKey()));
  }

  void _cycleStepBackground(int index) {
    if (index != _activeIndex) return;
    setState(() {
      _activeBackgroundMode = switch (_activeBackgroundMode) {
        NoteStepBackgroundMode.auto => NoteStepBackgroundMode.whatsapp,
        NoteStepBackgroundMode.whatsapp => NoteStepBackgroundMode.offwhite,
        NoteStepBackgroundMode.offwhite => NoteStepBackgroundMode.white,
        NoteStepBackgroundMode.white => NoteStepBackgroundMode.black,
        NoteStepBackgroundMode.black => NoteStepBackgroundMode.auto,
      };
    });
  }

  void _setActive(int index) {
    if (index < 0 || index >= _sections.length) return;
    setState(() => _activeIndex = index);
    // After the frame updates, gently scroll the tapped step so that it
    // sits around the middle of the screen for easier reading.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? stepContext = _stepKeys[index].currentContext;
      if (stepContext == null) return;
      Scrollable.ensureVisible(
        stepContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // aim for vertical center of the viewport
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final progressFill = _progressFillColor(theme, _activeBackgroundMode);
    final int totalSteps = _sections.isEmpty ? 1 : _sections.length;
    final progress = (_activeIndex + 1) / totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.summary?.title ?? 'Class note',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          // Let cards extend almost to the right edge so text
          // can use the full width of the screen.
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                color: progressFill,
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
              Expanded(
                child: ListView.builder(
                  // Extra bottom padding so the last item can scroll up
                  // toward the middle of the screen when focused.
                  padding: const EdgeInsets.only(bottom: 160),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final isActive = index == _activeIndex;
                    // Only the active step is "open" – others stay collapsed.
                    final isRevealed = isActive;
                    return NoteRailStep(
                      key: _stepKeys[index],
                      index: index,
                      total: _sections.length,
                      section: section,
                      isActive: isActive,
                      isRevealed: isRevealed,
                      onTap: () => _setActive(index),
                      onDoubleTap: () => _cycleStepBackground(index),
                      backgroundMode: isActive
                          ? _activeBackgroundMode
                          : NoteStepBackgroundMode.white,
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

Color _progressFillColor(ThemeData theme, NoteStepBackgroundMode mode) {
  const Color whatsappBubble = Color(0xFFDCF8C6);

  return switch (mode) {
    NoteStepBackgroundMode.auto => whatsappBubble,
    NoteStepBackgroundMode.whatsapp => whatsappBubble,
    NoteStepBackgroundMode.offwhite => Colors.black,
    NoteStepBackgroundMode.white => Colors.black,
    NoteStepBackgroundMode.black => Colors.black,
  };
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
