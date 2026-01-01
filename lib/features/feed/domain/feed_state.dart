import '../../../models/post.dart';

/// Simple immutable state for the home/trending feed.
class FeedState {
  const FeedState({
    required this.posts,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PostModel> posts;
  final bool isLoading;
  final String? errorMessage;

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

