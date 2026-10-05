import 'package:exam_prep_pro/features/analytics/state/analytics_provider.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_deps.dart';

QuestionAttempt _attempt(String topicId, bool correct, {int i = 0}) =>
    QuestionAttempt(
      questionId: 'q_${topicId}_$i',
      chapterId: topicId.split('_').first,
      topicId: topicId,
      selectedIndex: correct ? 0 : 1,
      isCorrect: correct,
      timeMs: 10000,
    );

Future<void> _seed(dynamic repo, String topicId,
    {required int correct, required int wrong}) async {
  final attempts = <QuestionAttempt>[
    for (var i = 0; i < correct; i++) _attempt(topicId, true, i: i),
    for (var i = 0; i < wrong; i++) _attempt(topicId, false, i: 100 + i),
  ];
  final result = QuizResult(
    mode: QuizMode.practice,
    chapterId: topicId.split('_').first,
    total: attempts.length,
    correct: correct,
    incorrect: wrong,
    unanswered: 0,
    timeSeconds: 60,
    takenAt: DateTime(2026, 9, 14),
  );
  await repo.saveResult(result, attempts);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpTestDatabase);

  test('no history → no recommendations, hasHistory false', () async {
    final deps = await buildTestDeps();
    final provider =
        AnalyticsProvider(deps.resultsRepository, deps.chapterRepository);
    await provider.load();
    expect(provider.hasHistory, isFalse);
    expect(provider.recommendations, isEmpty);
    expect(provider.weakTopics, isEmpty);
    await deps.dbHelper.close();
  });

  test('weak topics detected below 60% with ≥4 attempts, named in recs',
      () async {
    final deps = await buildTestDeps();
    // K-Maps (ch2_i14): 1/5 → weak. Boolean algebra (ch2_i12): 5/6 → strong.
    // Pointers (ch3_t7): 1/2 → below 60% but under min attempts → ignored.
    await _seed(deps.resultsRepository, 'ch2_i14', correct: 1, wrong: 4);
    await _seed(deps.resultsRepository, 'ch2_i12', correct: 5, wrong: 1);
    await _seed(deps.resultsRepository, 'ch3_t7', correct: 1, wrong: 1);

    final provider =
        AnalyticsProvider(deps.resultsRepository, deps.chapterRepository);
    await provider.load();

    expect(provider.hasHistory, isTrue);
    expect(provider.totalQuizzes, 3);
    expect(provider.weakTopics.length, 1);
    expect(provider.weakTopics.single.topicTitle, 'Karnaugh Maps');
    expect(provider.weakTopics.single.accuracy, closeTo(0.2, 0.001));

    // Recommendations are generated from the data, not hardcoded.
    expect(provider.recommendations.first, contains('Karnaugh Maps'));
    expect(
        provider.recommendations.any((r) => r.contains('20%')), isTrue);

    // Chapter accuracy computed per chapter.
    final ch2 = provider.chapterAccuracy
        .singleWhere((c) => c.chapterId == 'ch2');
    expect(ch2.attempted, 11);
    expect(ch2.accuracy, closeTo(6 / 11, 0.001));
    final ch1 = provider.chapterAccuracy
        .singleWhere((c) => c.chapterId == 'ch1');
    expect(ch1.attempted, 0);

    await deps.dbHelper.close();
  });

  test('all strong topics → positive recommendation', () async {
    final deps = await buildTestDeps();
    await _seed(deps.resultsRepository, 'ch1_t1', correct: 6, wrong: 0);

    final provider =
        AnalyticsProvider(deps.resultsRepository, deps.chapterRepository);
    await provider.load();

    expect(provider.weakTopics, isEmpty);
    expect(provider.recommendations.single, contains('Great work'));
    await deps.dbHelper.close();
  });

  test('insufficient attempts → keep-practicing recommendation', () async {
    final deps = await buildTestDeps();
    await _seed(deps.resultsRepository, 'ch1_t1', correct: 1, wrong: 1);

    final provider =
        AnalyticsProvider(deps.resultsRepository, deps.chapterRepository);
    await provider.load();

    expect(provider.weakTopics, isEmpty);
    expect(provider.recommendations.single, contains('Keep practicing'));
    await deps.dbHelper.close();
  });
}
