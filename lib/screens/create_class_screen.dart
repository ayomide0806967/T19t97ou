import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../widgets/step_rail.dart'; // no longer used in this screen
import '../widgets/setting_switch_row.dart';
import '../widgets/equal_width_buttons_row.dart';
import '../services/data_service.dart';
import 'ios_messages_screen.dart'
    show College, CollegeResource, CollegeDetailScreen;

/// Create a class flow (4-step wizard) matching the provided reference.
class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Step state
  int _step = 0;

  // Basics
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _facilitator = TextEditingController();
  final TextEditingController _description = TextEditingController();

  // Privacy & roles (set to mirror screenshot defaults)
  bool _isPrivate = true; // on
  bool _adminOnlyPosting = false; // off in screenshot
  bool _approvalRequired = true; // on

  // Features
  bool _allowMedia = false; // off in screenshot

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, 3);
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _facilitator.dispose();
    _description.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_step < 3) {
      setState(() => _step += 1);
    }
  }

  void _goBack() {
    if (_step > 0) setState(() => _step -= 1);
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    final data = context.read<DataService?>();
    final String name = _name.text.trim();
    final String codeRaw = _code.text.trim();
    final String code = codeRaw.isEmpty
        ? name.replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : codeRaw.toUpperCase();
    final String facilitatorRaw = _facilitator.text.trim();
    final String facilitator =
        facilitatorRaw.isEmpty ? 'Admin' : facilitatorRaw;

    debugPrint(
      'Create class: name=$name, code=$code, facilitator=$facilitator',
    );

    if (data != null) {
      // Integrate with your backing store here if desired, e.g.:
      // data.createClass(...);
    }

    final college = College(
      name: name,
      code: code,
      facilitator: facilitator,
      members: 1,
      deliveryMode: _isPrivate ? 'Private' : 'Open',
      upcomingExam: '',
      resources: const <CollegeResource>[],
      memberHandles: <String>{'@yourprofile'},
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CollegeDetailScreen(college: college),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const List<String> stepTitles = ['Basics', 'Privacy & roles', 'Features', 'Review'];

    return Scaffold(
      appBar: AppBar(title: const Text('Create a class')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Stack(
                children: [
                  // Vertical rail line behind all steps
                  Positioned(
                    left: 12, // center under the 24px dot
                    top: 12,  // start just below the first dot
                    right: null,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.black26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < stepTitles.length; i++) ...[
                        // Header row: dot + title
                        Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (i <= _step)
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: 2,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() => _step = i),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: i == _step ? Colors.black : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: i > _step ? Colors.black26 : Colors.black, width: 1),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            color: i == _step ? Colors.white : (i > _step ? Colors.black38 : Colors.black),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stepTitles[i],
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: i == _step ? FontWeight.w700 : FontWeight.w600,
                                            color: i > _step
                                                ? Colors.black45
                                                : theme.colorScheme.onSurface.withValues(alpha: i == _step ? 1.0 : 0.85),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Active step content directly under the number/title
                        if (i == _step) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: _CreateClassStepContent(
                                step: _step,
                                stepTitles: stepTitles,
                                name: _name,
                                code: _code,
                                facilitator: _facilitator,
                                description: _description,
                                isPrivate: _isPrivate,
                                adminOnlyPosting: _adminOnlyPosting,
                                approvalRequired: _approvalRequired,
                                allowMedia: _allowMedia,
                                onChangedPrivacy: (isPrivate, adminOnly, approval) {
                                  setState(() {
                                    _isPrivate = isPrivate;
                                    _adminOnlyPosting = adminOnly;
                                    _approvalRequired = approval;
                                  });
                                },
                                onChangedAllowMedia: (v) => setState(() => _allowMedia = v),
                                onBack: _goBack,
                                onNext: _goNext,
                                onCreate: _create,
                                formKey: _formKey,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: i == _step ? 16 : 32),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateClassStepContent extends StatelessWidget {
  const _CreateClassStepContent({
    required this.step,
    required this.stepTitles,
    required this.name,
    required this.code,
    required this.facilitator,
    required this.description,
    required this.isPrivate,
    required this.adminOnlyPosting,
    required this.approvalRequired,
    required this.allowMedia,
    required this.onChangedPrivacy,
    required this.onChangedAllowMedia,
    required this.onBack,
    required this.onNext,
    required this.onCreate,
    required this.formKey,
  });

  final int step;
  final List<String> stepTitles;

  final TextEditingController name;
  final TextEditingController code;
  final TextEditingController facilitator;
  final TextEditingController description;

  final bool isPrivate;
  final bool adminOnlyPosting;
  final bool approvalRequired;
  final bool allowMedia;

  final void Function(bool isPrivate, bool adminOnly, bool approval) onChangedPrivacy;
  final ValueChanged<bool> onChangedAllowMedia;

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ButtonStyle nextStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );

    final ButtonStyle backStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: theme.colorScheme.surface,
      side: const BorderSide(color: Colors.black, width: 1.2),
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );

    Widget panel(Widget child) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepTitles[step],
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        // Step contents
        if (step == 0) ...[
          panel(
            Theme(
              // Local rectangular text field theme for this panel only
              data: theme.copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 1.8),
                  ),
                ),
                textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
              ),
              child: LayoutBuilder(
                // Basics: responsive grid (2 cols on wide, 1 col on narrow)
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
                            decoration: const InputDecoration(labelText: 'Class name'),
                            style: const TextStyle(color: Colors.black),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a class name' : null,
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: code,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: 'Code (optional)'),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: facilitator,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Facilitator (optional)'),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: description,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(labelText: 'Description (optional)'),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    );
                  }
                  // Single column fallback
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Class name'),
                        style: const TextStyle(color: Colors.black),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a class name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: code,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Code (optional)'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: facilitator,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Facilitator (optional)'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Description (optional)'),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ] else if (step == 1) ...[
          // Privacy & roles: three monochrome switches inside bordered tiles
          panel(
            Column(
              children: [
                SettingSwitchRow(
                  label: 'Private class',
                  subtitle: 'Join via invite only',
                  value: isPrivate,
                  onChanged: (v) => onChangedPrivacy(v, adminOnlyPosting, approvalRequired),
                  monochrome: true,
                ),
                const SizedBox(height: 8),
                SettingSwitchRow(
                  label: 'Only admins can post',
                  subtitle: 'Members can still reply',
                  value: adminOnlyPosting,
                  onChanged: (v) => onChangedPrivacy(isPrivate, v, approvalRequired),
                  monochrome: true,
                ),
                const SizedBox(height: 8),
                SettingSwitchRow(
                  label: 'Approval required for member posts',
                  subtitle: 'Admins receive requests to approve',
                  value: approvalRequired,
                  onChanged: (v) => onChangedPrivacy(isPrivate, adminOnlyPosting, v),
                  monochrome: true,
                ),
              ],
            ),
          ),
        ] else if (step == 2) ...[
          panel(
            SettingSwitchRow(
              label: 'Allow media attachments',
              subtitle: 'Images and files in posts',
              value: allowMedia,
              onChanged: onChangedAllowMedia,
              monochrome: true,
            ),
          ),
        ] else ...[
          // Review: summary
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

        // Controls
        if (step == 0) ...[
          // First page: Back on the left, Next on the right.
          EqualWidthButtonsRow(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: backStyle,
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) onNext();
                },
                style: nextStyle,
                child: const Text('Next'),
              ),
            ],
          ),
        ] else ...[
          EqualWidthButtonsRow(
            children: [
              OutlinedButton(
                onPressed: onBack,
                style: backStyle,
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () {
                  if (step < 3) {
                    onNext();
                  } else {
                    onCreate();
                  }
                },
                style: nextStyle,
                child: Text(step == 3 ? 'Create' : 'Next'),
              ),
            ],
          ),
        ],
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
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: textColorMuted)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
