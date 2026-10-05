import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';

@immutable
class Flashcard {
  const Flashcard({
    required this.id,
    required this.chapterId,
    required this.topicId,
    required this.front,
    required this.back,
    required this.difficulty,
  });

  final String id;
  final String chapterId;
  final String topicId;
  final String front;
  final String back;
  final String difficulty;

  static Flashcard? tryFromJson(Map<String, dynamic> json) {
    final id = JsonReader.readStringOrNull(json, 'id');
    final chapterId = JsonReader.readStringOrNull(json, 'chapterId');
    final front = JsonReader.readStringOrNull(json, 'front');
    final back = JsonReader.readStringOrNull(json, 'back');
    if (id == null || chapterId == null || front == null || back == null) {
      return null;
    }
    return Flashcard(
      id: id,
      chapterId: chapterId,
      topicId: JsonReader.readString(json, 'topicId'),
      front: front,
      back: back,
      difficulty: JsonReader.readString(json, 'difficulty', fallback: 'medium'),
    );
  }
}

/// How the user graded a card during review.
enum ReviewGrade { hard, good, easy }

/// Per-card spaced-repetition state, persisted in SQLite.
///
/// Deterministic scheduling (see plan/02-architecture.md):
///   hard → 1 day, ease −0.15 (floor 1.3)
///   good → max(1, round(interval × ease)), first time 3 days
///   easy → max(4, round(interval × ease × 1.5)), ease +0.15 (cap 2.8)
@immutable
class FlashcardReview {
  const FlashcardReview({
    required this.cardId,
    required this.ease,
    required this.intervalDays,
    required this.dueDate,
    required this.reviewCount,
    this.lastReviewedAt,
  });

  final String cardId;
  final double ease;
  final int intervalDays;
  final DateTime dueDate;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  /// Initial state for a never-reviewed card: due immediately.
  factory FlashcardReview.fresh(String cardId, DateTime now) => FlashcardReview(
        cardId: cardId,
        ease: AppConstants.initialEase,
        intervalDays: 0,
        dueDate: AppDateUtils.dateOnly(now),
        reviewCount: 0,
      );

  bool isDue(DateTime now) =>
      !AppDateUtils.dateOnly(dueDate).isAfter(AppDateUtils.dateOnly(now));

  /// Applies a grade and returns the next state.
  FlashcardReview graded(ReviewGrade grade, DateTime now) {
    double nextEase = ease;
    int nextInterval;
    switch (grade) {
      case ReviewGrade.hard:
        nextEase = (ease - AppConstants.easeStep)
            .clamp(AppConstants.minEase, AppConstants.maxEase);
        nextInterval = AppConstants.hardIntervalDays;
      case ReviewGrade.good:
        nextInterval = reviewCount == 0
            ? AppConstants.initialGoodIntervalDays
            : (intervalDays * ease).round().clamp(1, 36500);
      case ReviewGrade.easy:
        nextEase = (ease + AppConstants.easeStep)
            .clamp(AppConstants.minEase, AppConstants.maxEase);
        final base = intervalDays == 0 ? 1 : intervalDays;
        nextInterval = (base * ease * AppConstants.easyBonus)
            .round()
            .clamp(AppConstants.minEasyIntervalDays, 36500);
    }
    return FlashcardReview(
      cardId: cardId,
      ease: nextEase,
      intervalDays: nextInterval,
      dueDate:
          AppDateUtils.dateOnly(now).add(Duration(days: nextInterval)),
      reviewCount: reviewCount + 1,
      lastReviewedAt: now,
    );
  }

  /// Preview of the interval a grade would produce (for button sublabels).
  int previewIntervalDays(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.hard:
        return AppConstants.hardIntervalDays;
      case ReviewGrade.good:
        return reviewCount == 0
            ? AppConstants.initialGoodIntervalDays
            : (intervalDays * ease).round().clamp(1, 36500);
      case ReviewGrade.easy:
        final base = intervalDays == 0 ? 1 : intervalDays;
        return (base * ease * AppConstants.easyBonus)
            .round()
            .clamp(AppConstants.minEasyIntervalDays, 36500);
    }
  }

  Map<String, dynamic> toDbMap() => {
        'card_id': cardId,
        'ease': ease,
        'interval_days': intervalDays,
        'due_date': dueDate.millisecondsSinceEpoch,
        'review_count': reviewCount,
        'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
      };

  static FlashcardReview fromDbMap(Map<String, dynamic> map) => FlashcardReview(
        cardId: map['card_id'] as String,
        ease: (map['ease'] as num?)?.toDouble() ?? AppConstants.initialEase,
        intervalDays: (map['interval_days'] as num?)?.toInt() ?? 0,
        dueDate: DateTime.fromMillisecondsSinceEpoch(
            (map['due_date'] as num?)?.toInt() ?? 0),
        reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
        lastReviewedAt: map['last_reviewed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (map['last_reviewed_at'] as num).toInt()),
      );
}
