part of '../ios_messages_screen.dart';

class CollegeDetailScreen extends StatelessWidget {
  const CollegeDetailScreen({super.key, required this.college});

  final College college;

  @override
  Widget build(BuildContext context) {
    return _CollegeScreen(college: college);
  }
}

class _CollegeScreen extends ConsumerStatefulWidget {
  const _CollegeScreen({required this.college});

  final College college;

  @override
  ConsumerState<_CollegeScreen> createState() => _CollegeScreenState();
}
