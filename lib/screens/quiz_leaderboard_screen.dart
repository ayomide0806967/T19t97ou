import 'package:flutter/material.dart';

/// Quiz leaderboard screen styled to match the provided design:
/// - Purple gradient background with subtle abstract waves
/// - Bold header card with V-shaped bottom and top-3 pyramid layout
/// - Floating white leaderboard card for remaining users.
class QuizLeaderboardScreen extends StatelessWidget {
  const QuizLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample data for the leaderboard.
    final List<UserScore> scores = [
      UserScore(name: 'Marcel', score: 10000, trend: Trend.up),
      UserScore(name: 'Becky', score: 1390, trend: Trend.up),
      UserScore(name: 'Tara', score: 1270, trend: Trend.down),
      UserScore(name: 'Ibhanu Mapon', score: 980, trend: Trend.up),
      UserScore(name: 'Robin', score: 930, trend: Trend.up),
      UserScore(name: 'Taran', score: 890, trend: Trend.down),
      UserScore(name: 'Mia', score: 860, trend: Trend.up),
      UserScore(name: 'Andrew', score: 830, trend: Trend.down),
      UserScore(name: 'William', score: 810, trend: Trend.up),
    ];

    final topThree = scores.take(3).toList();
    final rest = scores.skip(3).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Purple background gradient.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF311B92),
                  Color(0xFF4527A0),
                  Color(0xFF512DA8),
                ],
              ),
            ),
          ),
          // Low-opacity decorative waves.
          const Positioned.fill(child: _BackgroundWaves()),
          // Main content.
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TopHeaderCard(topThree: topThree),
                ),
                const SizedBox(height: 8),
                // Floating leaderboard card.
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _LeaderboardListCard(userScores: rest),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserScore {
  UserScore({
    required this.name,
    required this.score,
    required this.trend,
  });

  final String name;
  final int score;
  final Trend trend;

  String get initials {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

enum Trend { up, down, neutral }

class _TopHeaderCard extends StatelessWidget {
  const _TopHeaderCard({required this.topThree});

  final List<UserScore> topThree;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipPath(
      clipper: _HeaderVClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF512DA8),
              Color(0xFF4527A0),
              Color(0xFF311B92),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'LEADERBOARD',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Time filter chip (e.g., Monthly)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Crown icon
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD54F),
              size: 32,
            ),
            const SizedBox(height: 12),
            // Top 3 pyramid layout.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TopUserPill(
                  user: topThree[1],
                  rank: 2,
                  isCenter: false,
                ),
                _TopUserPill(
                  user: topThree[0],
                  rank: 1,
                  isCenter: true,
                ),
                _TopUserPill(
                  user: topThree[2],
                  rank: 3,
                  isCenter: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUserPill extends StatelessWidget {
  const _TopUserPill({
    required this.user,
    required this.rank,
    required this.isCenter,
  });

  final UserScore user;
  final int rank;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double avatarRadius = isCenter ? 34 : 28;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: avatarRadius * 2,
          height: avatarRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD54F),
                Color(0xFFFFB300),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: CircleAvatar(
              radius: avatarRadius - 5,
              backgroundColor: const Color(0xFF1A1035),
              child: Text(
                user.initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: isCenter ? FontWeight.w600 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${user.score}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardListCard extends StatelessWidget {
  const _LeaderboardListCard({required this.userScores});

  final List<UserScore> userScores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: userScores.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 72,
          color: const Color(0xFFEDE7F6),
        ),
        itemBuilder: (context, index) {
          final user = userScores[index];
          final rank = index + 4; // continues after top 3
          return _LeaderboardListItem(
            rank: rank,
            user: user,
          );
        },
      ),
    );
  }
}

class _LeaderboardListItem extends StatelessWidget {
  const _LeaderboardListItem({
    required this.rank,
    required this.user,
  });

  final int rank;
  final UserScore user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color badgeColor;
    if (rank <= 10) {
      badgeColor = const Color(0xFF7C4DFF);
    } else {
      badgeColor = const Color(0xFFB39DDB);
    }

    IconData trendIcon;
    Color trendColor;
    switch (user.trend) {
      case Trend.up:
        trendIcon = Icons.arrow_upward_rounded;
        trendColor = const Color(0xFF43A047);
        break;
      case Trend.down:
        trendIcon = Icons.arrow_downward_rounded;
        trendColor = const Color(0xFFE53935);
        break;
      case Trend.neutral:
        trendIcon = Icons.remove_rounded;
        trendColor = Colors.grey;
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '#$rank',
              style: theme.textTheme.bodySmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEDE7F6),
            child: Text(
              user.initials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF4527A0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        user.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${user.score}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4527A0),
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            trendIcon,
            size: 18,
            color: trendColor,
          ),
        ],
      ),
    );
  }
}

class _BackgroundWaves extends StatelessWidget {
  const _BackgroundWaves();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavesPainter(),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7E57C2).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Path buildWave(double heightFactor, double amplitude) {
      final path = Path()..moveTo(0, size.height * heightFactor);
      for (double x = 0; x <= size.width; x += 8) {
        final y = size.height * heightFactor +
            amplitude * (x / size.width - 0.5) * (x / size.width - 0.5) * -1;
        path.lineTo(x, y);
      }
      return path;
    }

    canvas.drawPath(buildWave(0.25, 18), paint);
    canvas.drawPath(buildWave(0.45, 24), paint..color = paint.color.withOpacity(0.18));
    canvas.drawPath(buildWave(0.65, 30), paint..color = paint.color.withOpacity(0.14));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Clipper that creates a gentle V-shaped notch at the bottom of the header
/// card, similar to the provided design.
class _HeaderVClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 40)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

