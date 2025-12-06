import '../models/college.dart';

class ClassService {
  ClassService._();

  // Demo colleges. In a real app, load from backend or local DB.
  static final List<College> _colleges = <College>[
    College(
      name: 'Biology 401: Genetics',
      code: 'BIO401',
      facilitator: 'Dr. Tayo Ajayi • Tuesdays & Thursdays',
      members: 42,
      deliveryMode: 'Hybrid cohort',
      upcomingExam: 'Mid-sem • 18 Oct',
      resources: const [],
      memberHandles: <String>{
        '@year3_shift', '@osce_ready', '@skillslab', '@yourprofile',
      },
    ),
    College(
      name: 'Civic Education: Governance & Policy',
      code: 'CVE220',
      facilitator: 'Mrs. Amaka Eze • Mondays',
      members: 58,
      deliveryMode: 'Virtual classroom',
      upcomingExam: 'Mock exam • 26 Oct',
      resources: const [],
      memberHandles: <String>{
        '@coach_amaka', '@community_rounds', '@yourprofile',
      },
    ),
  ];

  static List<College> userColleges(String handle) {
    if (handle.isEmpty) return _colleges;
    return _colleges
        .where((c) => c.memberHandles.contains(handle))
        .toList(growable: false);
  }
}

