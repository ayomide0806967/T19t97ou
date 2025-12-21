import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../screens/ios_messages_screen.dart' as legacy;

/// Compatibility layer for the legacy classes/messages UI living under
/// `lib/screens/ios_messages_screen.dart`.
///
/// Keep all direct imports of the legacy library here so the rest of the app
/// can depend on a stable, intentionally small API surface.
Route<void> messageRepliesRouteFromPost({
  required PostModel post,
  required String currentUserHandle,
}) {
  return legacy.messageRepliesRouteFromPost(
    post: post,
    currentUserHandle: currentUserHandle,
  );
}

