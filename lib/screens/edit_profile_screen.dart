import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'settings_screen.dart';

class EditProfileResult {
  const EditProfileResult({
    required this.headerImage,
    required this.profileImage,
    required this.name,
    required this.bio,
    required this.location,
    required this.website,
    required this.dateOfBirth,
    required this.isPrivateAccount,
    required this.tipsEnabled,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
  final String name;
  final String bio;
  final String location;
  final String website;
  final DateTime? dateOfBirth;
  final bool isPrivateAccount;
  final bool tipsEnabled;
}

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
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  Uint8List? _headerImage;
  Uint8List? _profileImage;
  DateTime? _dob;
  bool _isPrivate = false;
  bool _tipsEnabled = false;
  bool _isSaving = false;

  bool get _hasChanges {
    if (_nameController.text.trim() != widget.initialName.trim()) return true;
    if (_bioController.text.trim() != widget.initialBio.trim()) return true;
    if (_locationController.text.trim().isNotEmpty) return true;
    if (_websiteController.text.trim().isNotEmpty) return true;
    if (_headerImage != widget.initialHeaderImage) return true;
    if (_profileImage != widget.initialProfileImage) return true;
    if (_dob != null) return true;
    if (_isPrivate) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
    _headerImage = widget.initialHeaderImage;
    _profileImage = widget.initialProfileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickHeader() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _headerImage = bytes);
  }

  Future<void> _pickAvatar() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _profileImage = bytes);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  void _save() {
    _isSaving = true;
    String bio = _bioController.text.trim();
    if (bio.length > 160) {
      bio = bio.substring(0, 160);
    }
    final result = EditProfileResult(
      headerImage: _headerImage,
      profileImage: _profileImage,
      name: _nameController.text.trim(),
      bio: bio,
      location: _locationController.text.trim(),
      website: _websiteController.text.trim(),
      dateOfBirth: _dob,
      isPrivateAccount: _isPrivate,
      tipsEnabled: _tipsEnabled,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.55);

    return WillPopScope(
      onWillPop: () async {
        if (_isSaving || !_hasChanges) return true;
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
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cover + avatar (matches the screenshot style)
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _pickHeader,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: const Color(0xFFF3F4F6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_headerImage != null)
                        Image.memory(
                          _headerImage!,
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
                  onTap: _pickAvatar,
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
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: MemoryImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: _profileImage == null
                            ? Text(
                                widget.initials,
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
          ),
          const SizedBox(height: 48),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _LinedField(
                  label: 'Name',
                  controller: _nameController,
                  maxLength: 26,
                ),
                _LinedField(
                  label: 'Bio',
                  controller: _bioController,
                  minLines: 2,
                  autoExpand: true,
                  maxLength: 160,
                ),
                _LinedTapRow(
                  label: 'Date of birth',
                  value: _dob == null
                      ? 'Add your date of birth'
                      : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                  valueColor: _dob == null ? subtle : onSurface,
                  onTap: _pickDob,
                ),
                const SizedBox(height: 18),
                _ToggleRow(
                  label: 'Private account',
                  valueLabel: _isPrivate ? 'On' : 'Off',
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
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
}

class _LinedField extends StatefulWidget {
  const _LinedField({
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.minLines,
    this.autoExpand = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final int? minLines;
  final bool autoExpand;

  @override
  State<_LinedField> createState() => _LinedFieldState();
}

class _LinedFieldState extends State<_LinedField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _hasFocus = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.45);

    final int? effectiveMinLines =
        widget.minLines ?? (widget.autoExpand ? 1 : widget.maxLines);
    final int? effectiveMaxLines = widget.autoExpand ? null : widget.maxLines;

    final Color dividerColor = _hasFocus
        ? const Color(0xFF00838F)
        : theme.dividerColor.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(color: subtle),
        ),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.only(top: 6, bottom: 10),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: effectiveMinLines,
            maxLines: effectiveMaxLines,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              hintText: widget.hintText,
              counterText: widget.maxLength != null ? '' : null,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurface,
              fontSize: 16,
            ),
          ),
        ),
        Divider(
          color: dividerColor,
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }
}

class _LinedTapRow extends StatelessWidget {
  const _LinedTapRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontSize: 16,
              ),
            ),
          ),
          Divider(
            color: theme.dividerColor.withValues(alpha: 0.9),
            thickness: 1,
            height: 1,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.45);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(valueLabel, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: const Color(0xFFF3F4F6),
      ),
      onTap: () => onChanged(!value),
    );
  }
}
