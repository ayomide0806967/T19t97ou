import '../../../models/college.dart';
import '../domain/class_source.dart';

/// In-memory/demo implementation backed by the previous ClassService data.
class StaticClassSource implements ClassSource {
  StaticClassSource();

  // Demo colleges. In a real app, load from backend or local DB.
  static final List<College> _colleges = <College>[
    College(
      name: 'Biology 401: Genetics',
      code: 'BIO401',
      facilitator: 'Dr. Tayo Ajayi • Tuesdays & Thursdays',
      members: 42,
      deliveryMode: 'Hybrid cohort',
      upcomingExam: 'Mid-sem • 18 Oct',
      resources: <CollegeResource>[
        const CollegeResource(
          title: 'Gene Expression Slides',
          fileType: 'pdf',
          size: '3.2 MB',
        ),
        const CollegeResource(
          title: 'CRISPR Lab Manual',
          fileType: 'pdf',
          size: '1.1 MB',
        ),
        const CollegeResource(
          title: 'Exam Blueprint',
          fileType: 'pdf',
          size: '820 KB',
        ),
      ],
      memberHandles: <String>{
        '@year3_shift',
        '@osce_ready',
        '@skillslab',
      },
      lectureNotes: <LectureNote>[
        const LectureNote(
          title: 'Mendelian inheritance overview',
          subtitle: 'Week 1 notes',
          size: '6 pages',
        ),
        const LectureNote(
          title: 'Gene regulation basics',
          subtitle: 'Week 2 notes',
          size: '9 pages',
        ),
        const LectureNote(
          title: 'CRISPR: principles + ethics',
          subtitle: 'Seminar handout',
          size: '4 pages',
        ),
      ],
    ),
    College(
      name: 'Civic Education: Governance & Policy',
      code: 'CVE220',
      facilitator: 'Mrs. Amaka Eze • Mondays',
      members: 58,
      deliveryMode: 'Virtual classroom',
      upcomingExam: 'Mock exam • 26 Oct',
      resources: <CollegeResource>[
        const CollegeResource(
          title: 'Policy Case Studies',
          fileType: 'pdf',
          size: '2.5 MB',
        ),
        const CollegeResource(
          title: 'Past Questions',
          fileType: 'pdf',
          size: '4.1 MB',
        ),
      ],
      memberHandles: <String>{
        '@coach_amaka',
        '@community_rounds',
      },
      lectureNotes: <LectureNote>[
        const LectureNote(
          title: 'Arms of government',
          subtitle: 'Introductory lecture',
          size: '8 pages',
        ),
        const LectureNote(
          title: 'Policy lifecycle',
          subtitle: 'Framework + examples',
          size: '5 pages',
        ),
      ],
    ),
    College(
      name: 'Chemistry 202: Organic Basics',
      code: 'CHM202',
      facilitator: 'Dr. Musa Bello • Wednesdays',
      members: 38,
      deliveryMode: 'On‑campus',
      upcomingExam: 'Quiz • 4 Nov',
      resources: <CollegeResource>[
        const CollegeResource(
          title: 'Intro to Organic Reactions',
          fileType: 'pdf',
          size: '2.1 MB',
        ),
        const CollegeResource(
          title: 'Lab Safety Checklist',
          fileType: 'pdf',
          size: '940 KB',
        ),
      ],
      memberHandles: <String>{
        '@lab_group_a',
        '@study_circle',
      },
      lectureNotes: <LectureNote>[
        const LectureNote(
          title: 'Hydrocarbons overview',
          subtitle: 'Week 1 notes',
          size: '7 pages',
        ),
        const LectureNote(
          title: 'Functional groups',
          subtitle: 'Week 2 notes',
          size: '6 pages',
        ),
      ],
    ),
    College(
      name: 'Mathematics 101: Calculus I',
      code: 'MTH101',
      facilitator: 'Prof. Kemi Adesina • Fridays',
      members: 120,
      deliveryMode: 'Lecture theatre',
      upcomingExam: 'Revision test • 12 Nov',
      resources: <CollegeResource>[
        const CollegeResource(
          title: 'Limits & Continuity slides',
          fileType: 'pdf',
          size: '1.8 MB',
        ),
        const CollegeResource(
          title: 'Problem set – Derivatives',
          fileType: 'pdf',
          size: '600 KB',
        ),
      ],
      memberHandles: <String>{
        '@calc_club',
        '@math_helpers',
      },
      lectureNotes: <LectureNote>[
        const LectureNote(
          title: 'Introduction to limits',
          subtitle: 'Lecture 1',
          size: '5 pages',
        ),
        const LectureNote(
          title: 'Derivative rules',
          subtitle: 'Lecture 3',
          size: '9 pages',
        ),
      ],
    ),
  ];

  @override
  List<College> userColleges(String handle) {
    if (handle.isEmpty) return _colleges;
    return _colleges
        .where((c) => c.memberHandles.contains(handle))
        .toList(growable: false);
  }

  @override
  List<College> allColleges() => List<College>.unmodifiable(_colleges);

  @override
  College? findByCode(String code) {
    if (code.isEmpty) return null;
    final lookup = code.toUpperCase();
    try {
      return _colleges.firstWhere(
        (c) => c.code.toUpperCase() == lookup,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<College> searchPublicColleges(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allColleges();
    return _colleges.where((college) {
      final name = college.name.toLowerCase();
      final facilitator = college.facilitator.toLowerCase();
      final upcoming = college.upcomingExam.toLowerCase();
      return name.contains(q) ||
          facilitator.contains(q) ||
          upcoming.contains(q);
    }).toList(growable: false);
  }
}
