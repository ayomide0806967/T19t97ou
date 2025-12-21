part of '../ios_messages_screen.dart';

class _ClassHeaderChip extends StatelessWidget {
  const _ClassHeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassesExperience extends StatefulWidget {
  const _ClassesExperience({this.showSearchAndJoin = true});

  final bool showSearchAndJoin;

  @override
  State<_ClassesExperience> createState() => _ClassesExperienceState();
}

class _ClassesExperienceState extends State<_ClassesExperience> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<College> _filteredColleges() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _demoColleges;
    return _demoColleges.where((college) {
      final name = college.name.toLowerCase();
      final facilitator = college.facilitator.toLowerCase();
      final upcoming = college.upcomingExam.toLowerCase();
      return name.contains(query) ||
          facilitator.contains(query) ||
          upcoming.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<College> colleges = _filteredColleges();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSearchAndJoin) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceVariant.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    prefixIconColor: Colors.black.withValues(alpha: 0.55),
                    hintText: 'Search public classes',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join a class',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join a class space with an invite code.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleJoinClass(context),
                            icon: const Icon(Icons.group_add_rounded, size: 22),
                            label: const Text('Join a class'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7DD3E8),
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 14,
                              ),
                              shape: const StadiumBorder(),
                              elevation: 3,
                              textStyle:
                                  theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: ElevatedButton(
                            onPressed: () => _handleCreateClass(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7DD3E8),
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                              elevation: 3,
                            ),
                            child: const Icon(Icons.add, size: 26),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              'Your classes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Grid layout for class cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    (constraints.maxWidth - 12) / 2; // 12 = gap between cards
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (colleges.isEmpty)
                      SizedBox(
                        width: constraints.maxWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'No classes found.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black.withValues(alpha: 0.50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    for (int i = 0; i < colleges.length; i++)
                      SizedBox(
                        width: cardWidth,
                        child: _ModernCollegeCard(
                          college: colleges[i],
                          isDark: i % 2 == 0, // Alternate dark/light
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleCreateClass(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CreateClassScreen()),
  );
}

Future<void> _handleJoinClass(BuildContext context) async {
  final handle = deriveHandleFromEmail(
    context.read<AuthRepository>().currentUser?.email,
    maxLength: 999,
  );
  final code = await _promptForInviteCode(context);
  if (code == null) return;
  final resolved = await InvitesService.resolve(code);
  if (resolved == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.invalidInviteCode)));
    }
    return;
  }
  final match = _demoColleges.firstWhere(
    (c) => c.code.toUpperCase() == resolved.toUpperCase(),
    orElse: () => _demoColleges.first,
  );
  final members = await MembersService.getMembersFor(match.code);
  members.add(handle);
  await MembersService.saveMembersFor(match.code, members);
  if (context.mounted) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _CollegeScreen(college: match)));
  }
}

Future<String?> _promptForInviteCode(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Text(S.enterInviteCode),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'e.g. AB23YZ'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(S.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(S.join),
        ),
      ],
    ),
  );
  return result == null || result.isEmpty ? null : result;
}

// Modern card design matching the reference - alternating dark/light
class _ModernCollegeCard extends StatelessWidget {
  const _ModernCollegeCard({required this.college, required this.isDark});

  final College college;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Colors based on dark/light variant
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
    final pillBgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFF0F0F0);
    final accentColor = const Color(
      0xFF7DD3E8,
    ); // Light cyan/teal for play button

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _CollegeScreen(college: college)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title (class name - truncated to 2 lines)
            Text(
              college.name.split(':').first.trim(), // Get short name
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Facilitator name
            Text(
              college.facilitator.split('•').first.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subtleTextColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            // Bottom row with schedule and play button
            Row(
              children: [
                // Schedule pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pillBgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      college.upcomingExam.isEmpty
                          ? 'Schedule'
                          : college.upcomingExam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtleTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Play/Go button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black87,
                    size: 24,
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
