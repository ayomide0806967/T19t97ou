part of 'compose_screen.dart';

abstract class _ComposeScreenStateBase extends ConsumerState<ComposeScreen> {
  final TextEditingController controller = _LimitHighlightController(
    maxChars: 280,
  );
  final FocusNode textFocusNode = FocusNode();
  bool isPosting = false;
  final List<XFile> media = <XFile>[];
  final ImagePicker picker = ImagePicker();
  ReplyPermission replyPermission = ReplyPermission.everyone;
  bool largeText = false;

  @override
  void dispose() {
    controller.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  bool get canPost =>
      (controller.text.trim().isNotEmpty || media.isNotEmpty) &&
      controller.text.length <= 280 &&
      !isPosting;

  bool get hasUnsavedChanges =>
      controller.text.trim().isNotEmpty || media.isNotEmpty;

  String get currentUserHandle {
    final profileHandle =
        ref.read(profileRepositoryProvider).profile.handle.trim();
    if (profileHandle.isNotEmpty && !_isDemoProfileHandle(profileHandle)) {
      return profileHandle;
    }
    return ref.read(currentUserHandleProvider);
  }

  String get currentUserName {
    final profile = ref.read(profileRepositoryProvider).profile;
    final name = profile.fullName.trim();
    if (name.isNotEmpty && !_isDemoProfileName(name)) return name;
    final handle = currentUserHandle.trim();
    if (handle.isEmpty) return 'You';
    return _displayNameFromHandle(handle);
  }

  bool _isDemoProfileHandle(String handle) {
    final normalized = handle.trim().toLowerCase();
    return normalized == '@productlead' || normalized == '@yourprofile';
  }

  bool _isDemoProfileName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'alex rivera';
  }

  String _displayNameFromHandle(String handle) {
    final raw = handle.trim().replaceFirst(RegExp(r'^@'), '');
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'You';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String get replyPermissionLabel {
    switch (replyPermission) {
      case ReplyPermission.everyone:
        return 'Everyone can reply';
      case ReplyPermission.following:
        return 'People you follow';
      case ReplyPermission.mentioned:
        return 'Only people you mention';
    }
  }

  void toggleTextSize() {
    setState(() {
      largeText = !largeText;
    });
  }

  Future<void> onAudienceTap() async {
    final result = await showModalBottomSheet<ReplyPermission>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who can reply?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ReplyOptionTile(
                  title: 'Everyone can reply',
                  subtitle: 'Anyone on the platform can respond.',
                  selected: replyPermission == ReplyPermission.everyone,
                  onTap: () => Navigator.of(ctx).pop(ReplyPermission.everyone),
                ),
                _ReplyOptionTile(
                  title: 'People you follow',
                  subtitle: 'Only people you follow can reply.',
                  selected: replyPermission == ReplyPermission.following,
                  onTap: () => Navigator.of(ctx).pop(ReplyPermission.following),
                ),
                _ReplyOptionTile(
                  title: 'Only people you mention',
                  subtitle: 'Only accounts you mention can reply.',
                  selected: replyPermission == ReplyPermission.mentioned,
                  onTap: () => Navigator.of(ctx).pop(ReplyPermission.mentioned),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        replyPermission = result;
      });
    }
  }

  Future<void> post() async {
    if (!canPost) return;
    setState(() => isPosting = true);
    final handle = currentUserHandle;
    try {
      await ref.read(composeControllerProvider.notifier).createPost(
            author: currentUserName,
            handle: handle,
            body: controller.text.trim(),
            mediaPaths: media.map((f) => f.path).toList(),
          );
      if (!mounted) return;
      AppToast.showTopOverlay(
        context,
        'Your post was sent',
        duration: ToastDurations.standard,
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => isPosting = false);
      AppToast.showTopOverlay(
        context,
        'Could not send post',
        duration: ToastDurations.standard,
      );
    }
  }

  Future<void> handleExit() async {
    if (!hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    FocusScope.of(context).unfocus();

    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Save post?'),
        content: const Text(
          'You can save this to send later from your Drafts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.delete),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == _ExitAction.delete) {
      Navigator.pop(context);
      return;
    }

    if (action == _ExitAction.save) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to drafts'),
          duration: Duration(milliseconds: 900),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> files = await picker.pickMultiImage();
      if (!mounted || files.isEmpty) return;
      setState(() {
        media
          ..clear()
          ..addAll(files);
      });
    } catch (_) {
      // Silent for now; could surface an error toast.
    }
  }
}

class _ComposeScreenState extends _ComposeScreenStateBase
    with _ComposeScreenBuild {}
