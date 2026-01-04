import 'dart:io';
import 'package:flutter/material.dart';
import '../models/class_note.dart';

enum NoteStepBackgroundMode {
  auto,
  whatsapp,
  offwhite,
  white,
  black,
}

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
    required this.backgroundMode,
    this.onDoubleTap,
  });

  final int index;
  final int total;
  final ClassNoteSection section;
  final bool isActive;
  final bool isRevealed;
  final VoidCallback onTap;
  final NoteStepBackgroundMode backgroundMode;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: isDark ? 0.6 : 0.55,
    );
    // Use the WhatsApp-style bubble for text steps, but keep image-only
    // steps on a neutral surface so the images stand out without tint.
    const Color whatsappBubble = Color(0xFFDCF8C6);
    final bool hasImages = section.imagePaths.isNotEmpty;
    final Color offwhite = isDark ? theme.colorScheme.surface : const Color(0xFFF5F5F5);
    final Color pureWhite = isDark ? theme.colorScheme.surface : Colors.white;

    final Color panelColor = switch (backgroundMode) {
      NoteStepBackgroundMode.auto => hasImages
          ? theme.colorScheme.surface
          : (isActive ? whatsappBubble : theme.colorScheme.surface),
      NoteStepBackgroundMode.whatsapp => whatsappBubble,
      NoteStepBackgroundMode.offwhite => offwhite,
      NoteStepBackgroundMode.white => pureWhite,
      NoteStepBackgroundMode.black => Colors.black,
    };

    final bool isDarkPanel = panelColor.computeLuminance() < 0.28;
    final Color contentColor = isDarkPanel ? Colors.white : Colors.black87;
    final Color metaColor = isDarkPanel
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.55);
    final Color borderColor = isDarkPanel
        ? Colors.white.withValues(alpha: 0.28)
        : theme.dividerColor.withValues(alpha: 0.25);

    return Padding(
      padding: EdgeInsets.only(
        bottom: index == total - 1 ? 0 : 16,
      ),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
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
                    onDoubleTap: onDoubleTap,
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
                // Keep comfortable left padding near the rail, but make the
                // right padding tighter so text can run closer to the edge.
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: contentColor,
                        fontSize: 15,
                      ),
                    ),
                    if (section.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: metaColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (isRevealed && section.imagePaths.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: PageView.builder(
                          itemCount: section.imagePaths.length,
                          controller: PageController(viewportFraction: 0.9),
                          itemBuilder: (context, index) {
                            final String path = section.imagePaths[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _FullScreenImageViewer(imagePath: path),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black12,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Image ${index + 1}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: subtle,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (isRevealed && section.bullets.isNotEmpty) ...[
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
                                    Text(
                                      '•  ',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: contentColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: contentColor,
                                          height: 1.4,
                                          fontSize: 15,
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

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
