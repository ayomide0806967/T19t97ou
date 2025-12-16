import 'package:flutter/material.dart';

import 'create_class_screen.dart';
import 'ios_messages_screen.dart';
import 'quiz_create_screen.dart';

class MessagesHubScreen extends StatelessWidget {
  const MessagesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface =
        isDark ? const Color(0xFF0E0F12) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            _HubCard(
              title: 'Continue to inbox',
              subtitle: 'Open your conversations and class channels.',
              icon: Icons.mail_outline_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IosMinimalistMessagePage()),
              ),
            ),
            const SizedBox(height: 16),
            _HubCard(
              title: 'Create new class',
              subtitle: 'Set up a new class space.',
              icon: Icons.class_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateClassScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HubCard(
              title: 'Create new quiz',
              subtitle: 'Launch the step-by-step builder for a fresh quiz.',
              icon: Icons.create_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuizCreateScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.2);
    final Color subtitleColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

