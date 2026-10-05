import 'package:exam_prep_pro/features/bookmarks/domain/bookmark.dart';
import 'package:exam_prep_pro/features/flashcards/domain/flashcard.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_deps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpTestDatabase);

  group('BookmarkRepository', () {
    test('add, list, remove, toggle', () async {
      final deps = await buildTestDeps();
      final repo = deps.bookmarkRepository;

      await repo.add(BookmarkType.question, 'q_ch1_001');
      await repo.add(BookmarkType.formula, 'f_ch1_001');
      expect((await repo.getAll()).length, 2);
      expect(await repo.isBookmarked(BookmarkType.question, 'q_ch1_001'), true);

      // Duplicate insert is idempotent (UNIQUE + IGNORE).
      await repo.add(BookmarkType.question, 'q_ch1_001');
      expect((await repo.getByType(BookmarkType.question)).length, 1);

      expect(await repo.toggle(BookmarkType.question, 'q_ch1_001'), false);
      expect(await repo.isBookmarked(BookmarkType.question, 'q_ch1_001'),
          false);
      expect(await repo.toggle(BookmarkType.topic, 'ch1_t1'), true);

      await deps.dbHelper.close();
    });
  });

  group('ResultsRepository', () {
    test('save result with attempts and aggregate performance', () async {
      final deps = await buildTestDeps();
      final repo = deps.resultsRepository;

      final result = QuizResult(
        mode: QuizMode.practice,
        chapterId: 'ch2',
        total: 3,
        correct: 2,
        incorrect: 1,
        unanswered: 0,
        timeSeconds: 45,
        takenAt: DateTime(2026, 9, 14, 10),
      );
      final attempts = [
        const QuestionAttempt(
            questionId: 'q_ch2_001', chapterId: 'ch2', topicId: 'ch2_t1',
            selectedIndex: 0, isCorrect: true, timeMs: 9000),
        const QuestionAttempt(
            questionId: 'q_ch2_002', chapterId: 'ch2', topicId: 'ch2_t1',
            selectedIndex: 2, isCorrect: false, timeMs: 20000),
        const QuestionAttempt(
            questionId: 'q_ch2_020', chapterId: 'ch2', topicId: 'ch2_t9',
            selectedIndex: 1, isCorrect: true, timeMs: 16000),
      ];
      final id = await repo.saveResult(result, attempts);
      expect(id, greaterThan(0));

      final latest = await repo.getLatestResult();
      expect(latest, isNotNull);
      expect(latest!.correct, 2);
      expect(latest.accuracy, closeTo(2 / 3, 0.001));

      final stored = await repo.getAttemptsForResult(id);
      expect(stored.length, 3);

      final perf = await repo.getTopicPerformance();
      final t1 = perf.singleWhere((p) => p.topicId == 'ch2_t1');
      expect(t1.attempted, 2);
      expect(t1.correct, 1);
      expect(t1.accuracy, 0.5);

      final chapterPerf = await repo.getChapterPerformance();
      expect(chapterPerf.single.chapterId, 'ch2');
      expect(chapterPerf.single.attempted, 3);

      expect(await repo.totalQuizCount(), 1);
      await deps.dbHelper.close();
    });
  });

  group('FlashcardRepository', () {
    test('due queue and review persistence', () async {
      final deps = await buildTestDeps();
      final repo = deps.flashcardRepository;
      final now = DateTime(2026, 9, 14);

      final due = await repo.getDueCards(now);
      final all = await repo.getAllCards();
      // Fresh install: every card is due immediately.
      expect(due.length, all.length);

      // Grade the first card 'easy' — it leaves the due queue.
      final first = due.first;
      final next = first.review.graded(ReviewGrade.easy, now);
      await repo.saveReview(next);
      final dueAfter = await repo.getDueCards(now);
      expect(dueAfter.length, all.length - 1);

      // The state survives a fresh repository over the same DB.
      final stored = await repo.getReview(first.card.id);
      expect(stored, isNotNull);
      expect(stored!.reviewCount, 1);
      expect(stored.dueDate.isAfter(now), true);

      await deps.dbHelper.close();
    });
  });

  group('ProgressRepository', () {
    test('topic progress and readiness', () async {
      final deps = await buildTestDeps();
      final repo = deps.progressRepository;

      expect((await repo.getAllTopicProgress()), isEmpty);

      await repo.recordTopicStudied('ch1_t1');
      await repo.setTopicCompleted('ch1_t2', true);

      final all = await repo.getAllTopicProgress();
      expect(all['ch1_t1']!.completionPct, 0.5);
      expect(all['ch1_t2']!.completed, true);
      expect(all['ch1_t2']!.completionPct, 1.0);

      final progress = await repo.getUserProgress(10);
      expect(progress.completedTopics, 1);
      expect(progress.readiness, closeTo(0.15, 0.001)); // (0.5+1.0)/10
      expect(progress.streak, 1); // studying bumped the streak today

      await deps.dbHelper.close();
    });
  });
}
