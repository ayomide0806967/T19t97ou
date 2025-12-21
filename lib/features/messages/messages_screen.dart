import 'package:flutter/material.dart';

import 'legacy_messages_page.dart';

/// Temporary wrapper to decouple the rest of the app from the legacy
/// `ios_messages_screen.dart` mega-file. This will be replaced by a proper
/// feature module screen.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({
    super.key,
    this.openInboxOnStart = false,
  });

  final bool openInboxOnStart;

  @override
  Widget build(BuildContext context) =>
      IosMinimalistMessagePage(openInboxOnStart: openInboxOnStart);
}
