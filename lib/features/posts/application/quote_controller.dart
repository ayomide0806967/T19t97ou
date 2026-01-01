import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../features/feed/domain/post_repository.dart';
import '../../../models/post.dart';

/// Controller responsible for creating quote posts.
class QuoteController extends Notifier<void> {
  @override
  void build() {}

  PostRepository get _repository => ref.read(postRepositoryProvider);

  Future<void> addQuote({
    required String author,
    required String handle,
    required String comment,
    required PostSnapshot original,
    List<String> tags = const <String>[],
  }) {
    return _repository.addQuote(
      author: author,
      handle: handle,
      comment: comment,
      original: original,
      tags: tags,
    );
  }
}

final quoteControllerProvider =
    NotifierProvider<QuoteController, void>(QuoteController.new);

