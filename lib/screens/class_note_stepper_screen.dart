import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ClassNoteStepperScreen extends StatefulWidget {
  const ClassNoteStepperScreen({super.key});

  @override
  State<ClassNoteStepperScreen> createState() => _ClassNoteStepperScreenState();
}

class _ClassNoteStepperScreenState extends State<ClassNoteStepperScreen> {
  int _activeIndex = 0;

  // Example data – a single note broken into short rails/sections.
  final List<_ClassNoteSection> _sections = const [
    _ClassNoteSection(
      title: '1 · Overview',
      subtitle: 'Why this topic matters today',
      bullets: [
        'Defines the clinical problem in one or two sentences.',
        'Connects it to a real ward situation students will recognise.',
        'States the outcome: what you should be able to do after this note.',
      ],
    ),
    _ClassNoteSection(
      title: '2 · Key facts',
      subtitle: 'Numbers and red‑flag thresholds',
      bullets: [
        '3–5 key facts only – no paragraphs.',
        'Highlight red‑flags in bold in the final copy.',
        'Keep each line readable on one screen without scrolling sideways.',
      ],
    ),
    _ClassNoteSection(
      title: '3 · Simple example',
      subtitle: 'Short story from the ward',
      bullets: [
        'One patient story, 3–4 sentences max.',
        'Focus on the decision points, not every detail.',
        'End with: “What would you do next?” to keep them thinking.',
      ],
    ),
    _ClassNoteSection(
      title: '4 · Checklist',
      subtitle: 'Steps to follow in practice',
      bullets: [
        'Turn the protocol into 4–6 clear steps.',
        'Use verbs at the start: “Check…”, “Confirm…”, “Document…”.',
        'Highlight any “never” behaviours in a different colour in real notes.',
      ],
    ),
    _ClassNoteSection(
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
              // Step rails – only the current and next rails are fully "revealed"
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final isActive = index == _activeIndex;
                    final isNext = index == _activeIndex + 1;
                    // We "reveal" at most two sections at a time:
                    // current rail (expanded) and the next rail (peeked).
                    final isRevealed = isActive || isNext;
                    return _NoteRailStep(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
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

class _NoteRailStep extends StatelessWidget {
  const _NoteRailStep({
    required this.index,
    required this.total,
    required this.section,
    required this.isActive,
    required this.isRevealed,
    required this.onTap,
  });

  final int index;
  final int total;
  final _ClassNoteSection section;
  final bool isActive;
  final bool isRevealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );

    // WhatsApp-style accent for active highlights
    const whatsAppGreen = Color(0xFF25D366);

    final circleColor = isActive
        ? whatsAppGreen
        : onSurface.withValues(alpha: isRevealed ? 0.15 : 0.08);
    final borderColor =
        isActive ? whatsAppGreen : onSurface.withValues(alpha: 0.25);

    return Padding(
      padding: EdgeInsets.only(
        bottom: index == total - 1 ? 0 : 18,
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  if (index != 0)
                    Container(
                      width: 2,
                      height: 18,
                      color: onSurface.withValues(alpha: 0.25),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                      border: Border.all(color: borderColor, width: 1.6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isActive ? Colors.white : borderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (index != total - 1)
                    Container(
                      width: 2,
                      height: 26,
                      color: onSurface.withValues(alpha: 0.25),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? whatsAppGreen.withValues(alpha: 0.08)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? whatsAppGreen
                        : theme.dividerColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                      ),
                    ),
                    if (isRevealed) ...[
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: section.bullets
                            .map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('•  '),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: onSurface,
                                          // Slightly larger, chat-like reading size
                                          fontSize: isActive ? 16 : null,
                                          height: isActive ? 1.5 : 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassNoteSection {
  const _ClassNoteSection({
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;
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

  final List<_ClassNoteSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final controller = TextEditingController();

    final List<_DiscussionMessage> messages = [
      for (final section in sections)
        _DiscussionMessage(
          author: 'Tutor',
          isTutor: true,
          timeAgo: '',
          body: [
            section.title,
            section.subtitle,
            if (section.bullets.isNotEmpty)
              section.bullets.map((b) => '• $b').join('\n'),
          ].where((t) => t.trim().isNotEmpty).join('\n\n'),
        ),
      const _DiscussionMessage(
        author: 'Tutor',
        isTutor: true,
        timeAgo: '2h ago',
        body:
            'If you are unsure about a red‑flag value, always escalate early rather than waiting.',
      ),
      const _DiscussionMessage(
        author: 'Ada',
        isTutor: false,
        timeAgo: '1h ago',
        body:
            'Is there an easy way to remember the high‑risk medication list for exams?',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class discussion'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication safety in NICU',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discussion space for this note',
                    style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  return _DiscussionBubble(message: m);
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Ask a question or share a thought…',
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: onSurface.withValues(alpha: 0.16),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: onSurface.withValues(alpha: 0.16),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: Color(0xFF25D366),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF25D366),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        color: Colors.white,
                        onPressed: () {
                          // In this mock screen we just clear; hook into backend later.
                          controller.clear();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscussionMessage {
  const _DiscussionMessage({
    required this.author,
    required this.isTutor,
    required this.timeAgo,
    required this.body,
  });

  final String author;
  final bool isTutor;
  final String timeAgo;
  final String body;
}

class _DiscussionBubble extends StatelessWidget {
  const _DiscussionBubble({required this.message});

  final _DiscussionMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );

    final bool isTutor = message.isTutor;
    final Color border = theme.colorScheme.onSurface.withValues(alpha: 0.18);
    final Color fill = theme.colorScheme.surface;

    final avatarFrame = Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EC),
        borderRadius: BorderRadius.zero,
      ),
      alignment: Alignment.center,
      child: Text(
        message.author.isNotEmpty
            ? message.author.substring(0, 1).toUpperCase()
            : '?',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isTutor ? Colors.white : onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    Future<void> showRepostOptions() async {
      final theme = Theme.of(context);
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final bool isDark = theme.brightness == Brightness.dark;
          final Color surface = theme.colorScheme.surface.withValues(
            alpha: isDark ? 0.92 : 0.96,
          );
          final Color borderColor =
              Colors.white.withValues(alpha: isDark ? 0.12 : 0.25);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.repeat_rounded),
                            title: const Text('Repost'),
                            subtitle: const Text(
                              'Share this note message with your class',
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.dividerColor.withValues(alpha: 0.16),
                          ),
                          ListTile(
                            leading: const Icon(Icons.mode_comment_outlined),
                            title: const Text('Repost with comment'),
                            subtitle: const Text(
                              'Add your explanation before sharing',
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Use a reply-card style layout: rounded card with border and a
    // picture-frame avatar cutting into the left edge.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main discussion card
          Container(
            margin: const EdgeInsets.only(left: 32),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isTutor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Tutor',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF167C3A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      message.timeAgo,
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: subtle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurface,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Hook up to scroll to composer in a real implementation.
                      },
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: showRepostOptions,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'REPOST',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: subtle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Picture-frame avatar overlapping the left edge.
          Positioned(
            left: 0,
            top: 12,
            child: avatarFrame,
          ),
        ],
      ),
    );
  }
}
