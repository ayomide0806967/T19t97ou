part of 'profile_screen.dart';

extension _ProfileScreenActions on _ProfileScreenState {
  void _showHeaderToast(String message) {
    AppToast.showTopOverlay(
      context,
      message,
      duration: ToastDurations.standard,
    );
  }

  Future<void> _handlePullToRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      HapticFeedback.lightImpact();
      await ref.read(postRepositoryProvider).load();
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _handleMessageUser() async {
    if (!widget.readOnly) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
  }

  void _handleToggleFollow() {
    if (!widget.readOnly) return;
    final displayName =
        _nameOverride ?? _displayNameFromHandle(_currentUserHandle);
    setState(() {
      _isFollowingOther = !_isFollowingOther;
    });
    _showHeaderToast(
      _isFollowingOther
          ? 'You are now following $displayName'
          : 'You unfollowed $displayName',
    );
  }
}
