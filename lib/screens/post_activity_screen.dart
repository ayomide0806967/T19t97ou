import 'package:flutter/material.dart';

import '../models/activity_user.dart';
import '../models/post.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/icons/x_retweet_icon.dart';

/// Post Activity Screen - Shows engagement stats and list of users who interacted
class PostActivityScreen extends StatefulWidget {
  const PostActivityScreen({super.key, required this.post});

  final PostModel post;

  static Route<void> route({required PostModel post}) {
    return MaterialPageRoute(builder: (_) => PostActivityScreen(post: post));
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
    // Start with an empty list; real data should come from backend.
    _engagedUsers = const <ActivityUser>[];
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
    final Color surface = theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color subtleColor = onSurface.withValues(alpha: 0.6);
    final Color dividerColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.18 : 0.35,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Post activity'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Sort',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorRow(theme, onSurface, subtleColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          theme,
                          onSurface,
                          leading: Icon(
                            Icons.favorite_border_rounded,
                            size: 20,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                          label: 'Likes',
                          count: widget.post.likes,
                        ),
                        Divider(height: 1, color: dividerColor, indent: 56),
                        _buildStatRow(
                          theme,
                          onSurface,
                          leading: XRetweetIcon(
                            size: 20,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                          label: 'Reposts',
                          count: widget.post.reposts,
                        ),
                        Divider(height: 1, color: dividerColor, indent: 56),
                        _buildStatRow(
                          theme,
                          onSurface,
                          leading: Icon(
                            Icons.format_quote_outlined,
                            size: 20,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                          label: 'Quotes',
                          count: widget.post.replies,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList.separated(
            itemCount: _engagedUsers.length,
            separatorBuilder: (_, index) => Padding(
              padding: const EdgeInsets.only(left: 72),
              child: Divider(height: 1, color: dividerColor),
            ),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildUserTile(
                theme,
                _engagedUsers[index],
                onSurface,
                subtleColor,
                dividerColor,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(ThemeData theme, Color textColor, Color subtleColor) {
    final initials = _getInitials(widget.post.author);

    return Row(
      children: [
        // Avatar
        HexagonAvatar(
          size: 44,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
          borderWidth: 1.5,
          child: Center(
            child: Text(
              initials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
                style: theme.textTheme.bodySmall?.copyWith(color: subtleColor),
              ),
            ],
          ),
        ),
        // Reaction emojis
        Text('✅👍💫', style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    Color textColor, {
    required Widget leading,
    required String label,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 40, child: Center(child: leading)),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
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

    final Color followBg = isFollowing
        ? Colors.transparent
        : (isDark ? Colors.white : Colors.black);
    final Color followFg = isFollowing
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.black : Colors.white);
    final BorderSide followBorder = BorderSide(
      color: (isDark ? Colors.white : Colors.black).withValues(
        alpha: isFollowing ? 0.28 : 1,
      ),
      width: 1,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with optional badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            HexagonAvatar(
              size: 44,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
              borderWidth: 1.5,
              child: Center(
                child: Text(
                  user.initials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
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
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.favorite, size: 10, color: Colors.white),
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
              const SizedBox(height: 2),
              Text(
                user.displayName,
                style: theme.textTheme.bodySmall?.copyWith(color: subtleColor),
              ),
              if (user.comment != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.comment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.25,
                  ),
                ),
              ],
              if (user.followers > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
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

        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _toggleFollow(user.username),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: followBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.fromBorderSide(followBorder),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: theme.textTheme.bodySmall?.copyWith(
                color: followFg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
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
