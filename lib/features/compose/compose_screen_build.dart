part of 'compose_screen.dart';

mixin _ComposeScreenBuild on _ComposeScreenStateBase {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!hasUnsavedChanges) {
          Navigator.of(context).pop();
          return;
        }
        await handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: handleExit,
          ),
          title: const Text(
            'New Post',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Drafts coming soon'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
              child: const Text(
                'Drafts',
                style: TextStyle(
                  color: Color(0xFF128C7E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: canPost ? post : null,
              child: Text(
                'Post',
                style: TextStyle(
                  color: canPost ? AppTheme.accent : const Color(0xFFCBD5E1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (MediaQuery.of(context).viewInsets.bottom == 0) {
              FocusScope.of(context).requestFocus(textFocusNode);
            }
          },
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HexagonAvatar(
                            size: 44,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _AudienceChip(
                                label: replyPermissionLabel,
                                onTap: onAudienceTap,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        focusNode: textFocusNode,
                        autofocus: true,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: "What's happening?",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: largeText ? 20 : 16,
                          color: Colors.black,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _RecentMediaStrip(media: media),
                      const SizedBox(height: 12),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ComposerActionsRow(
                            onPickImages: pickImages,
                            onToggleTextStyle: toggleTextSize,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${controller.text.length}/280',
                          style: TextStyle(
                            color: controller.text.length > 280
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
