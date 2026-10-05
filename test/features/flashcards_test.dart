import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  testWidgets('cards tab shows the due queue with flip and grading',
      (tester) async {
    final deps = await pumpApp(tester);
    final initialDue = await deps.flashcardRepository.getDueCards(DateTime.now());
    final dueCount = initialDue.length;
    final firstCard = initialDue.first.card;

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    // All cards are due on first launch.
    expect(find.text('1 / $dueCount'), findsOneWidget);
    expect(find.text('Tap to Reveal Answer'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    // Interval preview sublabels.
    expect(find.text('(1 day)'), findsOneWidget);
    expect(find.text('(3 days)'), findsOneWidget);

    // Flip reveals the answer.
    final frontText = firstCard.front;
    expect(find.text(frontText), findsOneWidget);
    await tester.tap(find.text(frontText));
    await tester.pumpAndSettle();
    expect(find.textContaining(firstCard.back.substring(0, 12)), findsOneWidget);
    expect(find.text('Tap to Flip Back'), findsOneWidget);

    // Grading advances to the next card and persists the review.
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
    expect(find.text('2 / $dueCount'), findsOneWidget);
    expect(find.text(frontText), findsNothing);

    final review = await deps.flashcardRepository.getReview(firstCard.id);
    expect(review, isNotNull);
    expect(review!.reviewCount, 1);
    expect(review.intervalDays, greaterThanOrEqualTo(4));

    // Reviewed card is no longer due today.
    final due = await deps.flashcardRepository.getDueCards(DateTime.now());
    expect(due.length, dueCount - 1);
  });

  testWidgets('grading a hard card keeps it due tomorrow, not today',
      (tester) async {
    final deps = await pumpApp(tester);
    final initialDue = await deps.flashcardRepository.getDueCards(DateTime.now());
    final firstCard = initialDue.first.card;
    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();

    final review = await deps.flashcardRepository.getReview(firstCard.id);
    expect(review!.intervalDays, 1);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dueTomorrow =
        await deps.flashcardRepository.getDueCards(tomorrow);
    expect(dueTomorrow.any((d) => d.card.id == firstCard.id), isTrue);
  });
}
