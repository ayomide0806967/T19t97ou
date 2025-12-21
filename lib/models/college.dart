class College {
  const College({
    required this.name,
    required this.code,
    required this.facilitator,
    required this.members,
    required this.deliveryMode,
    required this.upcomingExam,
    required this.resources,
    required this.memberHandles,
    this.lectureNotes = const <LectureNote>[],
  });

  final String name;
  final String code;
  final String facilitator;
  final int members;
  final String deliveryMode;
  final String upcomingExam;
  final List<CollegeResource> resources;
  final Set<String> memberHandles;
  final List<LectureNote> lectureNotes;
}

class CollegeResource {
  const CollegeResource({
    required this.title,
    required this.fileType,
    required this.size,
  });

  final String title;
  final String fileType;
  final String size;
}

class LectureNote {
  const LectureNote({required this.title, this.subtitle, this.size});

  final String title;
  final String? subtitle;
  final String? size;
}
