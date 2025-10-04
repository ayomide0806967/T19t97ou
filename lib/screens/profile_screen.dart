import 'package:flutter/material.dart';

import '../services/simple_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/tweet_shell.dart';
import 'quote_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posts = _profilePosts;

    void showToast(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
    }

    void handleFollow() => showToast('You are now following Alex');
    void handleMessage() => showToast('Messaging coming soon');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Profile', style: theme.textTheme.headlineSmall),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(onPrimaryAction: handleFollow, onSecondaryAction: handleMessage),
                  const SizedBox(height: 32),
                  _ProfileTabs(
                    selectedIndex: _selectedTab,
                    onChanged: (index) {
                      setState(() => _selectedTab = index);
                    },
                  ),
                  const SizedBox(height: 24),
                  ...posts.map(
                    (post) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _ProfilePostCard(post: post),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onPrimaryAction, required this.onSecondaryAction});

  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = SimpleAuthService();
    final email = auth.currentUserEmail ?? 'user@institution.edu';

    return TweetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HexagonAvatar(
                size: 110,
                child: Center(
                  child: Text(
                    _initialsFrom(email),
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alex Rivera', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('@productlead • ${email.toLowerCase()}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Building human-centred platforms for students, faculty, and researchers. Product Lead at IN-Institution, previously design fellow at Hume Labs.',
            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary, height: 1.6),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _PillTag('Product Strategy'),
              _PillTag('Accessibility'),
              _PillTag('Leadership'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              _ProfileStat(value: '18.4K', label: 'Followers'),
              SizedBox(width: 32),
              _ProfileStat(value: '1.2K', label: 'Following'),
              SizedBox(width: 32),
              _ProfileStat(value: '342', label: 'Moments'),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimaryAction,
                  child: const Text('Follow'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondaryAction,
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.labelLarge?.copyWith(fontSize: 18, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = ['Moments', 'Highlights', 'Bookmarks'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_tabs.length, (index) {
        final isSelected = index == selectedIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) => onChanged(index),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.accent.withValues(alpha: 0.12),
              shape: const StadiumBorder(),
              side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.divider),
            ),
          ),
        );
      }),
    );
  }
}

class _ProfilePostCard extends StatefulWidget {
  const _ProfilePostCard({required this.post});

  final _ProfilePost post;

  @override
  State<_ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<_ProfilePostCard> {
  late int replies = widget.post.replies;
  late int reposts = widget.post.reposts;
  late int likes = widget.post.likes;
  late int views = widget.post.views;
  late int bookmarks = widget.post.bookmarks;

  bool liked = false;
  bool bookmarked = false;
  bool reposted = false;

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _handleAction(_MetricType type) {
    switch (type) {
      case _MetricType.reply:
        setState(() => replies += 1);
        _showToast(context, 'Reply composer coming soon');
        break;
      case _MetricType.rein:
        _showReinDropdown();
        break;
      case _MetricType.like:
        setState(() {
          liked = !liked;
          likes += liked ? 1 : -1;
        });
        break;
      case _MetricType.view:
        setState(() => views += 1);
        _showToast(context, 'Insights panel coming soon');
        break;
      case _MetricType.bookmark:
        setState(() {
          bookmarked = !bookmarked;
          bookmarks += bookmarked ? 1 : -1;
        });
        break;
      case _MetricType.share:
        _showToast(context, 'Share sheet coming soon');
        break;
    }
  }

  void _showReinDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildReinDropdownItem(
                    icon: Icons.repeat_rounded,
                    title: 'Re-institute',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        reposted = !reposted;
                        reposts += reposted ? 1 : -1;
                      });
                      _showToast(context, reposted ? 'Re-instituted!' : 'Removed re-institution');
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildReinDropdownItem(
                    icon: Icons.format_quote_rounded,
                    title: 'Quote',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QuoteScreen(
                            author: widget.post.author,
                            handle: '@profile',
                            timeAgo: widget.post.meta,
                            body: widget.post.body,
                            initials: _initialsFrom(widget.post.author),
                            tags: widget.post.tags,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  _buildReinDropdownItem(
                    icon: Icons.close_rounded,
                    title: 'Cancel',
                    color: const Color(0xFF64748B),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReinDropdownItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? const Color(0xFF2D3748);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: itemColor,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metrics = [
      _TweetMetricData(type: _MetricType.reply, icon: Icons.chat_rounded, count: replies),
      _TweetMetricData(type: _MetricType.rein, icon: Icons.swap_vertical_circle, count: reposts, isActive: reposted),
      _TweetMetricData(type: _MetricType.like, icon: liked ? Icons.favorite : Icons.favorite_border, count: likes, isActive: liked),
      _TweetMetricData(type: _MetricType.view, icon: Icons.visibility_outlined, count: views),
      _TweetMetricData(type: _MetricType.bookmark, icon: bookmarked ? Icons.bookmark : Icons.bookmark_border, count: bookmarks, isActive: bookmarked),
      const _TweetMetricData(type: _MetricType.share, icon: Icons.open_in_new_outlined),
    ];

    return TweetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HexagonAvatar(
                size: 56,
                child: Center(
                  child: Text(
                    _initialsFrom(widget.post.author),
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.author, style: theme.textTheme.labelLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(widget.post.meta, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showToast(context, 'Post options coming soon'),
                icon: const Icon(Icons.more_horiz, color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.post.body,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary, height: 1.6),
          ),
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.post.tags.map((tag) => _PillTag(tag)).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              for (final metric in metrics)
                Flexible(
                  flex: metric.count != null ? 2 : 1,
                  child: _TweetMetric(data: metric, onTap: () => _handleAction(metric.type)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TweetMetricData {
  const _TweetMetricData({
    required this.type,
    required this.icon,
    this.count,
    this.isActive = false,
  });

  final _MetricType type;
  final IconData icon;
  final int? count;
  final bool isActive;
}

class _TweetMetric extends StatelessWidget {
  const _TweetMetric({required this.data, required this.onTap});

  final _TweetMetricData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRein = data.type == _MetricType.rein;
    final color = data.isActive ? AppTheme.accent : AppTheme.textSecondary;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );

    Widget child = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRein)
            Text(
              'Re-in',
              style: textStyle?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            )
          else
            Icon(data.icon, size: 20, color: color),
          if (data.count != null) ...[
            const SizedBox(width: 4),
            Text(
              _formatMetric(data.count!),
              style: textStyle?.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );

    if (isRein) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: data.isActive ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
            border: data.isActive
              ? Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1)
              : null,
          ),
          child: child,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: child,
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600),
      backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
  }
}

enum _MetricType { reply, rein, like, view, bookmark, share }

class _ProfilePost {
  const _ProfilePost({
    required this.author,
    required this.meta,
    required this.body,
    required this.replies,
    required this.reposts,
    required this.likes,
    required this.views,
    required this.bookmarks,
    this.tags = const <String>[],
  });

  final String author;
  final String meta;
  final String body;
  final int replies;
  final int reposts;
  final int likes;
  final int views;
  final int bookmarks;
  final List<String> tags;
}

const List<_ProfilePost> _profilePosts = [
  _ProfilePost(
    author: 'DesignOps',
    meta: 'Shared • 3h ago',
    body:
        'Kicked off our typography study group today. Loved seeing fellow students collaborate on creating scalable design systems for their labs.',
    tags: ['Design Systems', 'Workshops'],
    replies: 24,
    reposts: 18,
    likes: 204,
    views: 15200,
    bookmarks: 31,
  ),
  _ProfilePost(
    author: 'Campus Labs',
    meta: 'Featured • 1d ago',
    body:
        'Alex led the beta launch of the Research Atlas. Minimal interface, streamlined filters, and context-aware bookmarking built entirely in Flutter.',
    tags: ['Product Launch', 'Research'],
    replies: 38,
    reposts: 22,
    likes: 420,
    views: 20100,
    bookmarks: 46,
  ),
  _ProfilePost(
    author: 'IN-Institution',
    meta: 'Mentioned • 2d ago',
    body:
        'Sharing gratitude for Alex and the team for crafting a calmer, more intentional social platform. The typography-forward approach resonates across campus.',
    tags: ['Community', 'Impact'],
    replies: 19,
    reposts: 14,
    likes: 312,
    views: 17800,
    bookmarks: 27,
  ),
];

String _initialsFrom(String value) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

String _formatMetric(int value) {
  if (value >= 1000000) {
    final formatted = value / 1000000;
    return formatted >= 10 ? '${formatted.toStringAsFixed(0)}M' : '${formatted.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final formatted = value / 1000;
    return formatted >= 10 ? '${formatted.toStringAsFixed(0)}K' : '${formatted.toStringAsFixed(1)}K';
  }
  return value.toString();
}
