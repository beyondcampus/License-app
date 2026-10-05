import 'package:exam_prep_pro/core/widgets/badges.dart';
import 'package:exam_prep_pro/core/widgets/option_button.dart';
import 'package:exam_prep_pro/features/quiz/state/quiz_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/test_deps.dart';

/// The quiz screen has a live 1-second timer, so pumpAndSettle would never
/// settle. These bounded pumps advance the fake clock instead.
Future<void> pumpFrames(WidgetTester tester,
    [Duration total = const Duration(milliseconds: 600)]) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> startTopicQuiz(WidgetTester tester) async {
  await tester.tap(find.text('Chapters'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Basic Electrical').first);
  await tester.pumpAndSettle();
  await openBasicConceptsGroup(tester);
  await tester.tap(find.text('Practice').last); // subtopic list Practice tab
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining("1.1.1 Ohm's Law"));
  await pumpFrames(tester);
}

void main() {
  setUpAll(setUpTestDatabase);

  testWidgets('full practice quiz: feedback, locking, finish → results',
      (tester) async {
    final deps = await pumpApp(tester);
    await startTopicQuiz(tester);
    final topicQuestions = await deps.questionRepository.getByTopic('ch1_t1');

    // Quiz screen with counter; practice has no timer.
    expect(find.textContaining('Question 1 of'), findsOneWidget);
    expect(find.text('Single Choice'), findsOneWidget);
    expect(find.byType(TimerBadge), findsNothing);

    // Q1: "A 12 V battery..." — correct answer is A (4 Ω).
    await tester.tap(find.textContaining('A. 4'));
    await pumpFrames(tester);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget);

    // Locked: tapping another option must not change the selection.
    await tester.tap(find.textContaining('B. 36'), warnIfMissed: false);
    await pumpFrames(tester);
    expect(find.byIcon(Icons.cancel), findsNothing);

    // Q2: answer incorrectly (correct is C "Four times").
    await tester.tap(find.text('Next Question'));
    await pumpFrames(tester);
    expect(find.textContaining('Question 2 of'), findsOneWidget);
    await tester.tap(find.textContaining('A. Double'));
    await pumpFrames(tester);
    // Incorrect selection marked AND correct answer revealed.
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.textContaining('Wrong — correct answer: C. Four'),
        findsOneWidget);

    // Q3: answer correctly (correct is C "Four times").
    await tester.tap(find.text('Next Question'));
    await pumpFrames(tester);
    await tester.tap(find.textContaining('C. Four'));
    await pumpFrames(tester);

    // Finish → results screen.
    var expectedCorrect = 2;
    if (topicQuestions.length > 3) {
      await tester.tap(find.text('Next Question'));
      await pumpFrames(tester);

      for (var i = 3; i < topicQuestions.length; i++) {
        // Tap option A itself: stems and explanations can also contain "A. ",
        // and long stems can push the options below the fold.
        final optionA = find.byType(OptionButton).first;
        await tester.ensureVisible(optionA);
        await tester.tap(optionA);
        await pumpFrames(tester);
        if (topicQuestions[i].correctIndex == 0) {
          expectedCorrect++;
        }

        if (i == topicQuestions.length - 1) {
          await tester.tap(find.text('Finish Quiz'));
        } else {
          await tester.tap(find.text('Next Question'));
        }
        await pumpFrames(tester);
      }
    } else {
      await tester.tap(find.text('Finish Quiz'));
    }
    await pumpFrames(tester, const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Quiz Results'), findsOneWidget);
    expect(
        find.text('$expectedCorrect / ${topicQuestions.length}'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);

    // Result persisted.
    final saved = await deps.resultsRepository.getLatestResult();
    expect(saved, isNotNull);
    expect(saved!.correct, expectedCorrect);
    expect(saved.incorrect, topicQuestions.length - expectedCorrect);
    expect(saved.total, topicQuestions.length);
  });

  testWidgets('bookmarking a question persists from the quiz screen',
      (tester) async {
    final deps = await pumpApp(tester);
    await startTopicQuiz(tester);

    await tester.tap(find.text('Bookmark'));
    await pumpFrames(tester);
    expect(find.text('Bookmarked'), findsOneWidget);

    final bookmarks = await deps.bookmarkRepository.getAll();
    expect(bookmarks.single.itemId, 'q_ch1_001');
  });

  testWidgets('exit confirmation intercepts back during a quiz',
      (tester) async {
    await pumpApp(tester);
    await startTopicQuiz(tester);

    await tester.pageBack();
    await pumpFrames(tester);
    expect(find.text('Exit Quiz?'), findsOneWidget);

    // Cancel keeps the quiz open.
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester);
    expect(find.textContaining('Question 1 of'), findsOneWidget);

    // Exit leaves the quiz.
    await tester.pageBack();
    await pumpFrames(tester);
    await tester.tap(find.text('Exit'));
    await pumpFrames(tester, const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Question 1 of'), findsNothing);
  });

  testWidgets('mock exam from practice tab runs without a timer',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mock Exam'));
    await pumpFrames(tester);
    expect(find.textContaining('Question 1 of 20'), findsOneWidget);

    // Deferred feedback: selecting shows no explanation and stays changeable.
    final firstOption = find.textContaining('A. ').first;
    await tester.tap(firstOption);
    await pumpFrames(tester);
    expect(find.text('Explanation'), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    // No countdown and no clock in the app bar.
    final ctx = tester.element(find.text('Single Choice'));
    final qp = Provider.of<QuizProvider>(ctx, listen: false);
    expect(qp.isTimed, isFalse);
    expect(find.byType(TimerBadge), findsNothing);

    // Leave the quiz to stop the timer cleanly.
    await tester.pageBack();
    await pumpFrames(tester);
    await tester.tap(find.text('Exit'));
    await pumpFrames(tester, const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('bookmarked mode with no bookmarks shows empty state',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Bookmarked Questions'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Bookmarked Questions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bookmark questions, formulas'),
        findsOneWidget);
  });

  testWidgets('practice card counts what is left; the quiz skips correct ones',
      (tester) async {
    final deps = await pumpApp(tester);
    final ohm = await deps.questionRepository.getByTopic('ch1_t1');
    await deps.practiceProgressRepository
        .record(ohm.first.id, isCorrect: true);
    await restartApp(tester, deps);

    await startTopicQuiz(tester);
    expect(find.textContaining('Question 1 of ${ohm.length - 1}'),
        findsOneWidget);
    expect(find.textContaining('answered correctly before'), findsNothing);

    // Back on the subtopic list, the practice card shows what is left.
    await tester.pageBack();
    await pumpFrames(tester);
    await tester.tap(find.text('Exit'));
    await pumpFrames(tester, const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('${ohm.length - 1} left of ${ohm.length} MCQs'),
        findsOneWidget);
  });
}
