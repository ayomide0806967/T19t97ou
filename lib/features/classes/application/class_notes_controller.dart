import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../feed/domain/post_repository.dart';

/// Controller for publishing lecture/class notes into the global feed.
class ClassNotesController extends Notifier<void> {
  @override
  void build() {}

  PostRepository get _repository => ref.read(postRepositoryProvider);

  Future<void> publishLectureNote({
    required String tutorName,
    required String currentUserHandle,
    required String body,
    required String topicTag,
    required String classCode,
  }) {
    return _repository.addPost(
      author: tutorName,
      handle: currentUserHandle,
      body: body,
      tags: <String>[topicTag, classCode],
    );
  }
}

final classNotesControllerProvider =
    NotifierProvider<ClassNotesController, void>(ClassNotesController.new);

