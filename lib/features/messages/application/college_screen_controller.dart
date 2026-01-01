import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/class_topic.dart';

part 'college_screen_controller.g.dart';

class CollegeUiState {
  const CollegeUiState({
    this.activeTopic,
    this.archivedTopics = const <ClassTopic>[],
    this.adminOnlyPosting = true,
    this.allowReplies = true,
    this.allowMedia = false,
    this.approvalRequired = false,
    this.isPrivate = true,
    this.autoArchiveOnEnd = true,
    this.unlockedTopicTags = const <String>{},
  });

  final ClassTopic? activeTopic;
  final List<ClassTopic> archivedTopics;

  final bool adminOnlyPosting;
  final bool allowReplies;
  final bool allowMedia;
  final bool approvalRequired;
  final bool isPrivate;
  final bool autoArchiveOnEnd;

  final Set<String> unlockedTopicTags;

  CollegeUiState copyWith({
    ClassTopic? activeTopic,
    bool clearActiveTopic = false,
    List<ClassTopic>? archivedTopics,
    bool? adminOnlyPosting,
    bool? allowReplies,
    bool? allowMedia,
    bool? approvalRequired,
    bool? isPrivate,
    bool? autoArchiveOnEnd,
    Set<String>? unlockedTopicTags,
  }) {
    return CollegeUiState(
      activeTopic: clearActiveTopic ? null : (activeTopic ?? this.activeTopic),
      archivedTopics: archivedTopics ?? this.archivedTopics,
      adminOnlyPosting: adminOnlyPosting ?? this.adminOnlyPosting,
      allowReplies: allowReplies ?? this.allowReplies,
      allowMedia: allowMedia ?? this.allowMedia,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      isPrivate: isPrivate ?? this.isPrivate,
      autoArchiveOnEnd: autoArchiveOnEnd ?? this.autoArchiveOnEnd,
      unlockedTopicTags: unlockedTopicTags ?? this.unlockedTopicTags,
    );
  }
}

@riverpod
class CollegeScreenController extends _$CollegeScreenController {
  @override
  CollegeUiState build(String classCode) {
    // For now we don't persist per-class settings; we just initialise
    // a fresh UI state for the given class code.
    return const CollegeUiState();
  }

  void startLecture(ClassTopic topic) {
    state = state.copyWith(activeTopic: topic);
  }

  void archiveActiveTopic() {
    final topic = state.activeTopic;
    if (topic == null) return;
    final nextArchived = <ClassTopic>[topic, ...state.archivedTopics];
    state = state.copyWith(
      clearActiveTopic: true,
      archivedTopics: nextArchived,
    );
  }

  void setAdminOnlyPosting(bool value) {
    state = state.copyWith(adminOnlyPosting: value);
  }

  void setAllowReplies(bool value) {
    state = state.copyWith(allowReplies: value);
  }

  void setIsPrivate(bool value) {
    state = state.copyWith(isPrivate: value);
  }

  void unlockTopicTag(String tag) {
    final next = <String>{...state.unlockedTopicTags, tag};
    state = state.copyWith(unlockedTopicTags: next);
  }
}
