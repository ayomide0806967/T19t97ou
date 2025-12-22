import 'package:flutter/material.dart';

part 'quiz_live_monitor_screen_actions.dart';
part 'quiz_live_monitor_screen_build.dart';
part 'quiz_live_monitor_screen_widgets.dart';

/// Live quiz monitor screen.
///
/// This screen lets the instructor see, in real time:
/// - Who is online and taking the quiz
/// - Who has submitted
/// - Who is offline / not started
/// - For each participant: how many questions answered and which question
///   they are currently on.
class QuizLiveMonitorScreen extends StatefulWidget {
  const QuizLiveMonitorScreen({super.key, required this.quizTitle});

  final String quizTitle;

  @override
  State<QuizLiveMonitorScreen> createState() => _QuizLiveMonitorScreenState();
}

enum ParticipantStatus { inProgress, submitted, offline, suspect, terminated }

class LiveParticipant {
  LiveParticipant({
    required this.name,
    required this.id,
    required this.status,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.answeredCount,
    required this.lastSeen,
  });

  final String name;
  final String id;
  final ParticipantStatus status;
  final int currentQuestion;
  final int totalQuestions;
  final int answeredCount;
  final DateTime lastSeen;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  double get progress => totalQuestions == 0
      ? 0
      : answeredCount.clamp(0, totalQuestions) / totalQuestions;
}

abstract class _QuizLiveMonitorScreenStateBase
    extends State<QuizLiveMonitorScreen> {
  late final List<LiveParticipant> _participants;
  String _filter = 'all'; // all, online, submitted, offline
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Sample data – replace with real-time data from backend.
    final now = DateTime.now();
    _participants = <LiveParticipant>[
      LiveParticipant(
        name: 'Marcel',
        id: 'M1',
        status: ParticipantStatus.inProgress,
        currentQuestion: 8,
        totalQuestions: 20,
        answeredCount: 7,
        lastSeen: now.subtract(const Duration(seconds: 5)),
      ),
      LiveParticipant(
        name: 'Becky',
        id: 'B2',
        status: ParticipantStatus.submitted,
        currentQuestion: 20,
        totalQuestions: 20,
        answeredCount: 20,
        lastSeen: now.subtract(const Duration(minutes: 2)),
      ),
      LiveParticipant(
        name: 'Tara',
        id: 'T3',
        status: ParticipantStatus.inProgress,
        currentQuestion: 4,
        totalQuestions: 20,
        answeredCount: 3,
        lastSeen: now.subtract(const Duration(seconds: 20)),
      ),
      LiveParticipant(
        name: 'Andrew',
        id: 'A4',
        status: ParticipantStatus.terminated,
        currentQuestion: 0,
        totalQuestions: 20,
        answeredCount: 0,
        lastSeen: now.subtract(const Duration(minutes: 15)),
      ),
      LiveParticipant(
        name: 'Mia',
        id: 'M5',
        status: ParticipantStatus.submitted,
        currentQuestion: 20,
        totalQuestions: 20,
        answeredCount: 20,
        lastSeen: now.subtract(const Duration(minutes: 5)),
      ),
      LiveParticipant(
        name: 'Robin',
        id: 'R6',
        status: ParticipantStatus.suspect,
        currentQuestion: 15,
        totalQuestions: 20,
        answeredCount: 14,
        lastSeen: now.subtract(const Duration(seconds: 10)),
      ),
    ];
  }

  int get _onlineCount => _participants
      .where((p) => p.status == ParticipantStatus.inProgress)
      .length;

  int get _submittedCount => _participants
      .where((p) => p.status == ParticipantStatus.submitted)
      .length;

  int get _offlineCount =>
      _participants.where((p) => p.status == ParticipantStatus.offline).length;

  List<LiveParticipant> get _filteredParticipants {
    final String query = _searchController.text.trim().toLowerCase();

    Iterable<LiveParticipant> filtered = _participants;

    switch (_filter) {
      case 'online':
        filtered = filtered.where(
          (p) => p.status == ParticipantStatus.inProgress,
        );
        break;
      case 'submitted':
        filtered = filtered.where(
          (p) => p.status == ParticipantStatus.submitted,
        );
        break;
      case 'offline':
        filtered = filtered.where((p) => p.status == ParticipantStatus.offline);
        break;
      case 'suspect':
        filtered = filtered.where((p) => p.status == ParticipantStatus.suspect);
        break;
      case 'terminated':
        filtered = filtered.where(
          (p) => p.status == ParticipantStatus.terminated,
        );
        break;
      case 'all':
      default:
        break;
    }

    if (query.isEmpty) {
      return filtered.toList();
    }

    return filtered
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query),
        )
        .toList();
  }
}

class _QuizLiveMonitorScreenState extends _QuizLiveMonitorScreenStateBase
    with _QuizLiveMonitorScreenActions, _QuizLiveMonitorScreenBuild {}
