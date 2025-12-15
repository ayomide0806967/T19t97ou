import 'package:flutter/material.dart';

class QuizAnswersScreen extends StatefulWidget {
  const QuizAnswersScreen({
    super.key,
    required this.quizTitle,
    this.totalAnswers,
  });

  final String quizTitle;
  final int? totalAnswers;

  @override
  State<QuizAnswersScreen> createState() => _QuizAnswersScreenState();
}

class _QuizAnswersScreenState extends State<QuizAnswersScreen> {
  int _bottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color scaffold = theme.scaffoldBackgroundColor;
    final List<_AnswerRowModel> answers =
        _buildSampleAnswers(total: widget.totalAnswers ?? 61);
    final List<_AnswerRowModel> toppers = (answers.toList()
          ..sort((a, b) => b.percent.compareTo(a.percent)))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: scaffold,
      appBar: AppBar(
        title: Text(widget.quizTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter options coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More actions coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: answers.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TopToppersRow(toppers: toppers);
          }
          final row = answers[index - 1];
          return _AnswerCard(model: row);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (index) {
          setState(() => _bottomIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download coming soon')),
              );
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publish coming soon')),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Answers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_download_outlined),
            label: 'Download',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            label: 'Publish',
          ),
        ],
      ),
    );
  }
}

class _TopToppersRow extends StatelessWidget {
  const _TopToppersRow({required this.toppers});

  final List<_AnswerRowModel> toppers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.45 : 0.35);
    final List<_AnswerRowModel> items =
        toppers.length >= 3 ? toppers.take(3).toList() : toppers;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            Expanded(
              child: _TopperTile(
                rank: index + 1,
                name: items[index].name,
                percent: items[index].percent,
              ),
            ),
            if (index != items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _TopperTile extends StatelessWidget {
  const _TopperTile({
    required this.rank,
    required this.name,
    required this.percent,
  });

  final int rank;
  final String name;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color badgeColor = switch (rank) {
      1 => const Color(0xFF075E54), // WhatsApp green
      2 => Colors.cyan, // cyan for top 2
      3 => Colors.red, // red for top 3
      _ => theme.colorScheme.primary,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RectProfilePic(name: name),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w400,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Top $rank',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RectProfilePic extends StatelessWidget {
  const _RectProfilePic({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.55 : 0.35);
    final String initials = _initials(name);

    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.20),
            theme.colorScheme.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.take(1).toString();
  final last = parts.length > 1 ? parts.last.characters.take(1).toString() : '';
  return (first + last).toUpperCase();
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.model});

  final _AnswerRowModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.40 : 0.30);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
      color: isDark ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${model.number}. ${model.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${model.percent}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              model.dateText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const _StatusChip(),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: (model.percent.clamp(0, 100)) / 100.0,
                        backgroundColor: isDark
                            ? colorScheme.onSurface.withValues(alpha: 0.10)
                            : const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF075E54),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color green = Color(0xFF075E54);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: green),
        const SizedBox(width: 6),
        Text(
          'Evaluated',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? theme.colorScheme.onSurface : green,
          ),
        ),
      ],
    );
  }
}

class _PercentRing extends StatelessWidget {
  const _PercentRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color track = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.10)
        : const Color(0xFFE5E7EB);
    const Color blue = Color(0xFF2563EB);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (percent.clamp(0, 100)) / 100.0,
            strokeWidth: 5,
            backgroundColor: track,
            color: blue,
          ),
          Text(
            '$percent%',
            style: theme.textTheme.labelLarge?.copyWith(
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerRowModel {
  const _AnswerRowModel({
    required this.number,
    required this.name,
    required this.percent,
    required this.dateText,
  });

  final int number;
  final String name;
  final int percent;
  final String dateText;
}

List<_AnswerRowModel> _buildSampleAnswers({
  required int total,
}) {
  final names = <String>[
    'Hassana',
    'KETURAH',
    'Dap',
    'Safiya Muhammad',
    'Maryam',
    'Amina',
    'Joseph',
    'Emmanuel',
    'Blessing',
    'Samuel',
  ];

  final now = DateTime.now();
  final all = List<_AnswerRowModel>.generate(total, (index) {
    final number = total - index;
    final name = names[index % names.length];
    final percent = (92 - (index * 3)) % 101;
    final dt = now.subtract(Duration(minutes: (index + 1) * 37));
    final dateText = _formatDateTime(dt);
    return _AnswerRowModel(
      number: number,
      name: name,
      percent: percent < 0 ? percent + 101 : percent,
      dateText: dateText,
    );
  });

  return all;
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final dd = value.day.toString().padLeft(2, '0');
  final mm = months[value.month - 1];
  final yyyy = value.year.toString();

  int hour = value.hour;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  final hh = hour.toString().padLeft(2, '0');
  final min = value.minute.toString().padLeft(2, '0');
  return '$dd $mm $yyyy, $hh:$min $suffix';
}
