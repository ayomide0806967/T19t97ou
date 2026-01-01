part of '../ios_messages_screen.dart';

class FullPageClassesScreen extends StatelessWidget {
  const FullPageClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
      ),
      body: const SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: _ClassesExperience(),
        ),
      ),
    );
  }
}
