class QuizDraft {
  QuizDraft({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.questionCount,
    required this.isTimed,
    this.timerMinutes,
    this.closingDate,
    this.requirePin = false,
    this.pin,
    this.visibility = 'public',
    this.restrictedAudience,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int questionCount;
  final bool isTimed;
  final int? timerMinutes;
  final DateTime? closingDate;
  final bool requirePin;
  final String? pin;
  final String visibility;
  final String? restrictedAudience;
}

class QuizResultSummary {
  QuizResultSummary({
    required this.title,
    required this.responses,
    required this.averageScore,
    required this.completionRate,
    required this.lastUpdated,
  });

  final String title;
  final int responses;
  final double averageScore;
  final double completionRate;
  final DateTime lastUpdated;
}

class QuizTakeQuestion {
  const QuizTakeQuestion({
    required this.prompt,
    required this.options,
    required this.answerIndex,
  });

  final String prompt;
  final List<String> options;
  final int answerIndex;
}

