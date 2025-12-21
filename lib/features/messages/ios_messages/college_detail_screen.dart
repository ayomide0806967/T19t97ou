part of '../ios_messages_screen.dart';

class CollegeDetailScreen extends StatelessWidget {
  const CollegeDetailScreen({super.key, required this.college});

  final College college;

  @override
  Widget build(BuildContext context) {
    return _CollegeScreen(college: college);
  }
}

class _CollegeScreen extends StatefulWidget {
  const _CollegeScreen({required this.college});

  final College college;

  @override
  State<_CollegeScreen> createState() => _CollegeScreenState();
}
