import '../../../models/post.dart';

class ClassTopicPostsState {
  const ClassTopicPostsState({
    required this.topicTag,
    required this.posts,
    required this.visibleCount,
    this.isLoading = false,
    this.errorMessage,
  });

  final String topicTag;
  final List<PostModel> posts;
  final int visibleCount;
  final bool isLoading;
  final String? errorMessage;

  ClassTopicPostsState copyWith({
    List<PostModel>? posts,
    int? visibleCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClassTopicPostsState(
      topicTag: topicTag,
      posts: posts ?? this.posts,
      visibleCount: visibleCount ?? this.visibleCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

