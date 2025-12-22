part of '../ios_messages_screen.dart';

mixin _LectureSetupFormBuild on _LectureSetupFormStateBase {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.black, width: 1.8),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: _StepRailMini(activeIndex: _step, steps: const ['1', '2']),
            ),
          ),
          if (_step == 0) ...[
            Text(
              'Lecture details',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Theme(
                data: theme.copyWith(
                  inputDecorationTheme: inputTheme,
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.black,
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _courseController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Course name',
                        hintText: 'e.g., Biology 401 · Genetics',
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter course name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tutorController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Tutor name (optional)',
                        hintText: 'e.g., Dr. Tayo Ajayi',
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _topicController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g., Mendelian inheritance, DNA structure',
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter topic' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _step = 1);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Next'),
              ),
            ),
          ] else ...[
            Text(
              'Access & privacy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingSwitchRow(
                    label: 'Private lecture (disable repost)',
                    value: _privateLecture,
                    onChanged: (v) => setState(() => _privateLecture = v),
                    monochrome: true,
                  ),
                  SettingSwitchRow(
                    label: 'Require PIN to access',
                    value: _requirePin,
                    onChanged: (v) => setState(() => _requirePin = v),
                    monochrome: true,
                  ),
                  SettingSwitchRow(
                    label: 'Add quiz for note',
                    value: _attachQuizForNote,
                    onChanged: (v) => setState(() => _attachQuizForNote = v),
                    monochrome: true,
                  ),
                  if (_requirePin) ...[
                    const SizedBox(height: 6),
                    Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: inputTheme,
                        textSelectionTheme: const TextSelectionThemeData(
                          cursorColor: Colors.black,
                        ),
                      ),
                      child: TextFormField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'PIN code',
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (v) {
                          if (!_requirePin) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a PIN code';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Auto-archive', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      if (_autoArchiveAt != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _autoArchiveAt = null),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                  if (_autoArchiveAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _autoArchiveAt!.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: const Color(0xFF075E54),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _pickDateTime(context),
                      child: const Text('Date/time'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 0),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start lecture'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
