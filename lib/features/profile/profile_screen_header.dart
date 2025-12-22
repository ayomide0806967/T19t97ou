part of 'profile_screen.dart';

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.headerImage,
    required this.profileImage,
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
    required this.activityLevelLabel,
    required this.activityProgress,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
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
  final String activityLevelLabel;
  final double activityProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.58);
    final coverPlaceholderColor = theme.colorScheme.surfaceContainerHigh
        .withValues(alpha: isDark ? 0.32 : 0.6);

    final double screenWidth = MediaQuery.of(context).size.width;
    const double coverHeight = 200;
    const double avatarSize = 96;

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
                  child: headerImage != null
                      ? Image.memory(headerImage!, fit: BoxFit.cover)
                      : Container(color: coverPlaceholderColor),
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
                        image: profileImage != null
                            ? DecorationImage(
                                image: MemoryImage(profileImage!),
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
                      child: profileImage == null
                          ? Text(
                              initials,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: onSurface,
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
                      side: const BorderSide(color: Colors.black),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
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
                            width: 1,
                          );

                          return OutlinedButton(
                            onPressed: onToggleFollow,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              side: followBorder,
                              foregroundColor: followFg,
                              backgroundColor: followBg,
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
              const SizedBox(height: 12),
              Text(
                bio,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: onSurface,
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 14),
              // Followers and counts under bio
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileStat(value: '18.4K', label: 'Followers'),
                  const SizedBox(width: 24),
                  const _ProfileStat(value: '1.2K', label: 'Following'),
                  const SizedBox(width: 24),
                  const _ProfileStat(value: '5.8K', label: 'Likes'),
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

