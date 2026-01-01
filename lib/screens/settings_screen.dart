import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/app_data_repository.dart';
import '../core/ui/app_preferences_controller.dart';
import '../core/ui/snackbars.dart';
import '../core/ui/theme_mode_controller.dart';
import '../features/auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);
    final authUi = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                subtitle: Text(
                  switch (themeMode) {
                    ThemeMode.system => 'System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  },
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode == null) return;
                      ref
                          .read(themeModeControllerProvider.notifier)
                          .setThemeMode(mode);
                    },
                  ),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation_outlined),
                title: const Text('Reduce motion'),
                subtitle: const Text('Simplify animations across the app'),
                value: prefs.reduceMotion,
                onChanged: (value) => prefsController.setReduceMotion(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Notifications',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Enable notifications'),
                subtitle: const Text(
                  'Get updates for replies, mentions, and quizzes',
                ),
                value: prefs.notificationsEnabled,
                onChanged: (value) =>
                    prefsController.setNotificationsEnabled(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Sound'),
                subtitle: const Text('Play notification sounds'),
                value: prefs.notificationSound,
                onChanged: prefs.notificationsEnabled
                    ? (value) => prefsController.setNotificationSound(value)
                    : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_outlined),
                title: const Text('Haptics'),
                subtitle: const Text('Vibrate on important alerts'),
                value: prefs.hapticsEnabled,
                onChanged: (value) => prefsController.setHapticsEnabled(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Feed',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.play_circle_outline),
                title: const Text('Autoplay media'),
                subtitle: const Text(
                  'Automatically play videos and animations',
                ),
                value: prefs.autoplayMedia,
                onChanged: (value) => prefsController.setAutoplayMedia(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.data_saver_on_outlined),
                title: const Text('Data saver'),
                subtitle: const Text('Reduce media usage on cellular networks'),
                value: prefs.dataSaver,
                onChanged: (value) => prefsController.setDataSaver(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off_outlined),
                title: const Text('Show sensitive content'),
                subtitle: const Text(
                  'Show potentially sensitive posts in the feed',
                ),
                value: prefs.showSensitiveContent,
                onChanged: (value) =>
                    prefsController.setShowSensitiveContent(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Privacy',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: const Text('Private account'),
                subtitle: const Text('Only approved users can follow you'),
                value: prefs.privateAccount,
                onChanged: (value) => prefsController.setPrivateAccount(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.circle_outlined),
                title: const Text('Show online status'),
                subtitle: const Text('Let others see when you are active'),
                value: prefs.showOnlineStatus,
                onChanged: (value) =>
                    prefsController.setShowOnlineStatus(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Quiz',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.lightbulb_outline),
                title: const Text('Show explanations'),
                subtitle: const Text(
                  'Show answer explanations when available',
                ),
                value: prefs.quizShowExplanations,
                onChanged: (value) =>
                    prefsController.setQuizShowExplanations(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.timer_outlined),
                title: const Text('Timer sounds'),
                subtitle: const Text('Play sounds for countdown timers'),
                value: prefs.quizTimerSounds,
                onChanged: (value) => prefsController.setQuizTimerSounds(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'General',
            children: [
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: Text(prefs.language),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: prefs.language,
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'French',
                        child: Text('French'),
                      ),
                      DropdownMenuItem(
                        value: 'Spanish',
                        child: Text('Spanish'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      prefsController.setLanguage(value);
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                subtitle: const Text('FAQ and support'),
                onTap: () =>
                    showComingSoonSnackBar(context, 'Help', popRoute: false),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Report a bug'),
                subtitle: const Text('Send feedback to improve the app'),
                onTap: () => showComingSoonSnackBar(
                  context,
                  'Bug report',
                  popRoute: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('Reset preferences'),
                subtitle: const Text('Restore default settings for toggles'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset preferences?'),
                      content: const Text(
                        'This resets toggle preferences to their defaults.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await prefsController.resetToDefaults();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Clear local data'),
                subtitle: const Text(
                  'Clears preferences and cached demo data',
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear local data?'),
                      content: const Text(
                        'This will clear locally stored preferences including login state and theme.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final repository = LocalAppDataRepository();
                    await repository.clearAllLocalData();
                    if (!context.mounted) return;
                    await ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    await prefsController.resetToDefaults();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Local data cleared')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Sign out'),
                subtitle: const Text('Log out of your account'),
                enabled: !authUi.isLoading,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text('You can sign back in anytime.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('Permanently delete your account'),
                onTap: () => showComingSoonSnackBar(
                  context,
                  'Delete account',
                  popRoute: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SectionCard(
            title: 'About',
            children: [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('In institution'),
                subtitle: Text('Frontend demo build'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Divider(height: 1),
          ..._withDividers(children),
        ],
      ),
    );
  }

  static List<Widget> _withDividers(List<Widget> widgets) {
    final out = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      out.add(widgets[i]);
      if (i != widgets.length - 1) out.add(const Divider(height: 1));
    }
    return out;
  }
}
