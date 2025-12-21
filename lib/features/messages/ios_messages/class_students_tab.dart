part of '../ios_messages_screen.dart';

class _ClassStudentsTab extends StatefulWidget {
  const _ClassStudentsTab({
    required this.members,
    required this.onAdd,
    required this.onExit,
    required this.onSuspend,
  });

  final Set<String> members;
  final Future<void> Function(BuildContext context) onAdd;
  final void Function(BuildContext context) onExit;
  final void Function(String handle) onSuspend;

  @override
  State<_ClassStudentsTab> createState() => _ClassStudentsTabState();
}

class _ClassStudentsTabState extends State<_ClassStudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> list = widget.members.toList()..sort();

    final List<String> filteredList = _query.isEmpty
        ? list
        : list
              .where(
                (handle) => handle.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    void showStudentActions(String handle) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_search_outlined),
                  title: const Text('View full profile'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(handle: handle),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: const Text('Message'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Messaging $handle…')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Suspend student'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onSuspend(handle);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onAdd(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add student'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide.none,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onExit(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete class'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.85),
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
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: Colors.black.withValues(alpha: 0.55),
                hintText: 'Search students',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No students listed yet',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else if (filteredList.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No students found',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 0,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final String handle = filteredList[index];
                return _StudentCard(
                  handle: handle,
                  index: index,
                  onTap: () => showStudentActions(handle),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.handle,
    required this.index,
    required this.onTap,
  });

  final String handle;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color nameColor = const Color(0xFF111827);
    final Color frameColor = theme.colorScheme.surfaceVariant.withValues(
      alpha: 0.8,
    );

    final String cleanHandle = handle.replaceFirst(RegExp('^@'), '');
    final List<String> parts = cleanHandle
        .split(RegExp(r'[_\.]'))
        .where((p) => p.isNotEmpty)
        .toList();
    final String displayName = parts.isEmpty
        ? cleanHandle
        : parts
              .map(
                (p) => p.length == 1
                    ? p.toUpperCase()
                    : '${p[0].toUpperCase()}${p.substring(1)}',
              )
              .join(' ');
    final String initials = cleanHandle.isEmpty
        ? '--'
        : cleanHandle
              .replaceAll(RegExp(r'[^a-zA-Z]'), '')
              .toUpperCase()
              .padRight(2, cleanHandle[0].toUpperCase())
              .substring(0, 2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: frameColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName.isEmpty ? handle : displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nameColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Removed unused _CollegeHeader widget
