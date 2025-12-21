import 'package:flutter/material.dart';

import '../core/navigation/app_nav.dart';
import 'compose_fab.dart';
import 'floating_nav_bar.dart';

/// Shared top-level scaffold used by the main bottom navigation destinations.
///
/// Keeps the bottom nav + compose FAB behavior consistent across screens.
class AppTabScaffold extends StatelessWidget {
  const AppTabScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.onHomeReselect,
    this.isHomeRoot = false,
    this.showComposeFab = true,
  });

  final int currentIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final VoidCallback? onHomeReselect;
  final bool isHomeRoot;
  final bool showComposeFab;

  void _handleTabTap(BuildContext context, int index) {
    final navigator = Navigator.of(context);

    if (index == 2) {
      navigator.push(AppNav.compose());
      return;
    }

    if (index == currentIndex) {
      if (index == 0 && isHomeRoot) {
        onHomeReselect?.call();
      }
      return;
    }

    if (index == 0) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    final Route<void> route = switch (index) {
      1 => AppNav.hub(),
      3 => AppNav.notifications(),
      4 => AppNav.myProfile(),
      _ => AppNav.compose(),
    };

    if (isHomeRoot) {
      navigator.push(route);
      return;
    }

    navigator.pushReplacement(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      body: body,
      floatingActionButton: showComposeFab
          ? const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ComposeFab(),
            )
          : null,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: currentIndex,
        onIndexChange: (index) => _handleTabTap(context, index),
        destinations: const [
          FloatingNavBarDestination(icon: Icons.home_filled, onTap: null),
          FloatingNavBarDestination(icon: Icons.mail_outline_rounded, onTap: null),
          FloatingNavBarDestination(icon: Icons.add, onTap: null),
          FloatingNavBarDestination(icon: Icons.favorite_border_rounded, onTap: null),
          FloatingNavBarDestination(icon: Icons.person_outline_rounded, onTap: null),
        ],
      ),
    );
  }
}

