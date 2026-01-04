import 'package:flutter/foundation.dart';

/// A comment on a post.
@immutable
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    this.authorAvatarUrl,
    required this.body,
    this.parentCommentId,
    required this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.isLiked = false,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final String body;
  final String? parentCommentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likes;
  final bool isLiked;

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorHandle,
    String? authorAvatarUrl,
    String? body,
    String? parentCommentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorHandle: authorHandle ?? this.authorHandle,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      body: body ?? this.body,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

/// Domain-level contract for comment operations.
///
/// Decouples UI from storage implementation (local, Supabase, etc.).
abstract class CommentRepository {
  /// Watch comments for a post as a stream.
  Stream<List<Comment>> watchComments(String postId);

  /// Get comments for a post (one-time fetch).
  Future<List<Comment>> getComments(String postId);

  /// Add a new comment to a post.
  Future<Comment> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  });

  /// Edit an existing comment.
  Future<Comment> editComment({
    required String commentId,
    required String body,
  });

  /// Delete a comment.
  Future<void> deleteComment(String commentId);

  /// Toggle like on a comment.
  Future<bool> toggleLike(String commentId);
}
