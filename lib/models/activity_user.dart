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

  /// Previously generated demo users for a post; now returns an empty list.
  static List<ActivityUser> generateDemoUsers(int count, {int seed = 0}) =>
      <ActivityUser>[];
}
