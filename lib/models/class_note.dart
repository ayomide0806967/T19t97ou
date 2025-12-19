class ClassNoteSection {
  const ClassNoteSection({
    required this.title,
    required this.subtitle,
    required this.bullets,
    this.imagePaths = const <String>[],
  });

  final String title;
  final String subtitle;
  final List<String> bullets;
  final List<String> imagePaths;
}

/// Lightweight summary used for class note cards.
class ClassNoteSummary {
  const ClassNoteSummary({
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.estimatedMinutes,
    required this.createdAt,
    this.commentCount = 0,
    this.sections = const <ClassNoteSection>[],
    this.attachedQuizTitle,
  });

  final String title;
  final String subtitle;
  final int steps;
  final int estimatedMinutes;
  final DateTime createdAt;
  final int commentCount;
  final List<ClassNoteSection> sections;
  final String? attachedQuizTitle;
}
