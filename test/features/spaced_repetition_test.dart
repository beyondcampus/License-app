import 'package:exam_prep_pro/features/flashcards/domain/flashcard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day0 = DateTime(2026, 9, 14, 15, 30);

  group('FlashcardReview scheduling', () {
    test('fresh card is due immediately', () {
      final review = FlashcardReview.fresh('c1', day0);
      expect(review.isDue(day0), isTrue);
      expect(review.reviewCount, 0);
      expect(review.ease, 2.0);
    });

    test('hard → 1 day interval, ease decreases with floor 1.3', () {
      var review = FlashcardReview.fresh('c1', day0);
      review = review.graded(ReviewGrade.hard, day0);
      expect(review.intervalDays, 1);
      expect(review.ease, closeTo(1.85, 0.001));
      expect(review.dueDate, DateTime(2026, 9, 15));
      expect(review.isDue(day0), isFalse);
      expect(review.isDue(DateTime(2026, 9, 15, 8)), isTrue);

      // Repeated hard grades never push ease below the floor.
      for (var i = 0; i < 10; i++) {
        review = review.graded(ReviewGrade.hard, day0);
      }
      expect(review.ease, closeTo(1.3, 0.001));
    });

    test('good → 3 days first time, then interval × ease', () {
      var review = FlashcardReview.fresh('c1', day0);
      review = review.graded(ReviewGrade.good, day0);
      expect(review.intervalDays, 3);
      expect(review.ease, 2.0); // unchanged
      review = review.graded(ReviewGrade.good, DateTime(2026, 9, 17));
      expect(review.intervalDays, 6); // 3 × 2.0
      expect(review.dueDate, DateTime(2026, 9, 23));
    });

    test('easy → longer interval and ease increases with cap 2.8', () {
      var review = FlashcardReview.fresh('c1', day0);
      review = review.graded(ReviewGrade.easy, day0);
      // base 1 × ease 2.0 × bonus 1.5 = 3 → clamped to min 4.
      expect(review.intervalDays, 4);
      expect(review.ease, closeTo(2.15, 0.001));

      for (var i = 0; i < 10; i++) {
        review = review.graded(ReviewGrade.easy, day0);
      }
      expect(review.ease, closeTo(2.8, 0.001));
    });

    test('preview ordering: hard < good < easy for a mid-progress card', () {
      final review = FlashcardReview.fresh('c1', day0)
          .graded(ReviewGrade.good, day0); // interval 3, ease 2.0
      expect(review.previewIntervalDays(ReviewGrade.hard), 1);
      expect(review.previewIntervalDays(ReviewGrade.good), 6);
      expect(review.previewIntervalDays(ReviewGrade.easy), 9);
    });

    test('deterministic: same grades produce identical schedules', () {
      FlashcardReview run() {
        var r = FlashcardReview.fresh('c1', day0);
        r = r.graded(ReviewGrade.good, day0);
        r = r.graded(ReviewGrade.hard, DateTime(2026, 9, 17));
        r = r.graded(ReviewGrade.easy, DateTime(2026, 9, 18));
        return r;
      }

      final a = run();
      final b = run();
      expect(a.intervalDays, b.intervalDays);
      expect(a.ease, b.ease);
      expect(a.dueDate, b.dueDate);
      expect(a.reviewCount, 3);
    });

    test('db map round trip', () {
      final review = FlashcardReview.fresh('c9', day0)
          .graded(ReviewGrade.good, day0);
      final restored = FlashcardReview.fromDbMap(review.toDbMap());
      expect(restored.cardId, 'c9');
      expect(restored.intervalDays, review.intervalDays);
      expect(restored.ease, review.ease);
      expect(restored.dueDate, review.dueDate);
      expect(restored.reviewCount, 1);
      expect(restored.lastReviewedAt, review.lastReviewedAt);
    });
  });
}
