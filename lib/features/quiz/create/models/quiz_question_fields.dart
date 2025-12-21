import 'package:flutter/material.dart';

class QuizQuestionFields {
  QuizQuestionFields()
      : prompt = TextEditingController(),
        options = List<TextEditingController>.generate(
          4,
          (_) => TextEditingController(),
        ),
        optionImages = List<String?>.filled(4, null, growable: true),
        promptImage = null;

  final TextEditingController prompt;
  final List<TextEditingController> options;
  int correctIndex = 0;
  final List<String?> optionImages;
  String? promptImage;

  void dispose() {
    prompt.dispose();
    for (final controller in options) {
      controller.dispose();
    }
  }
}

