part of '../ios_messages_screen.dart';

// Spotify-style full-bleed hero that extends to the top of the screen
class _SpotifyStyleHero extends StatelessWidget {
  const _SpotifyStyleHero({
    required this.topPadding,
    required this.onInboxTap,
    required this.onCreateClassTap,
    required this.onJoinClassTap,
  });

  final double topPadding;
  final VoidCallback onInboxTap;
  final VoidCallback onCreateClassTap;
  final VoidCallback onJoinClassTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main hero content with curved bottom
        ClipPath(
          clipper: _CurvedBottomClipper(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 50), // Extra padding for wave
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000), // Pure black at the top
                  Color(0xFF111111), // Dark grey mid
                  Color(0xFF181818), // Dark grey at the bottom
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Background artwork/pattern
                Positioned.fill(
                  child: CustomPaint(painter: _HeroArtworkPainter()),
                ),
                // Decorative elements
                Positioned(
                  top: topPadding + 40,
                  right: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _whatsAppGreen.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding + 100,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with small Inbox button
                      Row(
                        children: [
                          Text(
                            'Classes',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: onInboxTap,
                            child: const Text(
                              'Inbox',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Main heading
                      const Text(
                        'Learn Together,\nGrow Together',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create or join a class to collaborate with your peers and share knowledge.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Small secondary button for joining a class
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onJoinClassTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                            label: const Text(
                              'Join a class',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Primary pill button for creating a class
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onCreateClassTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _whatsAppDarkGreen,
                            elevation: 6,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Text(
                            'Create a class group',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Custom clipper for curved bottom edge
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    // Create a smooth curve at the bottom
    path.quadraticBezierTo(
      size.width / 2, // Control point X (center)
      size.height + 20, // Control point Y (creates the curve depth)
      size.width, // End point X
      size.height - 50, // End point Y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Custom painter for hero artwork
class _HeroArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Abstract curved lines
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.3 + i * 0.15));
      path.quadraticBezierTo(
        size.width * 0.4,
        size.height * (0.2 + i * 0.1),
        size.width,
        size.height * (0.4 + i * 0.12),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

