import 'package:flutter/material.dart';

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Required'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              'Supabase is not configured for this build.',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'This app is configured to run fully “live” using Supabase only. '
              'Provide these build-time values and rebuild/run:',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const _CodeBlock(
              lines: [
                'flutter run \\',
                '  --dart-define-from-file=.env',
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'If you are running tests:',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const _CodeBlock(
              lines: [
                'flutter test \\',
                '  --dart-define-from-file=.env',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        lines.join('\n'),
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.35,
        ),
      ),
    );
  }
}
