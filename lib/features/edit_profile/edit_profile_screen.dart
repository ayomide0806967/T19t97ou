import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/edit_profile_controller.dart';
import 'domain/edit_profile_state.dart';
import 'ui/profile_form_widgets.dart';
import '../../screens/settings_screen.dart';

// Re-export the result class for external use
export 'domain/edit_profile_state.dart' show EditProfileResult;

/// Edit profile screen using Riverpod for state management.
///
/// This refactored version separates:
/// - State (EditProfileState) - immutable data
/// - Controller (EditProfileController) - business logic
/// - Widgets (profile_form_widgets.dart) - reusable UI components
/// - Screen (this file) - composition layer
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialBio,
    required this.initials,
    this.initialHeaderImage,
    this.initialProfileImage,
  });

  final String initialName;
  final String initialBio;
  final String initials;
  final Uint8List? initialHeaderImage;
  final Uint8List? initialProfileImage;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = EditProfileParams(
      initialName: widget.initialName,
      initialBio: widget.initialBio,
      initialHeaderImage: widget.initialHeaderImage,
      initialProfileImage: widget.initialProfileImage,
    );

    return ProviderScope(
      overrides: editProfileOverrides(params),
      child: _EditProfileContent(
        initials: widget.initials,
        nameController: _nameController,
        bioController: _bioController,
      ),
    );
  }
}

class _EditProfileContent extends ConsumerWidget {
  const _EditProfileContent({
    required this.initials,
    required this.nameController,
    required this.bioController,
  });

  final String initials;
  final TextEditingController nameController;
  final TextEditingController bioController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editProfileControllerProvider);
    final controller = ref.read(editProfileControllerProvider.notifier);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.55);

    return WillPopScope(
      onWillPop: () async {
        if (state.isSaving || !controller.hasChanges) return true;
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. If you go back now, they will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        return shouldDiscard ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit profile'),
          actions: [
            TextButton(
              onPressed: () {
                final result = controller.save();
                Navigator.of(context).pop(result);
              },
              child: const Text('Save'),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cover + avatar section
            _buildHeaderSection(state, controller, theme),
            const SizedBox(height: 48),
            // Form fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  LinedField(
                    label: 'Name',
                    controller: nameController,
                    maxLength: 26,
                    onChanged: controller.updateName,
                  ),
                  LinedField(
                    label: 'Bio',
                    controller: bioController,
                    minLines: 2,
                    autoExpand: true,
                    maxLength: 160,
                    onChanged: controller.updateBio,
                  ),
                  LinedTapRow(
                    label: 'Date of birth',
                    value: state.dateOfBirth == null
                        ? 'Add your date of birth'
                        : '${state.dateOfBirth!.day}/${state.dateOfBirth!.month}/${state.dateOfBirth!.year}',
                    valueColor: state.dateOfBirth == null ? subtle : onSurface,
                    onTap: () => _pickDateOfBirth(context, controller),
                  ),
                  const SizedBox(height: 18),
                  ToggleRow(
                    label: 'Private account',
                    valueLabel: state.isPrivateAccount ? 'On' : 'Off',
                    value: state.isPrivateAccount,
                    onChanged: controller.togglePrivateAccount,
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Open other settings'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    EditProfileState state,
    EditProfileController controller,
    ThemeData theme,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: controller.pickHeaderImage,
          child: Container(
            height: 160,
            width: double.infinity,
            color: const Color(0xFFF3F4F6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (state.headerImage != null)
                  Image.memory(
                    state.headerImage!,
                    fit: BoxFit.cover,
                  ),
                Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: -32,
          child: GestureDetector(
            onTap: controller.pickProfileImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    image: state.profileImage != null
                        ? DecorationImage(
                            image: MemoryImage(state.profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: state.profileImage == null
                      ? Text(
                          initials,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateOfBirth(
    BuildContext context,
    EditProfileController controller,
  ) async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      controller.updateDateOfBirth(picked);
    }
  }
}
