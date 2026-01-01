import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/app_providers.dart';
import 'core/ui/theme_mode_controller.dart';
import 'navigation_drawer_screen_parts.dart';
import 'widgets/brand_mark.dart';


class NavigationDrawerScreen extends ConsumerStatefulWidget {
  const NavigationDrawerScreen({super.key});

  @override
  ConsumerState<NavigationDrawerScreen> createState() =>
      _NavigationDrawerScreenState();
}

class _NavigationDrawerScreenState extends ConsumerState<NavigationDrawerScreen>
    with NavigationDrawerBuildHelpers {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final scaffold = theme.scaffoldBackgroundColor;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.65 : 0.5);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffold,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.45 : 0.2),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.menu, color: onSurface, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: Row(
          children: [
            const BrandMark(size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: isDark ? 0.45 : 0.2),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: onSurface, size: 22),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildWelcomeSection(theme, onSurface),
            const SizedBox(height: 32),
            buildStatsGrid(theme, onSurface),
            const SizedBox(height: 32),
            buildRecentActivity(theme, onSurface, subtle),
            const SizedBox(height: 32),
            buildQuickActions(theme, onSurface),
          ],
        ),
      ),
      drawer: buildNavigationDrawer(theme, surface, onSurface, subtle),
    );
  }
}
