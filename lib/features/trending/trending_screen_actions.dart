part of 'trending_screen.dart';

mixin _TrendingScreenActions on _TrendingScreenStateBase {
  Future<void> _showQuickControls() async {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    final appSettings = context.read<AppSettings>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TrendingQuickControlPanel(
          theme: theme,
          appSettings: appSettings,
          onCompose: () async {
            await navigator.push(AppNav.compose());
          },
          onBackToTop: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          },
          onClearSearch: () {
            _searchController.clear();
          },
        );
      },
    );
  }
}
