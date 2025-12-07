import 'package:flutter/material.dart';
import '../models/class_note.dart';

/// Displays a completed note step in the stepper rail.
/// Matches the monochrome design of Create Class screen.
class NoteRailStep extends StatelessWidget {
  const NoteRailStep({
    super.key,
    required this.index,
    required this.total,
    required this.section,
    required this.isActive,
    required this.isRevealed,
    required this.onTap,
  });

  final int index;
  final int total;
  final ClassNoteSection section;
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: index == total - 1 ? 0 : 16,
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  if (index != 0)
                    Container(
                      width: isActive ? 2 : 1,
                      height: 8,
                      color: isActive ? Colors.black : Colors.black26,
                    ),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? Colors.black : Colors.black26,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : (isRevealed ? Colors.black : Colors.black38),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  if (index != total - 1)
                    Container(
                      width: isActive ? 2 : 1,
                      height: 20,
                      color: isActive ? Colors.black : Colors.black26,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content panel
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    if (section.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ],
                    if (isRevealed && section.bullets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: section.bullets
                            .map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('•  '),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: onSurface,
                                          height: 1.4,
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
