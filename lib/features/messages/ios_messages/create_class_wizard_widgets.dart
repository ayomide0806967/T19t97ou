part of '../ios_messages_screen.dart';

class _CreateClassStepContent extends StatelessWidget {
  const _CreateClassStepContent({
    required this.theme,
    required this.step,
    required this.name,
    required this.code,
    required this.facilitator,
    required this.description,
    required this.isPrivate,
    required this.adminOnlyPosting,
    required this.approvalRequired,
    required this.allowMedia,
    required this.onBack,
    required this.onNext,
    required this.onCreate,
    required this.formKey,
    required this.stepTitles,
  });

  final ThemeData theme;
  final int step;
  final TextEditingController name;
  final TextEditingController code;
  final TextEditingController facilitator;
  final TextEditingController description;
  final bool isPrivate;
  final bool adminOnlyPosting;
  final bool approvalRequired;
  final bool allowMedia;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  final GlobalKey<FormState> formKey;
  final List<String> stepTitles;

  @override
  Widget build(BuildContext context) {
    Widget panel(Widget child) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
          ),
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepTitles[step],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (step == 0) ...[
          panel(
            Theme(
              data: theme.copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.8,
                    ),
                  ),
                ),
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Colors.black,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, inner) {
                  final twoCols = inner.maxWidth >= 520;
                  if (twoCols) {
                    final double col = (inner.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: name,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Class name',
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter a class name'
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: code,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Code (optional)',
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: facilitator,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Facilitator (optional)',
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: description,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Class name',
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a class name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: code,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Code (optional)',
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: facilitator,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Facilitator (optional)',
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ] else if (step == 1) ...[
          SettingSwitchRow(
            label: 'Private class',
            subtitle: 'Join via invite only',
            value: isPrivate,
            onChanged: (_) {},
          ),
          SettingSwitchRow(
            label: 'Only admins can post',
            subtitle: 'Members can still reply',
            value: adminOnlyPosting,
            onChanged: (_) {},
          ),
          SettingSwitchRow(
            label: 'Approval required for member posts',
            subtitle: 'Admins receive requests to approve',
            value: approvalRequired,
            onChanged: (_) {},
          ),
        ] else if (step == 2) ...[
          SettingSwitchRow(
            label: 'Allow media attachments',
            subtitle: 'Images and files in posts',
            value: allowMedia,
            onChanged: (_) {},
          ),
        ] else ...[
          _ReviewSummary(
            name: name.text.trim(),
            code: code.text.trim(),
            facilitator: facilitator.text.trim(),
            description: description.text.trim(),
            isPrivate: isPrivate,
            adminOnlyPosting: adminOnlyPosting,
            approvalRequired: approvalRequired,
            allowMedia: allowMedia,
          ),
        ],
        const SizedBox(height: 16),
        if (step == 0)
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) onNext();
                },
                child: const Text('Next'),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (step < 3) {
                    onNext();
                  } else {
                    onCreate();
                  }
                },
                child: Text(step == 3 ? 'Create' : 'Next'),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.name,
    required this.code,
    required this.facilitator,
    required this.description,
    required this.isPrivate,
    required this.adminOnlyPosting,
    required this.approvalRequired,
    required this.allowMedia,
  });

  final String name;
  final String code;
  final String facilitator;
  final String description;
  final bool isPrivate;
  final bool adminOnlyPosting;
  final bool approvalRequired;
  final bool allowMedia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColorMuted = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColorMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Class name', name),
        row('Code', code),
        row('Facilitator / Admin', facilitator),
        row('Description', description),
        const SizedBox(height: 8),
        Divider(color: theme.dividerColor.withValues(alpha: 0.25)),
        const SizedBox(height: 8),
        row('Private class', isPrivate ? 'On' : 'Off'),
        row('Only admins can post', adminOnlyPosting ? 'On' : 'Off'),
        row('Approval required', approvalRequired ? 'On' : 'Off'),
        row('Media attachments', allowMedia ? 'On' : 'Off'),
      ],
    );
  }
}

// Removed unused _ClassStatChip widget

// Removed unused _TweetCard widget

// Removed unused _TweetStat widget

// Removed unused _TweetMessage model

const List<_Conversation> _demoConversations = <_Conversation>[];

// Quiz screens exist separately; access via header quiz icon.

/// Public wrapper so other parts of the app (e.g. quiz dashboard)
/// can navigate to the class detail experience using the same layout.
// (moved to ios_messages/college_screen_state.dart)



// (moved to ios_messages/class_feed_tab.dart)
