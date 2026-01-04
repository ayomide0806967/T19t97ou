import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz.dart';
import '../application/quiz_providers.dart';
import '../results/quiz_correction_screen.dart';

enum _AnswerSortOption {
  alphabet,
  submitTime,
  notEvaluated,
  evaluated,
  percentageAscending,
  percentageDescending,
}

enum _DateFilter {
  lifetime,
  last24Hours,
  last7Days,
  last30Days,
}

enum _TextMatch {
  contains,
  equals,
}

class _QuestionFilter {
  const _QuestionFilter({
    required this.questionIndex,
    required this.match,
    required this.value,
  });

  final int questionIndex;
  final _TextMatch match;
  final String value;
}

class _FilterConfig {
  const _FilterConfig({
    required this.dateFilter,
    required this.questionFilters,
  });

  final _DateFilter dateFilter;
  final List<_QuestionFilter> questionFilters;
}

class QuizAnswersScreen extends ConsumerStatefulWidget {
  const QuizAnswersScreen({
    super.key,
    required this.quizTitle,
    this.totalAnswers,
  });

  final String quizTitle;
  final int? totalAnswers;

  @override
  ConsumerState<QuizAnswersScreen> createState() => _QuizAnswersScreenState();
}

class _QuizAnswersScreenState extends ConsumerState<QuizAnswersScreen> {
  int _bottomIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  _AnswerSortOption _sortOption = _AnswerSortOption.percentageDescending;
  _DateFilter _dateFilter = _DateFilter.lifetime;
  final List<_QuestionFilter> _questionFilters = <_QuestionFilter>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _isSearching = !_isSearching);
    if (!_isSearching) {
      _searchController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _openCorrection(_AnswerRowModel model) {
    final quizSource = ref.read(quizSourceProvider);
    final questions =
        quizSource.questionsForTitle(widget.quizTitle) ??
        quizSource.sampleQuestions;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizCorrectionScreen(
          questions: questions,
          responses: model.responses,
          totalTime: const Duration(minutes: 10),
          remainingTime: const Duration(minutes: 2),
        ),
      ),
    );
  }

  String _sortLabel(_AnswerSortOption option) {
    return switch (option) {
      _AnswerSortOption.alphabet => 'Alphabet',
      _AnswerSortOption.submitTime => 'Submit Time',
      _AnswerSortOption.notEvaluated => 'Not evaluated',
      _AnswerSortOption.evaluated => 'Evaluated',
      _AnswerSortOption.percentageAscending => 'Percentage - Ascending',
      _AnswerSortOption.percentageDescending => 'Percentage - Descending',
    };
  }

  Future<void> _showSortSheet() async {
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<_AnswerSortOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort by',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in _AnswerSortOption.values) ...[
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _sortOption == option
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 22,
                      color: _sortOption == option
                          ? const Color(0xFFFFB066)
                          : Colors.black.withValues(alpha: 0.12),
                    ),
                    title: Text(
                      _sortLabel(option),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                  if (option != _AnswerSortOption.values.last)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => _sortOption = selected);
  }

  String _dateLabel(_DateFilter option) {
    return switch (option) {
      _DateFilter.lifetime => 'Lifetime',
      _DateFilter.last24Hours => 'Last 24 hours',
      _DateFilter.last7Days => 'Last 7 days',
      _DateFilter.last30Days => 'Last 30 days',
    };
  }

  String _matchLabel(_TextMatch match) {
    return switch (match) {
      _TextMatch.contains => 'Contains',
      _TextMatch.equals => 'Equals',
    };
  }

  String _truncate(String text, {int max = 24}) {
    final value = text.trim();
    if (value.length <= max) return value;
    return '${value.substring(0, max - 3)}...';
  }

  String _filterSummary(QuizTakeQuestion question, _QuestionFilter filter) {
    return '${_truncate(question.prompt)} • ${_matchLabel(filter.match)} • ${_truncate(filter.value)}';
  }

  Future<void> _showFilterDialog(List<QuizTakeQuestion> questions) async {
    final theme = Theme.of(context);
    _DateFilter tempDate = _dateFilter;
    final List<_QuestionFilter> tempQuestionFilters =
        List<_QuestionFilter>.of(_questionFilters);
    int? tempQuestionIndex;
    _TextMatch tempMatch = _TextMatch.contains;
    String? tempValue;

    final result = await showDialog<_FilterConfig>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            const InputDecorationTheme fieldDecorationTheme =
                InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            );
            const MenuStyle dropdownMenuStyle = MenuStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              surfaceTintColor:
                  WidgetStatePropertyAll<Color>(Colors.transparent),
            );
            final selectedQuestion = (tempQuestionIndex != null &&
                    tempQuestionIndex! >= 0 &&
                    tempQuestionIndex! < questions.length)
                ? questions[tempQuestionIndex!]
                : null;
            final options = selectedQuestion?.options ?? const <String>[];

            void addFilter() {
              if (tempQuestionIndex == null || tempValue == null) return;
              final idx = tempQuestionIndex!;
              final value = tempValue!.trim();
              if (idx < 0 || idx >= questions.length || value.isEmpty) return;
              setLocalState(() {
                tempQuestionFilters.add(
                  _QuestionFilter(
                    questionIndex: idx,
                    match: tempMatch,
                    value: value,
                  ),
                );
                tempQuestionIndex = null;
                tempValue = null;
                tempMatch = _TextMatch.contains;
              });
            }

            const logoOrange = Color(0xFFFFB066);
            final ButtonStyle primaryButtonStyle =
                ElevatedButton.styleFrom(
              backgroundColor: logoOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );
            final ButtonStyle outlineButtonStyle =
                OutlinedButton.styleFrom(
              foregroundColor: logoOrange,
              side: const BorderSide(color: logoOrange, width: 1),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        border: Border.all(
                          color: const Color(0xFF60A5FA),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Results',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Lifetime',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Filter by date',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownMenu<_DateFilter>(
                      initialSelection: tempDate,
                      onSelected: (v) {
                        if (v == null) return;
                        setLocalState(() => tempDate = v);
                      },
                      dropdownMenuEntries: _DateFilter.values
                          .map(
                            (v) => DropdownMenuEntry<_DateFilter>(
                              value: v,
                              label: _dateLabel(v),
                            ),
                          )
                          .toList(),
                      menuStyle: dropdownMenuStyle,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      inputDecorationTheme: fieldDecorationTheme,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Filter by Question',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownMenu<int?>(
                      initialSelection: tempQuestionIndex,
                      onSelected: (v) {
                        setLocalState(() {
                          tempQuestionIndex = v;
                          tempValue = null;
                        });
                      },
                      dropdownMenuEntries: <DropdownMenuEntry<int?>>[
                        const DropdownMenuEntry<int?>(
                          value: null,
                          label: 'Select a question',
                        ),
                        ...List.generate(
                          questions.length,
                          (i) => DropdownMenuEntry<int?>(
                            value: i,
                            label: '${i + 1}. ${_truncate(questions[i].prompt)}',
                          ),
                        ),
                      ],
                      menuStyle: dropdownMenuStyle,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      inputDecorationTheme: fieldDecorationTheme,
                    ),
                    const SizedBox(height: 10),
                    DropdownMenu<_TextMatch>(
                      initialSelection: tempMatch,
                      onSelected: (v) {
                        if (v == null) return;
                        setLocalState(() => tempMatch = v);
                      },
                      dropdownMenuEntries: _TextMatch.values
                          .map(
                            (v) => DropdownMenuEntry<_TextMatch>(
                              value: v,
                              label: _matchLabel(v),
                            ),
                          )
                          .toList(),
                      menuStyle: dropdownMenuStyle,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      inputDecorationTheme: fieldDecorationTheme,
                    ),
                    const SizedBox(height: 10),
                    DropdownMenu<String>(
                      enabled: selectedQuestion != null,
                      initialSelection: tempValue,
                      onSelected: (v) => setLocalState(() => tempValue = v),
                      dropdownMenuEntries: options
                          .map(
                            (opt) => DropdownMenuEntry<String>(
                              value: opt,
                              label: _truncate(opt),
                            ),
                          )
                          .toList(),
                      menuStyle: dropdownMenuStyle,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      inputDecorationTheme: fieldDecorationTheme,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          onPressed: addFilter,
                          style: primaryButtonStyle,
                          child: const Text('Add Filter'),
                        ),
                      ),
                    ),
                    if (tempQuestionFilters.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (int i = 0; i < tempQuestionFilters.length; i++)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filterSummary(
                                  questions[tempQuestionFilters[i].questionIndex],
                                  tempQuestionFilters[i],
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setLocalState(
                                () => tempQuestionFilters.removeAt(i),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: outlineButtonStyle,
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(
                              _FilterConfig(
                                dateFilter: tempDate,
                                questionFilters: tempQuestionFilters,
                              ),
                            ),
                            style: primaryButtonStyle,
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _dateFilter = result.dateFilter;
      _questionFilters
        ..clear()
        ..addAll(result.questionFilters);
    });
  }

  Future<void> _showDownloadOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download results as',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Excel'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Excel download coming soon')),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('PDF'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('PDF download coming soon')),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Word'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Word download coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime? _cutoffFor(_DateFilter filter) {
    final now = DateTime.now();
    return switch (filter) {
      _DateFilter.lifetime => null,
      _DateFilter.last24Hours => now.subtract(const Duration(hours: 24)),
      _DateFilter.last7Days => now.subtract(const Duration(days: 7)),
      _DateFilter.last30Days => now.subtract(const Duration(days: 30)),
    };
  }

  List<_AnswerRowModel> _filterAndSortAnswers(
    List<_AnswerRowModel> all,
    List<QuizTakeQuestion> questions,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<_AnswerRowModel> items = all;

    final cutoff = _cutoffFor(_dateFilter);
    if (cutoff != null) {
      items = items.where((a) => a.submittedAt.isAfter(cutoff));
    }

    if (query.isNotEmpty) {
      items = items.where(
        (a) =>
            a.name.toLowerCase().contains(query) ||
            a.percent.toString().contains(query),
      );
    }

    for (final filter in _questionFilters) {
      if (filter.questionIndex < 0) continue;
      if (filter.questionIndex >= questions.length) continue;
      final q = questions[filter.questionIndex];
      items = items.where((a) {
        final selectedIndex = a.responses[filter.questionIndex];
        if (selectedIndex == null) return false;
        if (selectedIndex < 0 || selectedIndex >= q.options.length) return false;
        final selectedText = q.options[selectedIndex];
        final needle = filter.value.toLowerCase();
        final hay = selectedText.toLowerCase();
        return switch (filter.match) {
          _TextMatch.contains => hay.contains(needle),
          _TextMatch.equals => hay == needle,
        };
      });
    }

    List<_AnswerRowModel> list() => items.toList();

    return switch (_sortOption) {
      _AnswerSortOption.alphabet => list()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      _AnswerSortOption.submitTime => list()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt)),
      _AnswerSortOption.notEvaluated => items.where((a) => !a.evaluated).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt)),
      _AnswerSortOption.evaluated => items.where((a) => a.evaluated).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt)),
      _AnswerSortOption.percentageAscending => list()
        ..sort((a, b) => a.percent.compareTo(b.percent)),
      _AnswerSortOption.percentageDescending => list()
        ..sort((a, b) => b.percent.compareTo(a.percent)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color scaffold = theme.scaffoldBackgroundColor;
    final quizSource = ref.watch(quizSourceProvider);
    final questions =
        quizSource.questionsForTitle(widget.quizTitle) ??
        quizSource.sampleQuestions;
    final List<_AnswerRowModel> allAnswers =
        _buildSampleAnswers(
          total: widget.totalAnswers ?? 61,
          questions: questions,
        );
    final List<_AnswerRowModel> answers = _filterAndSortAnswers(allAnswers, questions);
    final List<_AnswerRowModel> toppers = (answers.toList()
          ..sort((a, b) => b.percent.compareTo(a.percent)))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: scaffold,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search students...',
                  border: InputBorder.none,
                ),
              )
            : Text(widget.quizTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              _showFilterDialog(questions);
            },
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showSortSheet();
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: answers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TopToppersRow(toppers: toppers);
          }
          final row = answers[index - 1];
          return _AnswerCard(
            model: row,
            onTap: () => _openCorrection(row),
          );
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
              _showDownloadOptions();
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
    final Color badgeColor = switch (rank) {
      1 => const Color(0xFFD9B99B),
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
  const _AnswerCard({required this.model, required this.onTap});

  final _AnswerRowModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.40 : 0.30);
    const Color progressColor = Color(0xFFD9B99B);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: border),
      ),
      color: isDark ? colorScheme.surface : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
          child: Row(
            children: [
              _PercentArc(percent: model.percent, color: progressColor),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${model.number}. ${model.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
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
                    _StatusChip(evaluated: model.evaluated),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.evaluated});

  final bool evaluated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color evaluatedBlue = Colors.cyan;
    const Color notEvaluatedGray = Color(0xFF111827);
    final Color textColor = evaluated
        ? evaluatedBlue
        : (isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.75)
            : notEvaluatedGray);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          evaluated ? Icons.check_circle : Icons.error_outline_rounded,
          size: 14,
          color: textColor,
        ),
        const SizedBox(width: 6),
        Text(
          evaluated ? 'Evaluated' : 'Not evaluated',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _PercentArc extends StatelessWidget {
  const _PercentArc({
    required this.percent,
    required this.color,
  });

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color track = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.10)
        : const Color(0xFFE5E7EB);

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (percent.clamp(0, 100)) / 100.0,
            strokeWidth: 6,
            backgroundColor: track,
            color: color,
          ),
          Text(
            '$percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
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
    required this.submittedAt,
    required this.evaluated,
    required this.responses,
  });

  final int number;
  final String name;
  final int percent;
  final String dateText;
  final DateTime submittedAt;
  final bool evaluated;
  final Map<int, int> responses;
}

List<_AnswerRowModel> _buildSampleAnswers({
  required int total,
  required List<QuizTakeQuestion> questions,
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
    final dt = now.subtract(Duration(minutes: (index + 1) * 37));
    final evaluated = (index % 4) != 0;
    int correct = 0;
    final responses = <int, int>{};
    for (int qIndex = 0; qIndex < questions.length; qIndex++) {
      final q = questions[qIndex];
      final selected = (index + qIndex) % q.options.length;
      responses[qIndex] = selected;
      if (selected == q.answerIndex) correct += 1;
    }
    final int percent = questions.isEmpty
        ? 0
        : ((correct / questions.length) * 100).round().clamp(0, 100);
    final dateText = _formatDateTime(dt);
    return _AnswerRowModel(
      number: number,
      name: name,
      percent: percent,
      dateText: dateText,
      submittedAt: dt,
      evaluated: evaluated,
      responses: responses,
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
