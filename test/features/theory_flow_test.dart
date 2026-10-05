import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  Future<void> openFirstChapter(WidgetTester tester) async {
    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Basic Electrical').first);
    await tester.pumpAndSettle();
  }

  testWidgets('chapter → topic → theory reader with tabs and blocks',
      (tester) async {
    await pumpApp(tester);
    await openFirstChapter(tester);

    // Topic list shows theory/practice tabs and topic cards with badges.
    expect(find.text('Theory'), findsOneWidget);
    expect(find.text('Practice'), findsWidgets);
    expect(find.textContaining('1.1 Basic Concepts'), findsOneWidget);
    await openBasicConceptsGroup(tester);
    expect(find.textContaining("Ohm's Law"), findsWidgets);

    await tester.tap(find.textContaining("1.1.1 Ohm's Law"));
    await tester.pumpAndSettle();

    // Reader: concepts tab renders headings, paragraphs, formula (LaTeX).
    expect(find.text('Concepts'), findsOneWidget);
    expect(find.textContaining('current flowing through a conductor'),
        findsOneWidget);
    expect(find.byType(Math), findsWidgets);

    // Formulas tab.
    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
    expect(find.byType(Math), findsWidgets);

    // Notes tab has exam tips.
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Exam Tip'), findsWidgets);

    // Bottom actions exist.
    expect(find.text('Formula Sheet'), findsOneWidget);
    expect(find.text('Practice MCQs'), findsOneWidget);

    // Back navigation returns to the subtopic list.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('1.1.2'), findsWidgets);
  });

  testWidgets('reading a topic records progress and completion persists',
      (tester) async {
    final deps = await pumpApp(tester);
    await openFirstChapter(tester);
    await openBasicConceptsGroup(tester);

    await tester.tap(find.textContaining("1.1.1 Ohm's Law"));
    await tester.pumpAndSettle();

    // Mark as complete.
    await tester.dragUntilVisible(find.text('Mark as Complete'),
        find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as Complete'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);

    // Persisted in the repository.
    final progress =
        await deps.progressRepository.getTopicProgress('ch1_t1');
    expect(progress!.completed, isTrue);

    // Streak was bumped by studying.
    expect(deps.prefs.streakCount, 1);
  });

  testWidgets('theory bookmark toggles and persists', (tester) async {
    final deps = await pumpApp(tester);
    await openFirstChapter(tester);
    await openBasicConceptsGroup(tester);
    await tester.tap(find.textContaining("1.1.1 Ohm's Law"));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    final bookmarks = await deps.bookmarkRepository.getAll();
    expect(bookmarks.single.itemId, 'ch1_t1');
  });

  testWidgets('practice tab lists topics with play affordance',
      (tester) async {
    await pumpApp(tester);
    await openFirstChapter(tester);

    await tester.tap(find.text('Practice').last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_outline), findsWidgets);
    expect(find.textContaining('MCQs'), findsWidgets);
  });
}
