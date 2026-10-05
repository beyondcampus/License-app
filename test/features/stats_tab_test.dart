import 'package:exam_prep_pro/features/quiz/domain/quiz_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  testWidgets('stats tab shows empty state before any quiz', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Take your first quiz'), findsOneWidget);
  });

  testWidgets('stats tab shows score, chart, weak topics and recommendations',
      (tester) async {
    final deps = await pumpApp(tester);

    // Seed history: weak K-Maps performance (1/5).
    final attempts = [
      for (var i = 0; i < 5; i++)
        QuestionAttempt(
          questionId: 'seed_$i',
          chapterId: 'ch2',
          topicId: 'ch2_i14',
          selectedIndex: i == 0 ? 0 : 1,
          isCorrect: i == 0,
          timeMs: 12000,
        ),
    ];
    await deps.resultsRepository.saveResult(
      QuizResult(
        mode: QuizMode.timed,
        chapterId: 'ch2',
        total: 5,
        correct: 1,
        incorrect: 4,
        unanswered: 0,
        timeSeconds: 120,
        takenAt: DateTime(2026, 9, 15),
      ),
      attempts,
    );

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.textContaining('Accuracy Rate'), findsOneWidget);
    expect(find.text('Accuracy by Chapter'), findsOneWidget);
    expect(find.text('Chap 2'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Topics to Review'),
        find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.textContaining('Karnaugh Maps'), findsWidgets);

    await tester.dragUntilVisible(
        find.textContaining('Focus on Karnaugh Maps'),
        find.byType(ListView),
        const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.textContaining('Focus on Karnaugh Maps'), findsOneWidget);
  });
}
