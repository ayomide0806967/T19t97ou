part of '../ios_messages_screen.dart';

class _ClassActionCard extends StatelessWidget {
  const _ClassActionCard({
    required this.title,
    required this.onTap,
    required this.backgroundColor,
    this.playIconColor = Colors.black,
  });

  final String title;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color playIconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: playIconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed legacy _ActiveTopicCard: details are now surfaced in the class header
// and a compact "Move to Library" pill above the discussion instead of a full card.

class _StartLectureCard extends StatefulWidget {
  const _StartLectureCard({required this.onStart});
  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onStart;
  @override
  State<_StartLectureCard> createState() => _StartLectureCardState();
}

/// Full-page lecture setup experience, opened from the "CREATE LECTURE NOTE"
/// button on the class feed. Wraps the existing _StartLectureCard in a
/// dedicated screen with a black aesthetic banner.
class _LectureSetupPage extends StatelessWidget {
  const _LectureSetupPage({
    required this.college,
    required this.onStartLecture,
  });

  final College college;
  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onStartLecture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // WhatsApp-style header green for the create-lecture page.
    const Color bannerColor = Color(0xFF075E54);
    final Color bannerText = Colors.white;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top black banner with class context and description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                college.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: bannerText.withValues(alpha: 0.75),
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a lecture note',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: bannerText,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Set up the course, tutor, topic, and access before you start posting notes in real time.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: bannerText.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Lecture setup form
            Expanded(
              child: SingleChildScrollView(
                // Push the form closer to the vertical middle on
                // taller screens while remaining scrollable.
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                child: _LectureSetupForm(
                  onSubmit: (course, tutor, topic, settings) async {
                    // Notify parent to mark the topic as active
                    onStartLecture(course, tutor, topic, settings);
                    // Then take the user straight into the note creation flow
                    final summary = await Navigator.of(context)
                        .push<ClassNoteSummary>(
                          MaterialPageRoute(
                            builder: (_) => TeacherNoteCreationScreen(
                              topic: topic,
                              subtitle: tutor.isNotEmpty ? tutor : course,
                              attachQuizForNote: settings.attachQuizForNote,
                            ),
                          ),
                        );
                    if (!context.mounted) return;
                    Navigator.of(context).pop<ClassNoteSummary>(summary);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boxed lecture setup form that mirrors the "Create Lecture" note style.
class _LectureSetupForm extends StatefulWidget {
  const _LectureSetupForm({required this.onSubmit});

  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onSubmit;

  @override
  State<_LectureSetupForm> createState() => _LectureSetupFormState();
}

class _LectureSetupFormState extends State<_LectureSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _tutorController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  int _step = 0; // 0 = details, 1 = privacy
  bool _privateLecture = false;
  bool _requirePin = false;
  bool _attachQuizForNote = false;
  DateTime? _autoArchiveAt;

  @override
  void dispose() {
    _courseController.dispose();
    _tutorController.dispose();
    _topicController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// Simple, stable time picker that avoids the Material
  /// time picker layout bug on some devices by using a
  /// Cupertino-style wheel in a custom bottom sheet.
  Future<TimeOfDay?> _pickTimeSheet(
    BuildContext context,
    TimeOfDay initial,
  ) async {
    TimeOfDay temp = initial;
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String formatTime(TimeOfDay t) {
          final int hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
          final String minute = t.minute.toString().padLeft(2, '0');
          final String period = t.period == DayPeriod.am ? 'AM' : 'PM';
          return '$hour:$minute $period';
        }

        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      Text(
                        'Select time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(temp),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Large, centered time preview for better readability.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Builder(
                    builder: (_) => StatefulBuilder(
                      builder: (context, setLocalState) {
                        // This StatefulBuilder is only used to refresh
                        // the preview text when the wheel changes.
                        return Text(
                          formatTime(temp),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      2020,
                      1,
                      1,
                      initial.hour,
                      initial.minute,
                    ),
                    use24hFormat: false,
                    onDateTimeChanged: (dt) {
                      final next = TimeOfDay(hour: dt.hour, minute: dt.minute);
                      if (next == temp) return;
                      temp = next;
                      // Rebuild the preview text only.
                      (ctx as Element).markNeedsBuild();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (!context.mounted) return;
    if (date == null) return;
    final time = await _pickTimeSheet(
      context,
      TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (!context.mounted) return;
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _autoArchiveAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final course = _courseController.text.trim();
    final tutor = _tutorController.text.trim();
    final topic = _topicController.text.trim();
    final settings = _TopicSettings(
      privateLecture: _privateLecture,
      requirePin: _requirePin,
      pinCode: _requirePin ? _pinController.text.trim() : null,
      autoArchiveAt: _autoArchiveAt,
      attachQuizForNote: _attachQuizForNote,
    );
    widget.onSubmit(course, tutor, topic, settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.black, width: 1.8),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini stepper header showing 1 and 2
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: _StepRailMini(activeIndex: _step, steps: const ['1', '2']),
            ),
          ),
          if (_step == 0) ...[
            // Step 1: Lecture details
            Text(
              'Lecture details',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Theme(
                data: theme.copyWith(
                  inputDecorationTheme: inputTheme,
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.black,
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _courseController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Course name',
                        hintText: 'e.g., Biology 401 · Genetics',
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter course name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tutorController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Tutor name (optional)',
                        hintText: 'e.g., Dr. Tayo Ajayi',
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _topicController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g., Mendelian inheritance, DNA structure',
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter topic' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Next button (step 1 of 2)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _step = 1);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Next'),
              ),
            ),
          ] else ...[
            // Step 2: Access & privacy
            Text(
              'Access & privacy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
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
                  SettingSwitchRow(
                    label: 'Private lecture (disable repost)',
                    value: _privateLecture,
                    onChanged: (v) => setState(() => _privateLecture = v),
                    monochrome: true,
                  ),
                  SettingSwitchRow(
                    label: 'Require PIN to access',
                    value: _requirePin,
                    onChanged: (v) => setState(() => _requirePin = v),
                    monochrome: true,
                  ),
                  SettingSwitchRow(
                    label: 'Add quiz for note',
                    value: _attachQuizForNote,
                    onChanged: (v) => setState(() => _attachQuizForNote = v),
                    monochrome: true,
                  ),
                  if (_requirePin) ...[
                    const SizedBox(height: 6),
                    Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: inputTheme,
                        textSelectionTheme: const TextSelectionThemeData(
                          cursorColor: Colors.black,
                        ),
                      ),
                      child: TextFormField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'PIN code',
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (v) {
                          if (!_requirePin) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a PIN code';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Auto-archive', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      if (_autoArchiveAt != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _autoArchiveAt = null),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                  if (_autoArchiveAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _autoArchiveAt!.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: const Color(0xFF075E54),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _pickDateTime(context),
                      child: const Text('Date/time'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Back + Start buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 0),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start lecture'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StartLectureCardState extends State<_StartLectureCard> {
  final _course = TextEditingController();
  final _tutor = TextEditingController();
  final _topic = TextEditingController();
  bool _expanded = true;
  int _step = 0;
  bool _privateLecture = false;
  bool _requirePin = false;
  final TextEditingController _pin = TextEditingController();
  DateTime? _autoArchiveAt;

  bool get _canStart =>
      _course.text.trim().isNotEmpty && _topic.text.trim().isNotEmpty;

  @override
  void dispose() {
    _course.dispose();
    _tutor.dispose();
    _topic.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0F1114) : Colors.white;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.28 : 0.18,
    );
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Start a lecture',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              _StepRailMini(activeIndex: _step, steps: const ['1', '2']),
              const Spacer(),
              IconButton(
                tooltip: _expanded ? 'Collapse' : 'Expand',
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            if (_step == 0) ...[
              TextField(
                controller: _course,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(labelText: 'Course name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tutor,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  labelText: 'Tutor name (optional)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _topic,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(labelText: 'Topic'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canStart) setState(() => _step = 1);
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Create a lecture topic and start posting notes.',
                      style: theme.textTheme.bodySmall?.copyWith(color: meta),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _canStart
                        ? () => setState(() => _step = 1)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              SettingSwitchRow(
                label: 'Private lecture (disable repost)',
                value: _privateLecture,
                onChanged: (v) => setState(() => _privateLecture = v),
                monochrome: true,
              ),
              SettingSwitchRow(
                label: 'Require PIN to access',
                value: _requirePin,
                onChanged: (v) => setState(() => _requirePin = v),
                monochrome: true,
              ),
              if (_requirePin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(
                    controller: _pin,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(labelText: 'PIN code'),
                  ),
                ),
              const SizedBox(height: 6),
              // Auto-archive controls: label above, buttons below in one row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date/time', style: theme.textTheme.bodyMedium),
                  if (_autoArchiveAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _autoArchiveAt!.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final date = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: DateTime(now.year + 2),
                            );
                            if (!context.mounted) return;
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                now.add(const Duration(hours: 1)),
                              ),
                            );
                            if (!context.mounted) return;
                            if (time == null) return;
                            final dt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() => _autoArchiveAt = dt);
                          },
                          child: const Text('Date/time'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () =>
                              setState(() => _autoArchiveAt = null),
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom action buttons aligned on one horizontal line
              EqualWidthButtonsRow(
                height: 40,
                gap: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => setState(() => _step = 0),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Back', maxLines: 1),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: _canStart
                        ? () => widget.onStart(
                            _course.text.trim(),
                            _tutor.text.trim(),
                            _topic.text.trim(),
                            _TopicSettings(
                              privateLecture: _privateLecture,
                              requirePin: _requirePin,
                              pinCode: _requirePin ? _pin.text.trim() : null,
                              autoArchiveAt: _autoArchiveAt,
                            ),
                          )
                        : null,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Start', maxLines: 1),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
