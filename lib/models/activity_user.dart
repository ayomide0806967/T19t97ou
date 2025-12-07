import 'dart:math';
import 'package:flutter/material.dart';

/// Represents a user who engaged with a post (liked, reposted, quoted, etc.)
class ActivityUser {
  const ActivityUser({
    required this.username,
    required this.displayName,
    required this.timeAgo,
    this.bio,
    this.comment,
    this.followers = 0,
    this.isFollowing = false,
    this.avatarColors = const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  });

  final String username;
  final String displayName;
  final String timeAgo;
  final String? bio;
  final String? comment;
  final int followers;
  final bool isFollowing;
  final List<Color> avatarColors;

  String get initials {
    final letters = displayName.replaceAll(RegExp('[^A-Za-z]'), '');
    if (letters.isEmpty) return 'U';
    return letters.length >= 2
        ? letters.substring(0, 2).toUpperCase()
        : letters.toUpperCase();
  }

  ActivityUser copyWith({
    String? username,
    String? displayName,
    String? timeAgo,
    String? bio,
    String? comment,
    int? followers,
    bool? isFollowing,
    List<Color>? avatarColors,
  }) {
    return ActivityUser(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      timeAgo: timeAgo ?? this.timeAgo,
      bio: bio ?? this.bio,
      comment: comment ?? this.comment,
      followers: followers ?? this.followers,
      isFollowing: isFollowing ?? this.isFollowing,
      avatarColors: avatarColors ?? this.avatarColors,
    );
  }

  /// Generate demo activity users for a post
  static List<ActivityUser> generateDemoUsers(int count, {int seed = 0}) {
    final random = Random(seed);
    final names = [
      ('urfav_jecel14', "it'z'me_inday🐱14", '5h', 'Real', null),
      ('sa__mrtnz', '🤍\$A🤍', '40m', null, null),
      ('whos_minaal', 'Minahil Nawaz', '2h', null, null),
      ('marshmallows_lady11', 'Cierra Jackson', '1h', null, null),
      ('sxutina_a', 'kera_TIN? 🤪', '38m', null, null),
      ('urs_cristine29', 'Cristine Mae', '3h', null, null),
      ('daily_vibes_', 'Daily Vibes ✨', '15m', 'Just vibing', null),
      ('tech_sarah', 'Sarah Chen', '1h', 'Dev & Designer', null),
      ('music_lover22', 'Alex Rivera', '45m', '🎵 Music is life', null),
      ('travel_adventures', 'Marco Santos', '2h', 'Wanderlust', null),
    ];

    final gradients = [
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
      [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFFee0979), const Color(0xFFff6a00)],
    ];

    final users = <ActivityUser>[];
    for (int i = 0; i < count && i < names.length; i++) {
      final idx = (i + seed) % names.length;
      final name = names[idx];
      users.add(ActivityUser(
        username: name.$1,
        displayName: name.$2,
        timeAgo: name.$3,
        comment: name.$4,
        bio: name.$5,
        followers: random.nextInt(500) + 10,
        isFollowing: random.nextBool(),
        avatarColors: gradients[(i + seed) % gradients.length],
      ));
    }
    return users;
  }
}
