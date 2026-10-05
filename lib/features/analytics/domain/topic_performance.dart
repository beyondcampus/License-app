import 'package:flutter/foundation.dart';

/// Aggregated user performance on one topic, computed from stored attempts.
@immutable
class TopicPerformance {
  const TopicPerformance({
    required this.topicId,
    required this.chapterId,
    required this.attempted,
    required this.correct,
  });

  final String topicId;
  final String chapterId;
  final int attempted;
  final int correct;

  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

/// Aggregated per-chapter accuracy (for the analytics bar chart).
@immutable
class ChapterPerformance {
  const ChapterPerformance({
    required this.chapterId,
    required this.attempted,
    required this.correct,
  });

  final String chapterId;
  final int attempted;
  final int correct;

  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

/// Overall user progress snapshot for the dashboard.
@immutable
class UserProgress {
  const UserProgress({
    required this.readiness,
    required this.streak,
    required this.completedTopics,
    required this.totalTopics,
  });

  final double readiness;
  final int streak;
  final int completedTopics;
  final int totalTopics;

  static const empty = UserProgress(
      readiness: 0, streak: 0, completedTopics: 0, totalTopics: 0);
}
