part of 'quiz_live_monitor_screen.dart';

mixin _QuizLiveMonitorScreenBuild
    on _QuizLiveMonitorScreenStateBase, _QuizLiveMonitorScreenActions {
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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
}
