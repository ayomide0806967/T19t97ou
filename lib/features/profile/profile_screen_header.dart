part of 'profile_screen.dart';

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.headerImage,
    required this.headerImageUrl,
    required this.profileImage,
    required this.profileImageUrl,
    required this.initials,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.readOnly,
    required this.onProfileImageTap,
    required this.onHeaderTap,
    required this.onChangeCover,
    required this.onEditProfile,
    required this.onMessage,
    required this.onToggleFollow,
    required this.isFollowingOther,
    required this.onNotifications,
    required this.onMore,
    required this.followersCount,
    required this.followingCount,
    required this.likesCount,
    required this.activityLevelLabel,
    required this.activityProgress,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
  final String? headerImageUrl;
  final String? profileImageUrl;
  final String initials;
  final String displayName;
  final String handle;
  final String bio;
  final bool readOnly;
  final VoidCallback onProfileImageTap;
  final VoidCallback onHeaderTap;
  final VoidCallback onChangeCover;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onToggleFollow;
  final bool isFollowingOther;
  final VoidCallback onNotifications;
  final VoidCallback onMore;
  final int followersCount;
  final int followingCount;
  final int likesCount;
  final String activityLevelLabel;
  final double activityProgress;

  static String _formatCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final k = value / 1000.0;
      final text = k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return '${text}K';
    }
    final m = value / 1000000.0;
    final text = m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1);
    return '${text}M';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.58);
    const Color coverPlaceholderColor = Color(0xFFFFD3B0);

    final double screenWidth = MediaQuery.of(context).size.width;
    const double coverHeight = 200;
    const double avatarSize = 96;

    final ImageProvider<Object>? coverProvider = headerImage != null
        ? MemoryImage(headerImage!)
        : (headerImageUrl != null && headerImageUrl!.isNotEmpty
            ? NetworkImage(headerImageUrl!)
            : null);

    final ImageProvider<Object>? avatarProvider = profileImage != null
        ? MemoryImage(profileImage!)
        : (profileImageUrl != null && profileImageUrl!.isNotEmpty
            ? NetworkImage(profileImageUrl!)
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width cover image with extended hit area for overlapping avatar
        SizedBox(
          width: screenWidth,
          height: coverHeight + avatarSize / 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover image layer
              GestureDetector(
                onTap: onHeaderTap,
                child: SizedBox(
                  width: double.infinity,
                  height: coverHeight,
                  child: coverProvider != null
                      ? Image(image: coverProvider, fit: BoxFit.cover)
                      : Container(
                          color: coverPlaceholderColor,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Back button overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              // Header actions (no camera icon)
              Positioned(
                top: 12 + MediaQuery.of(context).padding.top,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (readOnly) ...[
                      IconButton(
                        onPressed: onNotifications,
                        tooltip: 'Notifications',
                        icon: const Icon(Icons.notifications_none_outlined),
                        iconSize: 22,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black.withValues(alpha: 0.28),
                          padding: const EdgeInsets.all(10),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: onMore,
                      tooltip: 'More',
                      icon: const Icon(Icons.more_horiz_rounded),
                      iconSize: 22,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black.withValues(alpha: 0.28),
                        padding: const EdgeInsets.all(10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Rectangular avatar overlapping the cover by half (fully hittestable)
              Positioned(
                left: 24,
                bottom: 0,
                child: GestureDetector(
                  onTap: onProfileImageTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: avatarProvider != null
                            ? DecorationImage(
                                image: avatarProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: profileImage == null
                            ? (isDark
                                ? Colors.black.withValues(alpha: 0.12)
                                : Colors.white)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: avatarProvider == null
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (!readOnly)
                Positioned(
                  right: 16,
                  bottom: -4,
                  child: OutlinedButton(
                    onPressed: onEditProfile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Color(0xFFFF8A3B)),
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFFF8A3B),
                    ),
                    child: const Text('Edit profile'),
                  ),
                )
              else
                Positioned(
                  right: 16,
                  bottom: -6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onMessage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          side: BorderSide(
                            color: onSurface.withValues(alpha: 0.25),
                          ),
                          foregroundColor: onSurface,
                          backgroundColor:
                              theme.colorScheme.surface.withValues(
                            alpha: isDark ? 0.8 : 0.9,
                          ),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: const Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final bool isFollowing = isFollowingOther;
                          final Color followBg = isFollowing
                              ? Colors.transparent
                              : (isDark ? Colors.white : Colors.black);
                          final Color followFg = isFollowing
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.black : Colors.white);
                          final BorderSide followBorder = BorderSide(
                            color:
                                (isDark ? Colors.white : Colors.black)
                                    .withValues(
                              alpha: isFollowing ? 0.28 : 1,
                            ),
                            width: 1.2,
                          );

                          return OutlinedButton.icon(
                            onPressed: onToggleFollow,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(96, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              side: followBorder,
                              foregroundColor: followFg,
                              backgroundColor: followBg,
                            ),
                            icon: Icon(
                              isFollowing ? Icons.check_rounded : Icons.add_rounded,
                              size: 16,
                            ),
                            label: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTheme.tweetBody(onSurface).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? onSurface
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                handle,
                style: AppTheme.tweetBody(subtle),
              ),
              SizedBox(height: bio.trim().isEmpty ? 10 : 12),
              if (bio.trim().isNotEmpty) ...[
                Text(
                  bio,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: onSurface,
                    height: 1.45,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Followers and counts under bio
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileStat(
                    value: _formatCount(followersCount),
                    label: 'Followers',
                  ),
                  const SizedBox(width: 24),
                  _ProfileStat(
                    value: _formatCount(followingCount),
                    label: 'Following',
                  ),
                  const SizedBox(width: 24),
                  _ProfileStat(
                    value: _formatCount(likesCount),
                    label: 'Likes',
                  ),
                  const SizedBox(width: 24),
                  _ProfileLevelStat(
                    label: activityLevelLabel,
                    progress: activityProgress,
                    interactive: !readOnly,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
