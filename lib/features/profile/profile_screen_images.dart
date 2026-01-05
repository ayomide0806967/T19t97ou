part of 'profile_screen.dart';

extension _ProfileScreenImages on _ProfileScreenState {
  Future<void> _handlePickProfileImage() async {
    if (widget.readOnly) return;
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 720,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _setLocalProfileImage(bytes);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateAvatar(bytes.toList(growable: false));
      final profile = ref.read(profileRepositoryProvider).profile;
      final postRepo = ref.read(postRepositoryProvider);
      if (postRepo is SupabasePostRepository) {
        postRepo.updateAvatarUrlForHandle(_currentUserHandle, profile.avatarUrl);
      }
      if (!mounted) return;
      AppToast.showSnack(
        context,
        'Profile photo updated',
        duration: ToastDurations.standard,
      );
    } catch (e) {
      debugPrint('Avatar upload failed: $e');
      if (!mounted) return;
      AppToast.showSnack(
        context,
        'Could not upload profile photo: ${e.toString().replaceFirst('Exception: ', '')}',
        duration: ToastDurations.standard,
      );
    }
  }

  Future<void> _showProfilePhotoViewer() async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final remoteUrl = profileRepo.profile.avatarUrl;
    final ImageProvider? imageProvider = _profileImage != null
        ? MemoryImage(_profileImage!)
        : (remoteUrl != null ? NetworkImage(remoteUrl) : null);
    final bool hasImage = imageProvider != null;
    final String initials = initialsFrom(
      (ref.read(authRepositoryProvider).currentUser?.email ??
          'user@institution.edu'),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      image: hasImage
                          ? DecorationImage(image: imageProvider!, fit: BoxFit.cover)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: hasImage
                        ? null
                        : Text(
                            initials,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                if (hasImage)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _openFullImage(
                        image: imageProvider!,
                        title: 'Profile photo',
                      );
                    },
                    child: const Text('View full picture'),
                  ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _handlePickProfileImage();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Change photo'),
                ),
                if (_profileImage != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _setLocalProfileImage(null);
                      AppToast.showSnack(
                        context,
                        'Profile photo removed',
                        duration: ToastDurations.standard,
                      );
                    },
                    child: const Text('Remove current photo'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHeaderImageViewer() async {
    final theme = Theme.of(context);
    final profileRepo = ref.read(profileRepositoryProvider);
    final remoteUrl = profileRepo.profile.headerUrl;
    final ImageProvider? imageProvider = _headerImage != null
        ? MemoryImage(_headerImage!)
        : (remoteUrl != null ? NetworkImage(remoteUrl) : null);
    final hasImage = imageProvider != null;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 32,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasImage
                        ? Image(image: imageProvider!, fit: BoxFit.cover)
                        : Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.wallpaper_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                if (hasImage)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _openFullImage(
                        image: imageProvider!,
                        title: 'Cover photo',
                      );
                    },
                    child: const Text('View full picture'),
                  ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _handleChangeHeader();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Change cover photo'),
                ),
                if (_headerImage != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _setLocalHeaderImage(null);
                      AppToast.showSnack(
                        context,
                        'Cover photo removed',
                        duration: ToastDurations.standard,
                      );
                    },
                    child: const Text('Remove current photo'),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFullImage({
    required ImageProvider image,
    String? title,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: title != null ? Text(title) : null,
          ),
          body: InteractiveViewer(
            constrained: false,
            minScale: 1.0,
            maxScale: 6.0,
            child: Center(
              child: Image(image: image, fit: BoxFit.none),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFullPlaceholder({
    required Widget child,
    String? title,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: title != null ? Text(title) : null,
          ),
          body: Center(child: child),
        ),
      ),
    );
  }

  Future<void> _openProfilePhotoDirect() async {
    if (_profileImage != null) {
      return _openFullImage(
        image: MemoryImage(_profileImage!),
        title: 'Profile photo',
      );
    }
    final initials = initialsFrom(widget.handleOverride ?? _currentUserHandle);
    return _openFullPlaceholder(
      title: 'Profile photo',
      child: Container(
        width: 260,
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          initials,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Future<void> _openHeaderPhotoDirect() async {
    if (_headerImage != null) {
      return _openFullImage(
        image: MemoryImage(_headerImage!),
        title: 'Cover photo',
      );
    }
    return _openFullPlaceholder(
      title: 'Cover photo',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Icon(
              Icons.wallpaper_outlined,
              color: Colors.white70,
              size: 72,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangeHeader() async {
    if (widget.readOnly) return;
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<_HeaderAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update cover image',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () =>
                      Navigator.of(context).pop(_HeaderAction.pickImage),
                ),
                if (_headerImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove photo'),
                    onTap: () =>
                        Navigator.of(context).pop(_HeaderAction.removeImage),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (action) {
      case _HeaderAction.pickImage:
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1600,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        _setLocalHeaderImage(bytes);
        try {
          await ref
              .read(profileRepositoryProvider)
              .updateHeader(bytes.toList(growable: false));
          if (!mounted) return;
          AppToast.showSnack(
            context,
            'Cover photo updated',
            duration: ToastDurations.standard,
          );
        } catch (e) {
          debugPrint('Header upload failed: $e');
          if (!mounted) return;
          AppToast.showSnack(
            context,
            'Could not upload cover photo: ${e.toString().replaceFirst('Exception: ', '')}',
            duration: ToastDurations.standard,
          );
        }
        break;
      case _HeaderAction.removeImage:
        _setLocalHeaderImage(null);
        AppToast.showSnack(
          context,
          'Cover photo removed',
          duration: ToastDurations.standard,
        );
        break;
      case null:
        break;
    }
  }
}
