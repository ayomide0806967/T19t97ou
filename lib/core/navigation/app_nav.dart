import 'package:flutter/material.dart';

import '../../screens/compose_screen.dart';
import '../../screens/bookmarks_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/quiz_dashboard_screen.dart';
import '../../screens/trending_screen.dart';
import '../../screens/user_profile_screen.dart';
import '../../features/subscription/subscribe_screen.dart';
import '../../features/messages/messages_screen.dart';

class AppNav {
  AppNav._();

  static Route<void> compose() =>
      MaterialPageRoute(builder: (_) => const ComposeScreen());

  static Route<void> quizDashboard() =>
      MaterialPageRoute(builder: (_) => const QuizDashboardScreen());

  static Route<void> subscriptions() => SubscribeScreen.route();

  static Route<void> classes() =>
      MaterialPageRoute(builder: (_) => const MessagesScreen());

  static Route<void> inbox() => MaterialPageRoute(
        builder: (_) => const MessagesScreen(openInboxOnStart: true),
      );

  static Route<void> hub() =>
      MaterialPageRoute(builder: (_) => const QuizDashboardScreen());

  static Route<void> notifications() =>
      MaterialPageRoute(builder: (_) => const NotificationsScreen());

  static Route<void> trending() =>
      MaterialPageRoute(builder: (_) => const TrendingScreen());

  static Route<void> myProfile() =>
      MaterialPageRoute(builder: (_) => const ProfileScreen());

  static Route<void> bookmarks() =>
      MaterialPageRoute(builder: (_) => const BookmarksScreen());

  static Route<void> userProfile(String handle) =>
      MaterialPageRoute(builder: (_) => UserProfileScreen(handle: handle));

  static Future<T?> push<T>(BuildContext context, Route<T> route) =>
      Navigator.of(context).push(route);
}
