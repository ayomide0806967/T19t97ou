import 'package:flutter/material.dart';

/// Live quiz monitor screen.
///
/// This screen lets the instructor see, in real time:
/// - Who is online and taking the quiz
/// - Who has submitted
/// - Who is offline / not started
/// - For each participant: how many questions answered and which question
///   they are currently on.
class QuizLiveMonitorScreen extends StatefulWidget {
  const QuizLiveMonitorScreen({
    super.key,
    required this.quizTitle,
  });

  final String quizTitle;

  @override
  State<QuizLiveMonitorScreen> createState() => _QuizLiveMonitorScreenState();
}

enum ParticipantStatus {
  inProgress,
  submitted,
  offline,
  suspect,
  terminated,
}

class LiveParticipant {
  LiveParticipant({
    required this.name,
    required this.id,
    required this.status,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.answeredCount,
    required this.lastSeen,
  });

  final String name;
  final String id;
  final ParticipantStatus status;
  final int currentQuestion;
  final int totalQuestions;
  final int answeredCount;
  final DateTime lastSeen;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  double get progress =>
      totalQuestions == 0 ? 0 : answeredCount.clamp(0, totalQuestions) / totalQuestions;
}

class _QuizLiveMonitorScreenState extends State<QuizLiveMonitorScreen> {
  late final List<LiveParticipant> _participants;
  String _filter = 'all'; // all, online, submitted, offline
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Sample data – replace with real-time data from backend.
    final now = DateTime.now();
    _participants = <LiveParticipant>[
      LiveParticipant(
        name: 'Marcel',
        id: 'M1',
        status: ParticipantStatus.inProgress,
        currentQuestion: 8,
        totalQuestions: 20,
        answeredCount: 7,
        lastSeen: now.subtract(const Duration(seconds: 5)),
      ),
      LiveParticipant(
        name: 'Becky',
        id: 'B2',
        status: ParticipantStatus.submitted,
        currentQuestion: 20,
        totalQuestions: 20,
        answeredCount: 20,
        lastSeen: now.subtract(const Duration(minutes: 2)),
      ),
      LiveParticipant(
        name: 'Tara',
        id: 'T3',
        status: ParticipantStatus.inProgress,
        currentQuestion: 4,
        totalQuestions: 20,
        answeredCount: 3,
        lastSeen: now.subtract(const Duration(seconds: 20)),
      ),
      LiveParticipant(
        name: 'Andrew',
        id: 'A4',
        status: ParticipantStatus.terminated,
        currentQuestion: 0,
        totalQuestions: 20,
        answeredCount: 0,
        lastSeen: now.subtract(const Duration(minutes: 15)),
      ),
      LiveParticipant(
        name: 'Mia',
        id: 'M5',
        status: ParticipantStatus.submitted,
        currentQuestion: 20,
        totalQuestions: 20,
        answeredCount: 20,
        lastSeen: now.subtract(const Duration(minutes: 5)),
      ),
      LiveParticipant(
        name: 'Robin',
        id: 'R6',
        status: ParticipantStatus.suspect,
        currentQuestion: 15,
        totalQuestions: 20,
        answeredCount: 14,
        lastSeen: now.subtract(const Duration(seconds: 10)),
      ),
    ];
  }

  int get _onlineCount =>
      _participants.where((p) => p.status == ParticipantStatus.inProgress).length;

  int get _submittedCount =>
      _participants.where((p) => p.status == ParticipantStatus.submitted).length;

  int get _offlineCount =>
      _participants.where((p) => p.status == ParticipantStatus.offline).length;

  int get _suspectCount =>
      _participants.where((p) => p.status == ParticipantStatus.suspect).length;

  int get _terminatedCount =>
      _participants.where((p) => p.status == ParticipantStatus.terminated).length;

  List<LiveParticipant> get _filteredParticipants {
    final String query = _searchController.text.trim().toLowerCase();

    Iterable<LiveParticipant> filtered = _participants;

    switch (_filter) {
      case 'online':
        filtered =
            filtered.where((p) => p.status == ParticipantStatus.inProgress);
        break;
      case 'submitted':
        filtered =
            filtered.where((p) => p.status == ParticipantStatus.submitted);
        break;
      case 'offline':
        filtered = filtered.where((p) => p.status == ParticipantStatus.offline);
        break;
      case 'suspect':
        filtered =
            filtered.where((p) => p.status == ParticipantStatus.suspect);
        break;
      case 'terminated':
        filtered =
            filtered.where((p) => p.status == ParticipantStatus.terminated);
        break;
      case 'all':
      default:
        break;
    }

    if (query.isEmpty) {
      return filtered.toList();
    }

    return filtered
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quizTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_participants.length} participants · $_onlineCount online',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatusChip(
                      label: 'Online',
                      count: _onlineCount,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Submitted',
                      count: _submittedCount,
                      color: const Color(0xFF075E54),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Offline',
                      count: _offlineCount,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        value: 'all',
                        groupValue: _filter,
                        onSelected: _onFilterChanged,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Online',
                        value: 'online',
                        groupValue: _filter,
                        onSelected: _onFilterChanged,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Submitted',
                        value: 'submitted',
                        groupValue: _filter,
                        onSelected: _onFilterChanged,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Offline',
                        value: 'offline',
                        groupValue: _filter,
                        onSelected: _onFilterChanged,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Suspect',
                        value: 'suspect',
                        groupValue: _filter,
                        onSelected: _onFilterChanged,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Terminated',
                        value: 'terminated',
                        groupValue: _filter,
                        onSelected: _onFilterChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search participants',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.8),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF9CA3AF),
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _filteredParticipants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final participant = _filteredParticipants[index];
                return _ParticipantTile(
                  participant: participant,
                  onTap: () => _openParticipantDetails(context, participant),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onFilterChanged(String value) {
    setState(() => _filter = value);
  }

  void _openParticipantDetails(BuildContext context, LiveParticipant p) {
    final theme = Theme.of(context);
    final int remaining =
        (p.totalQuestions - p.answeredCount).clamp(0, p.totalQuestions);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      p.initials,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel(p.status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _statusColor(theme, p.status)
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DetailMetric(
                    label: 'Answered',
                    value: '${p.answeredCount}/${p.totalQuestions}',
                  ),
                  const SizedBox(width: 16),
                  _DetailMetric(
                    label: 'Current question',
                    value: p.currentQuestion == 0
                        ? 'Not started'
                        : '${p.currentQuestion}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _DetailMetric(
                    label: 'Remaining',
                    value: '$remaining',
                  ),
                  const SizedBox(width: 16),
                  _DetailMetric(
                    label: 'Last seen',
                    value: _timeAgo(p.lastSeen),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (alertCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            title: const Text('Send nudge?'),
                            content: Text(
                              'This will send a gentle reminder to ${p.name}.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(alertCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(alertCtx).pop(true),
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Nudge sent to ${p.name}.'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: Text(
                        'Send nudge',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (alertCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            title: const Text('Pause this quiz?'),
                            content: Text(
                              'This will temporarily pause the quiz for ${p.name}.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(alertCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(alertCtx).pop(true),
                                child: const Text('Pause'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Quiz paused for ${p.name}.'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.pause_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        'Pause',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (alertCtx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          title: const Text('Terminate this attempt?'),
                          content: Text(
                            'This will end ${p.name}\'s quiz immediately and flag it for malpractice.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(alertCtx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(alertCtx).pop(true),
                              child: const Text(
                                'Terminate',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      setState(() {
                        final index = _participants.indexWhere(
                          (participant) => participant.id == p.id,
                        );
                        if (index != -1) {
                          final existing = _participants[index];
                          _participants[index] = LiveParticipant(
                            name: existing.name,
                            id: existing.id,
                            status: ParticipantStatus.terminated,
                            currentQuestion: existing.currentQuestion,
                            totalQuestions: existing.totalQuestions,
                            answeredCount: existing.answeredCount,
                            lastSeen: existing.lastSeen,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                            'Attempt terminated and flagged for malpractice for ${p.name}.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.report_gmailerrorred_outlined,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: const Text(
                      'Terminate (malpractice)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.inProgress:
        return 'Online · In progress';
      case ParticipantStatus.submitted:
        return 'Submitted';
      case ParticipantStatus.offline:
        return 'Offline';
      case ParticipantStatus.suspect:
        return 'Suspect activity';
      case ParticipantStatus.terminated:
        return 'Terminated';
    }
  }

  Color _statusColor(ThemeData theme, ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.inProgress:
        return Colors.green;
      case ParticipantStatus.submitted:
        return const Color(0xFF075E54);
      case ParticipantStatus.offline:
        return theme.colorScheme.onSurface.withValues(alpha: 0.55);
      case ParticipantStatus.suspect:
        return Colors.orange;
      case ParticipantStatus.terminated:
        return Colors.red;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$count $label',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool selected = value == groupValue;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: const Color(0xFF075E54).withValues(alpha: 0.12),
      side: BorderSide(
        color: selected
            ? const Color(0xFF075E54)
            : theme.dividerColor.withValues(alpha: 0.7),
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? const Color(0xFF075E54)
              : theme.dividerColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.onTap,
  });

  final LiveParticipant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = _statusColor(theme, participant.status);
    final String statusLabel = _statusLabel(participant.status);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                child: Text(
                  participant.initials,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Answered ${participant.answeredCount}/${participant.totalQuestions}'
                      '${participant.currentQuestion > 0 ? ' · Q ${participant.currentQuestion}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: participant.progress,
                        minHeight: 4,
                        backgroundColor:
                            theme.dividerColor.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(participant.progress * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.inProgress:
        return 'Online · In progress';
      case ParticipantStatus.submitted:
        return 'Submitted';
      case ParticipantStatus.offline:
        return 'Offline';
      case ParticipantStatus.suspect:
        return 'Suspect activity';
      case ParticipantStatus.terminated:
        return 'Terminated';
    }
  }

  Color _statusColor(ThemeData theme, ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.inProgress:
        return Colors.green;
      case ParticipantStatus.submitted:
        return const Color(0xFF075E54);
      case ParticipantStatus.offline:
        return theme.colorScheme.onSurface.withValues(alpha: 0.5);
      case ParticipantStatus.suspect:
        return Colors.orange;
      case ParticipantStatus.terminated:
        return Colors.red;
    }
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
