part of '../ios_messages_screen.dart';

class _CreateClassPage extends StatefulWidget {
  const _CreateClassPage({this.initialStep = 0});

  final int initialStep;

  @override
  State<_CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<_CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _facilitator = TextEditingController();
  final TextEditingController _description = TextEditingController();
  late int _step; // 0 = basics, 1 = settings
  bool _isPrivate = true;
  bool _adminOnlyPosting = true;
  bool _approvalRequired = false;
  bool _allowMedia = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _facilitator.dispose();
    _description.dispose();
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    final String name = _name.text.trim();
    final String codeRaw = _code.text.trim();
    final String code = codeRaw.isEmpty
        ? name.replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : codeRaw.toUpperCase();
    final String facilitator = _facilitator.text.trim().isEmpty
        ? 'Admin'
        : _facilitator.text.trim();

    final College result = College(
      name: name,
      code: code,
      facilitator: facilitator,
      members: 1,
      deliveryMode: _isPrivate ? 'Private' : 'Open',
      upcomingExam: '',
      resources: const <CollegeResource>[],
      memberHandles: <String>{'@yourprofile'},
      lectureNotes: const <LectureNote>[],
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const List<String> stepTitles = [
      'Basics',
      'Privacy & roles',
      'Features',
      'Review',
    ];

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
                    left: 12,
                    top: 12,
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
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
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
                                        child: _StepDot(
                                          active: i == _step,
                                          label: '${i + 1}',
                                          size: 24,
                                          dimmed: i > _step,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stepTitles[i],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: i == _step
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: i > _step
                                                    ? Colors.black45
                                                    : theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: i == _step
                                                                ? 1.0
                                                                : 0.85,
                                                          ),
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
                                theme: theme,
                                step: _step,
                                name: _name,
                                code: _code,
                                facilitator: _facilitator,
                                description: _description,
                                isPrivate: _isPrivate,
                                adminOnlyPosting: _adminOnlyPosting,
                                approvalRequired: _approvalRequired,
                                allowMedia: _allowMedia,
                                onBack: () => setState(() => _step -= 1),
                                onNext: () => setState(() => _step += 1),
                                onCreate: _create,
                                formKey: _formKey,
                                stepTitles: stepTitles,
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

