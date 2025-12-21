class ClassTopic {
  const ClassTopic({
    required this.courseName,
    required this.tutorName,
    required this.topicTitle,
    required this.createdAt,
    this.privateLecture = false,
    this.requirePin = false,
    this.pinCode,
    this.autoArchiveAt,
  });

  final String courseName;
  final String tutorName;
  final String topicTitle;
  final DateTime createdAt;
  final bool privateLecture;
  final bool requirePin;
  final String? pinCode;
  final DateTime? autoArchiveAt;

  String get topicTag {
    final t = topicTitle.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'topic_$t';
  }
}

