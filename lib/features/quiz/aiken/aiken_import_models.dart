import 'package:flutter/material.dart';

String normalizeAikenPrompt(String text) {
  final trimmed = text.trim();
  final withoutNumber = trimmed.replaceFirst(
    RegExp(
      r'^(?:Q(?:uestion)?\s*)?[\(\[]?\s*\d+\s*[\)\.\:\]]?\s*',
      caseSensitive: false,
    ),
    '',
  );
  return withoutNumber.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// Result returned from the Aiken import review screen.
class AikenImportResult {
  AikenImportResult({
    required this.questions,
    this.importMore = false,
  });

  final List<ImportedQuestion> questions;
  final bool importMore;
}

/// Represents an imported question with editable controllers.
class ImportedQuestion {
  ImportedQuestion({
    required this.prompt,
    required this.options,
    this.correctIndex = 0,
    this.promptImage,
    List<String?>? optionImages,
  }) : optionImages = optionImages ?? List.filled(options.length, null);

  factory ImportedQuestion.empty() {
    return ImportedQuestion(
      prompt: TextEditingController(),
      options: List.generate(4, (_) => TextEditingController()),
      optionImages: List.generate(4, (_) => null),
    );
  }

  final TextEditingController prompt;
  final List<TextEditingController> options;
  int correctIndex;
  String? promptImage;
  List<String?> optionImages;

  ImportedQuestion copy() {
    return ImportedQuestion(
      prompt: TextEditingController(text: prompt.text),
      options: options.map((c) => TextEditingController(text: c.text)).toList(),
      correctIndex: correctIndex,
      promptImage: promptImage,
      optionImages: List.from(optionImages),
    );
  }

  void dispose() {
    prompt.dispose();
    for (final c in options) {
      c.dispose();
    }
  }
}

/// Parses Aiken format text into a list of [ImportedQuestion].
List<ImportedQuestion> parseAikenQuestions(String raw) {
  final List<ImportedQuestion> result = [];
  final List<String> lines = raw.split(RegExp(r'\r?\n'));

  String? currentPrompt;
  List<String> options = [];
  String? correctLetter;

  final Set<String> seenPrompts = {};

  void commitQuestion() {
    if (currentPrompt == null || currentPrompt!.trim().isEmpty) {
      currentPrompt = null;
      options = [];
      correctLetter = null;
      return;
    }
    if (options.isEmpty) {
      options = [currentPrompt!.trim()];
    }

    final normalizedPrompt = normalizeAikenPrompt(currentPrompt!);
    if (normalizedPrompt.isEmpty || seenPrompts.contains(normalizedPrompt)) {
      currentPrompt = null;
      options = [];
      correctLetter = null;
      return;
    }
    seenPrompts.add(normalizedPrompt);

    final q = ImportedQuestion(
      prompt: TextEditingController(text: currentPrompt!.trim()),
      options: options.map((o) => TextEditingController(text: o.trim())).toList(),
      correctIndex: 0,
    );

    if (correctLetter != null) {
      const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      final idx = letters.indexOf(correctLetter!.toUpperCase());
      if (idx >= 0 && idx < options.length) {
        q.correctIndex = idx;
      }
    }

    while (q.options.length < 2) {
      q.options.add(TextEditingController());
    }

    result.add(q);

    currentPrompt = null;
    options = [];
    correctLetter = null;
  }

  final answerRegex = RegExp(
    r'^(?:ANSWER|ANS|KEY|CORRECT(?:\s+ANSWER)?)\b.*?([A-Ha-h])[^A-Za-z0-9]*$',
    caseSensitive: false,
  );

  final optionRegex = RegExp(
    r'^\s*[\(\[]?\s*([A-Ha-h])\s*[\)\.\:\]\-]?\s*(.+)$',
  );

  final questionNumberRegex = RegExp(
    r'^\s*(?:Q(?:uestion)?\s*)?[\(\[]?\s*\d+\s*[\)\.\:\]]?\s*(.+)$',
    caseSensitive: false,
  );

  for (int i = 0; i < lines.length; i++) {
    final String trimmedLine = lines[i].trim();

    if (trimmedLine.isEmpty) continue;

    if (currentPrompt == null && options.isEmpty) {
      final int colonIndex = trimmedLine.indexOf(':');
      if (colonIndex != -1 && colonIndex < trimmedLine.length - 1) {
        final String left = trimmedLine.substring(0, colonIndex).trim();
        final String right = trimmedLine.substring(colonIndex + 1).trim();
        final String normLeft = normalizeAikenPrompt(left);
        final String normRight = normalizeAikenPrompt(right);
        if (normLeft.isNotEmpty &&
            normLeft == normRight &&
            !seenPrompts.contains(normLeft)) {
          final q = ImportedQuestion(
            prompt: TextEditingController(text: left),
            options: [
              TextEditingController(text: right),
            ],
            correctIndex: 0,
          );
          while (q.options.length < 2) {
            q.options.add(TextEditingController());
          }
          result.add(q);
          seenPrompts.add(normLeft);
          continue;
        }
      }
    }

    final answerMatch = answerRegex.firstMatch(trimmedLine);
    if (answerMatch != null) {
      correctLetter = answerMatch.group(1)!.toUpperCase();
      commitQuestion();
      continue;
    }

    final optMatch = optionRegex.firstMatch(trimmedLine);
    if (optMatch != null) {
      final letter = optMatch.group(1)!.toUpperCase();
      final optionText = optMatch.group(2)!.trim();

      const validLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      if (validLetters.contains(letter)) {
        final expectedIdx = options.length;
        final letterIdx = validLetters.indexOf(letter);

        if (expectedIdx == letterIdx ||
            options.isEmpty ||
            (letterIdx >= expectedIdx && letterIdx <= expectedIdx + 1)) {
          options.add(optionText);
          continue;
        }
      }
    }

    final numMatch = questionNumberRegex.firstMatch(trimmedLine);
    if (numMatch != null && options.isEmpty) {
      currentPrompt = numMatch.group(1)!.trim();
      continue;
    }

    if (options.isEmpty) {
      if (currentPrompt == null) {
        currentPrompt = trimmedLine;
      } else {
        currentPrompt = '$currentPrompt\n$trimmedLine';
      }
    }
  }

  commitQuestion();
  return result;
}
