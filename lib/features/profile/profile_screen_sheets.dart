part of 'profile_screen.dart';

extension _ProfileScreenSheets on _ProfileScreenState {
  Future<void> _openNotificationsSheet({required String handle}) async {
    final String label = handle.startsWith('@') ? handle.substring(1) : handle;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF2F2F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;
        final sheetSurface = isDark ? theme.colorScheme.surface : Colors.white;
        final onSurface = theme.colorScheme.onSurface;
        final subtle = onSurface.withValues(alpha: isDark ? 0.62 : 0.58);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final boxBorder = Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
              width: 1,
            );

            Widget optionRow({
              required String title,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                trailing: selected
                    ? Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: onSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: sheetSurface,
                        ),
                      )
                    : Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: onSurface.withValues(
                              alpha: isDark ? 0.35 : 0.28,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                onTap: onTap,
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.22)
                              : const Color(0xFFBDBDBD),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sheetSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: boxBorder,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            optionRow(
                              title: 'Threads',
                              selected: _notifyThreads,
                              onTap: () => setModalState(() {
                                _notifyThreads = !_notifyThreads;
                              }),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1.5,
                              indent: 16,
                              endIndent: 16,
                              color: theme.dividerColor.withValues(
                                alpha: isDark ? 0.28 : 0.34,
                              ),
                            ),
                            optionRow(
                              title: 'Replies',
                              selected: _notifyReplies,
                              onTap: () => setModalState(() {
                                _notifyReplies = !_notifyReplies;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sheetSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: boxBorder,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text(
                            'Push notifications',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          trailing: Semantics(
                            button: true,
                            toggled: _pushNotificationsEnabled,
                            label: 'Push notifications',
                            child: InkWell(
                              onTap: () => setModalState(() {
                                _pushNotificationsEnabled =
                                    !_pushNotificationsEnabled;
                              }),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOut,
                                width: 54,
                                height: 32,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _pushNotificationsEnabled
                                      ? Colors.black
                                      : (isDark
                                            ? const Color(0xFF4A4A4A)
                                            : const Color(0xFFBDBDBD)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOut,
                                  alignment: _pushNotificationsEnabled
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "You'll get activity notifications for $label.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtle,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openProfileMoreSheet({
    required String handle,
    required bool showSettings,
    required VoidCallback onCopyLink,
  }) async {
    final String label = handle.startsWith('@') ? handle.substring(1) : handle;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFF2F2F2);
    final Color sheetSurface = isDark
        ? theme.colorScheme.surface
        : Colors.white;
    final Color onSurface = theme.colorScheme.onSurface;
    final Border boxBorder = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
      width: 1,
    );

    Widget handleRow({
      required BuildContext context,
      required String title,
      required IconData icon,
      Color? textColor,
      Color? iconColor,
      VoidCallback? onTap,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor ?? onSurface,
          ),
        ),
        trailing: Icon(icon, color: iconColor ?? onSurface),
        onTap: onTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                onTap();
              },
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final divider = Divider(
          height: 1,
          thickness: 1.2,
          indent: 18,
          endIndent: 18,
          color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.32),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        handleRow(
                          context: sheetContext,
                          title: 'QR Code',
                          icon: Icons.qr_code_2_rounded,
                          onTap: () => AppToast.showSnack(
                            context,
                            'QR code coming soon',
                            duration: ToastDurations.standard,
                          ),
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Copy profile link',
                          icon: Icons.link_rounded,
                          onTap: onCopyLink,
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Share to',
                          icon: Icons.ios_share_rounded,
                          onTap: () => AppToast.showSnack(
                            context,
                            'Share sheet coming soon',
                            duration: ToastDurations.standard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showSettings)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: boxBorder,
                      ),
                      child: handleRow(
                        context: sheetContext,
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        handleRow(
                          context: sheetContext,
                          title: 'Block',
                          icon: Icons.block_rounded,
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () => AppToast.showSnack(
                            context,
                            'Blocked $label (coming soon)',
                            duration: ToastDurations.standard,
                          ),
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Report',
                          icon: Icons.report_gmailerrorred_outlined,
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () => AppToast.showSnack(
                            context,
                            'Report $label (coming soon)',
                            duration: ToastDurations.standard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Removed extra safety-actions card; block/report are above.
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
