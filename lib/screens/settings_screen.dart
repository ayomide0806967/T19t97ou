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
    final authUi = ref.watch(authControllerProvider);

    void openPage(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Preferences',
            children: [
              _SettingsNavTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Theme and motion',
                onTap: () => openPage(const _AppearanceSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Push alerts and haptics',
                onTap: () => openPage(const _NotificationSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.dynamic_feed_outlined,
                title: 'Feed',
                subtitle: 'Media and data usage',
                onTap: () => openPage(const _FeedSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.lock_outline,
                title: 'Privacy',
                subtitle: 'Account and presence',
                onTap: () => openPage(const _PrivacySettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.quiz_outlined,
                title: 'Quiz',
                subtitle: 'Explanations and timer sounds',
                onTap: () => openPage(const _QuizSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'App language',
                onTap: () => openPage(const _LanguageSettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Support',
            children: [
              _SettingsNavTile(
                icon: Icons.help_outline,
                title: 'Help',
                subtitle: 'FAQ and support',
                onTap: () =>
                    showComingSoonSnackBar(context, 'Help', popRoute: false),
              ),
              _SettingsNavTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a bug',
                subtitle: 'Send feedback to improve the app',
                onTap: () => showComingSoonSnackBar(
                  context,
                  'Bug report',
                  popRoute: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Data',
            children: [
              _SettingsActionTile(
                icon: Icons.restore_outlined,
                title: 'Reset preferences',
                subtitle: 'Restore default settings',
                onTap: () async {
                  final prefsController =
                      ref.read(appPreferencesControllerProvider.notifier);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset preferences?'),
                      content: const Text(
                        'This resets preferences to their defaults.',
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
              _SettingsActionTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Clear local data',
                subtitle: 'Clears preferences and cached demo data',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear local data?'),
                      content: const Text(
                        'This clears locally stored preferences including login state and theme.',
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
                  if (confirmed != true) return;

                  final repository = LocalAppDataRepository();
                  await repository.clearAllLocalData();
                  if (!context.mounted) return;
                  await ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  await ref
                      .read(appPreferencesControllerProvider.notifier)
                      .resetToDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Local data cleared')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Account',
            children: [
              _SettingsActionTile(
                icon: Icons.logout_outlined,
                title: 'Sign out',
                subtitle: 'Log out of your account',
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
              _SettingsActionTile(
                icon: Icons.delete_outline,
                title: 'Delete account',
                subtitle: 'Permanently delete your account',
                destructive: true,
                onTap: () => showComingSoonSnackBar(
                  context,
                  'Delete account',
                  popRoute: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _SettingsGroup(
            title: 'About',
            children: [
              _SettingsNavTile(
                icon: Icons.info_outline,
                title: 'IN INSTITUTION',
                subtitle: 'Frontend client',
                onTap: null,
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.45 : 0.22);
    final headerColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.72 : 0.64,
    );
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w500,
      color: isDark ? headerColor : Colors.black,
      fontFamily: isDark ? null : 'Roboto',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
          child: Text(
            title.toUpperCase(),
            style: headerStyle,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(children: _withDividers(context, children)),
        ),
      ],
    );
  }

  static List<Widget> _withDividers(
    BuildContext context,
    List<Widget> widgets,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.20),
    );
    final out = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      out.add(widgets[i]);
      if (i != widgets.length - 1) out.add(divider);
    }
    return out;
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconFg = theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.60,
    );
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: isDark ? null : Colors.black,
      fontFamily: isDark ? null : 'Roboto',
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark ? subtle : Colors.black87,
      fontFamily: isDark ? null : 'Roboto',
    );

    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: Icon(icon, size: 22, color: iconFg),
      minLeadingWidth: 0,
      horizontalTitleGap: 6,
      title: Text(
        title,
        style: titleStyle,
      ),
      subtitle: Text(
        subtitle,
        style: subtitleStyle,
      ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: isDark ? null : Colors.black,
            )
          : null,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 2),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg =
        destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.60,
    );
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: isDark
          ? fg
          : (destructive ? theme.colorScheme.error : Colors.black),
      fontFamily: isDark ? null : 'Roboto',
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark ? subtle : Colors.black87,
      fontFamily: isDark ? null : 'Roboto',
    );

    return ListTile(
      enabled: enabled,
      onTap: enabled ? () => onTap() : null,
      leading: Icon(icon, size: 22, color: fg.withValues(alpha: 0.9)),
      minLeadingWidth: 0,
      horizontalTitleGap: 6,
      title: Text(
        title,
        style: titleStyle,
      ),
      subtitle: Text(
        subtitle,
        style: subtitleStyle,
      ),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 2),
    );
  }
}

class _CheckToggleTile extends StatelessWidget {
  const _CheckToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool next) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconFg = theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.60,
    );
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      color: isDark ? null : Colors.black,
      fontFamily: isDark ? null : 'Roboto',
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark ? subtle : Colors.black87,
      fontFamily: isDark ? null : 'Roboto',
    );

    return ListTile(
      enabled: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
      leading: Icon(icon, size: 22, color: iconFg),
      minLeadingWidth: 0,
      horizontalTitleGap: 6,
      title: Text(
        title,
        style: titleStyle,
      ),
      subtitle: Text(
        subtitle,
        style: subtitleStyle,
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: value
            ? const Icon(
                Icons.check_circle_rounded,
                key: ValueKey<String>('on'),
                color: Color(0xFF1D9BF0),
              )
            : Icon(
                Icons.circle_outlined,
                key: const ValueKey<String>('off'),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
      ),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 2),
    );
  }
}

class _AppearanceSettingsScreen extends ConsumerWidget {
  const _AppearanceSettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);

    String labelForThemeMode(ThemeMode mode) => switch (mode) {
          ThemeMode.system => 'System',
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
        };

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Theme',
            children: [
              for (final mode in const [
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ])
                ListTile(
                  title: Text(labelForThemeMode(mode)),
                  trailing: themeMode == mode
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1D9BF0),
                        )
                      : null,
                  onTap: () => ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(mode),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Dark mode',
            children: [
              _CheckToggleTile(
                icon: Icons.nights_stay_outlined,
                title: 'Blackout theme',
                subtitle: (themeMode == ThemeMode.dark || prefs.blackoutTheme)
                    ? 'Pure black background'
                    : 'Turns on when Dark mode is active',
                value: prefs.blackoutTheme,
                onChanged: (next) async {
                  if (next) {
                    await ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                  }
                  await prefsController.setBlackoutTheme(next);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Motion',
            children: [
              _CheckToggleTile(
                icon: Icons.animation_outlined,
                title: 'Reduce motion',
                subtitle: 'Simplify animations across the app',
                value: prefs.reduceMotion,
                onChanged: (next) => prefsController.setReduceMotion(next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsScreen extends ConsumerWidget {
  const _NotificationSettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Alerts',
            children: [
              _CheckToggleTile(
                icon: Icons.notifications_outlined,
                title: 'Enable notifications',
                subtitle: 'Get updates for replies, mentions, and quizzes',
                value: prefs.notificationsEnabled,
                onChanged: (next) =>
                    prefsController.setNotificationsEnabled(next),
              ),
              _CheckToggleTile(
                icon: Icons.volume_up_outlined,
                title: 'Sound',
                subtitle: prefs.notificationsEnabled
                    ? 'Play notification sounds'
                    : 'Enable notifications to change',
                value: prefs.notificationSound,
                enabled: prefs.notificationsEnabled,
                onChanged: (next) => prefsController.setNotificationSound(next),
              ),
              _CheckToggleTile(
                icon: Icons.vibration_outlined,
                title: 'Haptics',
                subtitle: 'Vibrate on important alerts',
                value: prefs.hapticsEnabled,
                onChanged: (next) => prefsController.setHapticsEnabled(next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedSettingsScreen extends ConsumerWidget {
  const _FeedSettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Media',
            children: [
              _CheckToggleTile(
                icon: Icons.play_circle_outline,
                title: 'Autoplay media',
                subtitle: 'Automatically play videos and animations',
                value: prefs.autoplayMedia,
                onChanged: (next) => prefsController.setAutoplayMedia(next),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Data usage',
            children: [
              _CheckToggleTile(
                icon: Icons.data_saver_on_outlined,
                title: 'Data saver',
                subtitle: 'Reduce media usage on cellular networks',
                value: prefs.dataSaver,
                onChanged: (next) => prefsController.setDataSaver(next),
              ),
              _CheckToggleTile(
                icon: Icons.visibility_outlined,
                title: 'Sensitive content',
                subtitle: 'Show posts that may be sensitive',
                value: prefs.showSensitiveContent,
                onChanged: (next) =>
                    prefsController.setShowSensitiveContent(next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacySettingsScreen extends ConsumerWidget {
  const _PrivacySettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Account',
            children: [
              _CheckToggleTile(
                icon: Icons.lock_outline,
                title: 'Private account',
                subtitle: 'Only approved users can follow you',
                value: prefs.privateAccount,
                onChanged: (next) => prefsController.setPrivateAccount(next),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Presence',
            children: [
              _CheckToggleTile(
                icon: Icons.circle_outlined,
                title: 'Show online status',
                subtitle: 'Let others see when you are active',
                value: prefs.showOnlineStatus,
                onChanged: (next) => prefsController.setShowOnlineStatus(next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizSettingsScreen extends ConsumerWidget {
  const _QuizSettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Experience',
            children: [
              _CheckToggleTile(
                icon: Icons.lightbulb_outline,
                title: 'Show explanations',
                subtitle: 'Show answer explanations when available',
                value: prefs.quizShowExplanations,
                onChanged: (next) =>
                    prefsController.setQuizShowExplanations(next),
              ),
              _CheckToggleTile(
                icon: Icons.timer_outlined,
                title: 'Timer sounds',
                subtitle: 'Play sounds for countdown timers',
                value: prefs.quizTimerSounds,
                onChanged: (next) => prefsController.setQuizTimerSounds(next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSettingsScreen extends ConsumerWidget {
  const _LanguageSettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesControllerProvider);
    final prefsController = ref.read(appPreferencesControllerProvider.notifier);

    const languages = ['English', 'French', 'Spanish'];

    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsGroup(
            title: 'Select',
            children: [
              for (final language in languages)
                ListTile(
                  title: Text(language),
                  trailing: prefs.language == language
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1D9BF0),
                        )
                      : null,
                  onTap: () => prefsController.setLanguage(language),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
