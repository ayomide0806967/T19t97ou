import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Minimalist iOS-style messages inbox page.
class IosMinimalistMessagePage extends StatefulWidget {
  const IosMinimalistMessagePage({super.key});

  @override
  State<IosMinimalistMessagePage> createState() =>
      _IosMinimalistMessagePageState();
}

class _IosMinimalistMessagePageState extends State<IosMinimalistMessagePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background = Colors.white;
    final List<_Conversation> filtered = _filteredConversations();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _MessagesHeader(theme: theme),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final conversation = filtered[index];
                  return _ConversationTile(conversation: conversation);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemCount: filtered.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Conversation> _filteredConversations() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _demoConversations;
    return _demoConversations
        .where(
          (conversation) =>
              conversation.name.toLowerCase().contains(query) ||
              conversation.lastMessage.toLowerCase().contains(query),
        )
        .toList();
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = const Color(0xFF1C274C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _HeaderIcon(
            icon: CupertinoIcons.pencil,
            onTap: () {},
            color: iconColor,
          ),
          const Spacer(),
          Text(
            'Messages',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: iconColor,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          _HeaderIcon(
            icon: CupertinoIcons.add,
            onTap: () {},
            color: iconColor,
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Icon(icon, size: 24, color: color),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color nameColor = const Color(0xFF1C274C);
    final Color messageColor = const Color(0xFF64748B);

    return Material(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConversationAvatar(initials: conversation.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: nameColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          conversation.timeLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: messageColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: messageColor,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: conversation.unreadCount),
                        ],
                      ],
                    ),
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

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFCFD8FF), Color(0xFFE7EAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF1C274C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5CFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Conversation {
  const _Conversation({
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
  });

  final String name;
  final String initials;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;
}

const List<_Conversation> _demoConversations = <_Conversation>[
  _Conversation(
    name: 'Hannah Nguyen',
    initials: 'HN',
    lastMessage: 'Sending now. Also, meeting moved to 10:30.',
    timeLabel: '09:22',
  ),
  _Conversation(
    name: 'Nursing Study Group',
    initials: 'NS',
    lastMessage: 'Practice test starts at 4pm today.',
    timeLabel: 'Sun',
    unreadCount: 5,
  ),
  _Conversation(
    name: 'Wale Adebayo',
    initials: 'WA',
    lastMessage: 'On my way 🚍',
    timeLabel: '08:55',
    unreadCount: 2,
  ),
  _Conversation(
    name: 'Hadiza Umar',
    initials: 'HU',
    lastMessage: 'I shared the doc.',
    timeLabel: 'Yesterday',
  ),
  _Conversation(
    name: 'Sam Obi',
    initials: 'SO',
    lastMessage: 'Lol true 😂',
    timeLabel: 'Sat',
  ),
  _Conversation(
    name: 'Maria Idowu',
    initials: 'MI',
    lastMessage: 'Voice note (0:23)',
    timeLabel: 'Fri',
    unreadCount: 1,
  ),
];
