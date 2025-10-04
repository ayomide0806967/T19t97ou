import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/tweet_shell.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedTab = 0;

  final List<Chat> _chats = [
    Chat(
      name: 'Design Team',
      message: 'Sarah: Great work on the new prototypes! 🎨',
      time: '2m ago',
      unread: 3,
      isOnline: true,
      isGroup: true,
      members: 5,
      lastMessage: 'Sarah',
    ),
    Chat(
      name: 'Dr. Maya Chen',
      message: 'The research paper looks excellent. Can we discuss...',
      time: '15m ago',
      unread: 1,
      isOnline: true,
      isGroup: false,
    ),
    Chat(
      name: 'Study Group - CS301',
      message: 'Alex: Anyone up for a review session tomorrow?',
      time: '1h ago',
      unread: 0,
      isOnline: false,
      isGroup: true,
      members: 8,
      lastMessage: 'Alex',
    ),
    Chat(
      name: 'Student Government',
      message: 'Meeting tomorrow at 3 PM in the main hall',
      time: '2h ago',
      unread: 12,
      isOnline: true,
      isGroup: true,
      members: 15,
      lastMessage: 'System',
    ),
    Chat(
      name: 'Career Services',
      message: 'Your resume has been selected for the internship program!',
      time: '3h ago',
      unread: 1,
      isOnline: false,
      isGroup: false,
    ),
    Chat(
      name: 'Photography Club',
      message: 'Emma: Check out these photos from yesterday\'s event! 📸',
      time: '5h ago',
      unread: 0,
      isOnline: false,
      isGroup: true,
      members: 12,
      lastMessage: 'Emma',
    ),
    Chat(
      name: 'Michael Park',
      message: 'Thanks for the help with the project!',
      time: '1d ago',
      unread: 0,
      isOnline: false,
      isGroup: false,
    ),
    Chat(
      name: 'Library Announcements',
      message: 'New study spaces available on the 3rd floor',
      time: '2d ago',
      unread: 0,
      isOnline: false,
      isGroup: true,
      members: 500,
      lastMessage: 'System',
    ),
  ];

  final List<OnlineUser> _onlineUsers = [
    OnlineUser(name: 'Sarah Chen', status: 'Available', avatar: 'SC'),
    OnlineUser(name: 'Alex Rivera', status: 'In a meeting', avatar: 'AR'),
    OnlineUser(name: 'Emma Wilson', status: 'Available', avatar: 'EW'),
    OnlineUser(name: 'James Kim', status: 'Away', avatar: 'JK'),
    OnlineUser(name: 'Lisa Park', status: 'Available', avatar: 'LP'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildTabs(),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        _buildChatsList(),
                        _buildOnlineUsers(),
                        _buildGroupsList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Messages',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_rounded,
              color: AppTheme.accent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: 'All',
              isActive: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
              badge: '16',
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Online',
              isActive: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
              badge: '5',
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Groups',
              isActive: _selectedTab == 2,
              onTap: () => setState(() => _selectedTab = 2),
              badge: '3',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return _ChatTile(chat: chat);
      },
    );
  }

  Widget _buildOnlineUsers() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _onlineUsers.length,
      itemBuilder: (context, index) {
        final user = _onlineUsers[index];
        return _OnlineUserTile(user: user);
      },
    );
  }

  Widget _buildGroupsList() {
    final groupChats = _chats.where((chat) => chat.isGroup).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groupChats.length,
      itemBuilder: (context, index) {
        final chat = groupChats[index];
        return _ChatTile(chat: chat);
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.2) : AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    HexagonAvatar(
                      size: 56,
                      backgroundColor: chat.isGroup ? AppTheme.accent : AppTheme.surface,
                      child: Center(
                        child: Icon(
                          chat.isGroup ? Icons.group_rounded : Icons.person_rounded,
                          color: chat.isGroup ? Colors.white : AppTheme.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    if (chat.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            chat.time,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.message,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (chat.unread > 0)
                            Container(
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  chat.unread > 99 ? '99+' : chat.unread.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (chat.isGroup)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 12,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${chat.members} members',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _OnlineUserTile extends StatelessWidget {
  const _OnlineUserTile({required this.user});

  final OnlineUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    HexagonAvatar(
                      size: 56,
                      child: Center(
                        child: Text(
                          user.avatar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: user.status == 'Available'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.status,
                        style: TextStyle(
                          color: user.status == 'Available'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class Chat {
  const Chat({
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.isGroup,
    this.members,
    this.lastMessage,
  });

  final String name;
  final String message;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isGroup;
  final int? members;
  final String? lastMessage;
}

class OnlineUser {
  const OnlineUser({
    required this.name,
    required this.status,
    required this.avatar,
  });

  final String name;
  final String status;
  final String avatar;
}