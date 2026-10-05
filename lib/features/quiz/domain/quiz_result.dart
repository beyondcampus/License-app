import 'package:flutter/foundation.dart';

/// The mode a quiz session runs in.
enum QuizMode { practice, timed, mock, bookmarked, fullExam }

/// One recorded answer inside a finished quiz.
@immutable
class QuestionAttempt {
  const QuestionAttempt({
    required this.questionId,
    required this.chapterId,
    required this.topicId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.timeMs,
  });

  final String questionId;
  final String chapterId;
  final String topicId;

  /// -1 means unanswered.
  final int selectedIndex;
  final bool isCorrect;
  final int timeMs;

  Map<String, dynamic> toDbMap(int resultId) => {
        'result_id': resultId,
        'question_id': questionId,
        'chapter_id': chapterId,
        'topic_id': topicId,
        'selected_index': selectedIndex,
        'is_correct': isCorrect ? 1 : 0,
        'time_ms': timeMs,
      };

  static QuestionAttempt fromDbMap(Map<String, dynamic> map) =>
      QuestionAttempt(
        questionId: map['question_id'] as String,
        chapterId: map['chapter_id'] as String,
        topicId: map['topic_id'] as String,
        selectedIndex: (map['selected_index'] as num?)?.toInt() ?? -1,
        isCorrect: (map['is_correct'] as num?) == 1,
        timeMs: (map['time_ms'] as num?)?.toInt() ?? 0,
      );
}

/// A finished quiz, persisted to SQLite.
@immutable
class QuizResult {
  const QuizResult({
    this.id,
    required this.mode,
    required this.chapterId,
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
    required this.timeSeconds,
    required this.takenAt,
  });

  /// DB row id (null before insert).
  final int? id;
  final QuizMode mode;

  /// Null for cross-chapter (mock/bookmarked) quizzes.
  final String? chapterId;
  final int total;
  final int correct;
  final int incorrect;
  final int unanswered;
  final int timeSeconds;
  final DateTime takenAt;

  double get accuracy {
    final answered = correct + incorrect;
    return answered == 0 ? 0 : correct / answered;
  }

  double get scoreRatio => total == 0 ? 0 : correct / total;

  double get avgSecondsPerQuestion => total == 0 ? 0 : timeSeconds / total;

  Map<String, dynamic> toDbMap() => {
        if (id != null) 'id': id,
        'mode': mode.name,
        'chapter_id': chapterId,
        'total': total,
        'correct': correct,
        'incorrect': incorrect,
        'unanswered': unanswered,
        'time_seconds': timeSeconds,
        'taken_at': takenAt.millisecondsSinceEpoch,
      };

  static QuizResult fromDbMap(Map<String, dynamic> map) => QuizResult(
        id: (map['id'] as num?)?.toInt(),
        mode: QuizMode.values
                .where((m) => m.name == map['mode'])
                .firstOrNull ??
            QuizMode.practice,
        chapterId: map['chapter_id'] as String?,
        total: (map['total'] as num?)?.toInt() ?? 0,
        correct: (map['correct'] as num?)?.toInt() ?? 0,
        incorrect: (map['incorrect'] as num?)?.toInt() ?? 0,
        unanswered: (map['unanswered'] as num?)?.toInt() ?? 0,
        timeSeconds: (map['time_seconds'] as num?)?.toInt() ?? 0,
        takenAt: DateTime.fromMillisecondsSinceEpoch(
            (map['taken_at'] as num?)?.toInt() ?? 0),
      );
}
