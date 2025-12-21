import 'package:flutter/material.dart';

import '../../../models/post.dart';
import '../../../screens/ios_messages_screen.dart' as legacy;

/// Temporary forwarding function so other features don't import the legacy
/// `ios_messages_screen.dart` directly.
Route<void> messageRepliesRouteFromPost({
  required PostModel post,
  required String currentUserHandle,
}) {
  return legacy.messageRepliesRouteFromPost(
    post: post,
    currentUserHandle: currentUserHandle,
  );
}

