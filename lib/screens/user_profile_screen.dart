import 'package:flutter/material.dart';

import 'profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      handleOverride: handle,
      readOnly: true,
    );
  }
}

