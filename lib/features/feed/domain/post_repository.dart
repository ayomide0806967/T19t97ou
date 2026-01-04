import '../../../models/post.dart';
import '../../../models/thread_entry.dart';

/// Domain-level contract for accessing and mutating posts in the feed.
///
/// This interface is deliberately Flutter-free so that implementations
/// can live in data layers (local storage, Supabase, etc.) without
/// depending on widgets or framework mixins.
abstract class PostRepository {
  List<PostModel> get posts;
  List<PostModel> get timelinePosts;

  /// Stream of timeline changes for realtime/reactive UIs.
  ///
  /// Implementations should emit whenever the underlying posts list changes,
  /// such as after [load], [addPost], [addQuote], or [toggleRepost].
  Stream<List<PostModel>> watchTimeline();

  /// Stream of thread updates for a given root post.
  ///
  /// Implementations should emit whenever the underlying data for the thread
  /// changes (for example, when new replies arrive or metrics are updated).
  Stream<ThreadEntry> watchThread(String postId);

  /// Stream of timeline updates scoped to a specific user handle.
  ///
  /// Implementations should emit a new list when the underlying posts for that
  /// handle change (e.g. new posts, deleted posts, or updated metrics).
  Stream<List<PostModel>> watchUserTimeline(String handle);

  Future<void> load();
  Future<void> clearAll();

  Future<void> addPost({
    required String author,
    required String handle,
    required String body,
    List<String> tags,
    List<String> mediaPaths,
  });

  Future<void> addQuote({
    required String author,
    required String handle,
    required String comment,
    required PostSnapshot original,
    List<String> tags,
  });

  Future<void> deletePost({required String postId});

  // =========================================================================
  // Like operations
  // =========================================================================

  /// Check whether the current user has liked a post.
  bool hasUserLiked(String postId);

  /// Toggle like on a post. Returns true if now liked, false if unliked.
  Future<bool> toggleLike(String postId);

  // =========================================================================
  // Repost operations
  // =========================================================================

  bool hasUserReposted(String postId, String userHandle);

  Future<bool> toggleRepost({
    required String postId,
    required String userHandle,
  });

  // =========================================================================
  // Bookmark operations
  // =========================================================================

  /// Check whether the current user has saved/bookmarked a post.
  bool hasUserBookmarked(String postId);

  /// Toggle bookmark on a post. Returns true if now bookmarked.
  Future<bool> toggleBookmark(String postId);

  /// Best-effort list of bookmarked posts, based on currently loaded data.
  List<PostModel> bookmarkedPosts();

  // =========================================================================
  // Thread & user timeline helpers
  // =========================================================================

  ThreadEntry buildThreadForPost(String postId);

  List<PostModel> postsForHandle(String handle);
  List<PostModel> postsForHandles(Set<String> handles);

  List<PostModel> repliesForHandle(String handle, {int minLikes});
}

