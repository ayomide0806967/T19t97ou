import '../../models/post.dart';
import '../../models/thread_entry.dart';

abstract class PostRepository {
  List<PostModel> get posts;
  List<PostModel> get timelinePosts;

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

  bool hasUserReposted(String postId, String userHandle);

  Future<bool> toggleRepost({
    required String postId,
    required String userHandle,
  });

  ThreadEntry buildThreadForPost(String postId);

  List<PostModel> postsForHandle(String handle);
  List<PostModel> postsForHandles(Set<String> handles);

  List<PostModel> repliesForHandle(String handle, {int minLikes});
}

