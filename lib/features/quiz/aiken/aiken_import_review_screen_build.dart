part of 'aiken_import_review_screen.dart';

mixin _AikenImportReviewScreenBuild
    on _AikenImportReviewScreenStateBase, _AikenImportReviewScreenActions {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background = isDark ? const Color(0xFF0B0D11) : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleClosePressed();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: _handleClosePressed,
            tooltip: 'Back',
          ),
          title: Text(
            'Review Imported Questions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: false,
          actions: const [SizedBox(width: 8)],
        ),
        body: Column(
          children: [
            // Summary header + search
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _whatsAppTeal, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: _whatsAppTeal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_questions.length} question${_questions.length == 1 ? '' : 's'} imported. Tap to expand and edit.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search imported questions',
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            isDense: true,
                            filled: true,
                            // Light grey pill for the search input itself
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(999),
                              ),
                              borderSide: const BorderSide(
                                color: _whatsAppTeal,
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _confirmImport,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Questions list (filtered by search)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (() {
                  final visible =
                      List<int>.generate(_questions.length, (i) => i).where((
                        i,
                      ) {
                        if (_searchQuery.trim().isEmpty) return true;
                        final q = _questions[i];
                        final query = _searchQuery.toLowerCase();
                        final prompt = q.prompt.text.toLowerCase();
                        if (prompt.contains(query)) return true;
                        for (final opt in q.options) {
                          if (opt.text.toLowerCase().contains(query)) {
                            return true;
                          }
                        }
                        return false;
                      }).toList();
                  // +2 for "add question manually" and "import more"
                  return visible.length + 2;
                })(),
                itemBuilder: (context, index) {
                  // Recompute visible indices for this builder
                  final visible =
                      List<int>.generate(_questions.length, (i) => i).where((
                        i,
                      ) {
                        if (_searchQuery.trim().isEmpty) return true;
                        final q = _questions[i];
                        final query = _searchQuery.toLowerCase();
                        final prompt = q.prompt.text.toLowerCase();
                        if (prompt.contains(query)) return true;
                        for (final opt in q.options) {
                          if (opt.text.toLowerCase().contains(query)) {
                            return true;
                          }
                        }
                        return false;
                      }).toList();

                  if (index == visible.length) {
                    // Add question button
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add question manually'),
                        style: TextButton.styleFrom(
                          foregroundColor: _whatsAppTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: _whatsAppTeal.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (index == visible.length + 1) {
                    // Import more Aiken file button
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        onPressed: () => _confirmImport(importMore: true),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Import more Aiken file'),
                        style: TextButton.styleFrom(
                          foregroundColor: _whatsAppTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: _whatsAppTeal.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final questionIndex = visible[index];
                  final q = _questions[questionIndex];
                  final isExpanded = _expandedIndex == questionIndex;

                  return _QuestionCard(
                    index: questionIndex,
                    question: q,
                    isExpanded: isExpanded,
                    onToggleExpand: () => _toggleExpand(questionIndex),
                    onAddOption: () => _addOption(questionIndex),
                    onRemoveOption: (optIdx) =>
                        _removeOption(questionIndex, optIdx),
                    onSetCorrect: (optIdx) =>
                        _setCorrect(questionIndex, optIdx),
                    onRemove: () => _removeQuestion(questionIndex),
                    onPickPromptImage: () => _pickPromptImage(questionIndex),
                    onRemovePromptImage: () =>
                        _removePromptImage(questionIndex),
                    onPickOptionImage: (optIdx) =>
                        _pickOptionImage(questionIndex, optIdx),
                    onRemoveOptionImage: (optIdx) =>
                        _removeOptionImage(questionIndex, optIdx),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showActionsSheet,
          backgroundColor: _whatsAppTeal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
