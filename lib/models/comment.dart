import 'package:flutter/material.dart';

class CommentModel {
  CommentModel({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.avatarColors,
    this.likes = 0,
    this.isLiked = false,
  });

  final String id;
  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<Color> avatarColors;
  int likes;
  bool isLiked;

  String get initials {
    final parts = author.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

