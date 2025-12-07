import 'package:flutter/material.dart';

import '../models/activity_user.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

/// Post Activity Screen - Shows engagement stats and list of users who interacted
class PostActivityScreen extends StatefulWidget {
  const PostActivityScreen({
    super.key,
    required this.post,
  });

  final PostModel post;

  static Route<void> route({required PostModel post}) {
    return MaterialPageRoute(
      builder: (_) => PostActivityScreen(post: post),
    );
  }

  @override
  State<PostActivityScreen> createState() => _PostActivityScreenState();
}

class _PostActivityScreenState extends State<PostActivityScreen> {
  late List<ActivityUser> _engagedUsers;
  final Map<String, bool> _followingState = {};

  @override
  void initState() {
    super.initState();
    // Generate demo users based on post id for consistency
    _engagedUsers = ActivityUser.generateDemoUsers(
      8,
      seed: widget.post.id.hashCode,
    );
    for (final user in _engagedUsers) {
      _followingState[user.username] = user.isFollowing;
    }
  }

  void _toggleFollow(String username) {
    setState(() {
      _followingState[username] = !(_followingState[username] ?? false);
    });
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      final formatted = value / 1000000;
      return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final formatted = value / 1000;
      return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = textColor.withValues(alpha: 0.6);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, textColor),
            Divider(height: 1, color: dividerColor),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author info row
                    _buildAuthorRow(theme, textColor, subtleColor),
                    Divider(height: 1, color: dividerColor),
                    
                    // Stats section
                    _buildStatRow(
                      theme,
                      textColor,
                      icon: Icons.favorite_border_rounded,
                      iconColor: Colors.transparent,
                      label: 'Likes',
                      count: widget.post.likes,
                    ),
                    Divider(height: 1, color: dividerColor, indent: 56),
                    _buildStatRow(
                      theme,
                      textColor,
                      icon: Icons.repeat_rounded,
                      iconColor: Colors.transparent,
                      label: 'Reposts',
                      count: widget.post.reposts,
                    ),
                    Divider(height: 1, color: dividerColor, indent: 56),
                    _buildStatRow(
                      theme,
                      textColor,
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: Colors.transparent,
                      label: 'Quotes',
                      count: widget.post.replies,
                    ),
                    Divider(height: 1, color: dividerColor),
                    
                    const SizedBox(height: 8),
                    
                    // Engaged users list
                    ..._engagedUsers.map((user) => _buildUserTile(
                      theme,
                      user,
                      textColor,
                      subtleColor,
                      dividerColor,
                    )),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back,
              size: 24,
              color: textColor,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'Post activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            'Sort',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(ThemeData theme, Color textColor, Color subtleColor) {
    final initials = _getInitials(widget.post.author);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Username + time
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    widget.post.handle.replaceAll('@', ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.post.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtleColor,
                  ),
                ),
              ],
            ),
          ),
          // Reaction emojis
          const Text('✅👍💫', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    Color textColor, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            _formatCount(count),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    ThemeData theme,
    ActivityUser user,
    Color textColor,
    Color subtleColor,
    Color dividerColor,
  ) {
    final isFollowing = _followingState[user.username] ?? false;
    final bool isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with optional badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: user.avatarColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  // Badge (heart indicator)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isDark ? Colors.black : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.username,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.timeAgo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: subtleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtleColor,
                      ),
                    ),
                    if (user.comment != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.comment!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                    if (user.followers > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Stacked avatars
                          SizedBox(
                            width: 32,
                            height: 18,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  child: _miniAvatar(const Color(0xFF4ECDC4)),
                                ),
                                Positioned(
                                  left: 10,
                                  child: _miniAvatar(const Color(0xFFF093FB)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${user.followers} followers',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Follow button
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _toggleFollow(user.username),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? Colors.transparent
                        : (isDark ? Colors.white : Colors.black),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: isFollowing ? 0.3 : 1)
                          : Colors.black.withValues(alpha: isFollowing ? 0.3 : 1),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: isFollowing
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.black : Colors.white),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor, indent: 72),
      ],
    );
  }

  Widget _miniAvatar(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          width: 1.5,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final letters = name.replaceAll(RegExp('[^A-Za-z]'), '');
    if (letters.isEmpty) return 'U';
    return letters.length >= 2
        ? letters.substring(0, 2).toUpperCase()
        : letters.toUpperCase();
  }
}
