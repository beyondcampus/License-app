import 'package:exam_prep_pro/core/constants/app_strings.dart';
import 'package:exam_prep_pro/core/services/content_source.dart';
import 'package:exam_prep_pro/core/widgets/badges.dart';
import 'package:exam_prep_pro/features/bookmarks/domain/bookmark.dart';
import 'package:exam_prep_pro/features/dashboard/presentation/dashboard_screen.dart';
import 'package:exam_prep_pro/features/flashcards/domain/flashcard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixture_content.dart';
import '../helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  group('malformed content rows never crash content loading', () {
    test('bad rows are skipped, valid rows are kept (Stage 11)', () async {
      final source = ContentSource(
        FixtureContentBackend({
          'chapters.json': [
            {'nonsense': 12},
          ],
          'topics.json': [
            {'oops': true},
          ],
          // One good entry among bad ones.
          'questions.json': [
            {'id': 'broken'},
            {'nonsense': 12},
            {
              'id': 'ok1',
              'chapterId': 'ch1',
              'topicId': 't1',
              'questionText': 'Valid?',
              'options': ['yes', 'no'],
              'correctIndex': 0,
              'explanation': 'yes',
              'difficulty': 'easy',
            },
            {
              'id': 'bad_index',
              'chapterId': 'ch1',
              'topicId': 't1',
              'questionText': 'Out of range index',
              'options': ['a', 'b'],
              'correctIndex': 7,
              'explanation': 'skipped',
            },
          ],
          // The other tables are empty.
        }),
      );

      expect(await source.chapters(), isEmpty);
      expect(await source.topics(), isEmpty);
      final questions = await source.questions();
      expect(questions.length, 1);
      expect(questions.single.id, 'ok1');
      expect(await source.theory(), isEmpty);
      expect(await source.formulas(), isEmpty);
      expect(await source.flashcards(), isEmpty);
    });
  });

  group('content comes only from Supabase', () {
    test('an unreachable backend is reported and retried, never replaced',
        () async {
      final backend = OfflineContentBackend(FixtureContentBackend.snapshot());
      final source = ContentSource(backend);

      await expectLater(
          source.chapters(), throwsA(isA<ContentUnavailableException>()));
      await expectLater(
          source.questions(), throwsA(isA<ContentUnavailableException>()));

      // The failure is not remembered: once online, the next call fetches.
      backend.online = true;
      expect(await source.chapters(), hasLength(10));
      expect(backend.requests, 3);
    });

    testWidgets('offline start shows a retryable error, then loads',
        (tester) async {
      final backend = OfflineContentBackend(FixtureContentBackend.snapshot());
      await pumpApp(tester, content: backend);

      Finder onDashboard(Finder finder) =>
          find.descendant(of: find.byType(DashboardScreen), matching: finder);
      expect(onDashboard(find.text(AppStrings.contentUnavailable)),
          findsOneWidget);
      expect(find.textContaining('Basic Electrical'), findsNothing);

      backend.online = true;
      await tester.tap(onDashboard(find.text(AppStrings.retry)));
      await tester.pumpAndSettle();

      expect(find.text('Select Subject Module'), findsOneWidget);
      expect(find.textContaining('Basic Electrical'), findsWidgets);
    });
  });

  testWidgets('app restart preserves progress, bookmarks and theme',
      (tester) async {
    final deps = await pumpApp(tester);

    // Make changes: bookmark, progress, theme.
    await deps.bookmarkRepository.add(BookmarkType.question, 'q_ch1_001');
    await deps.progressRepository.setTopicCompleted('ch1_t1', true);
    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();

    // Restart the app over the same storage.
    await restartApp(tester, deps);

    // Theme restored to light.
    final ctx = tester.element(find.text('Select Subject Module'));
    expect(Theme.of(ctx).brightness, Brightness.light);
    // Progress restored (streak from completing a topic today).
    expect(find.textContaining('🔥 1 Day'), findsOneWidget);
    // Bookmark still present.
    expect(
        await deps.bookmarkRepository
            .isBookmarked(BookmarkType.question, 'q_ch1_001'),
        isTrue);
  });

  testWidgets('timed quiz auto-finishes when the timer reaches zero',
      (tester) async {
    await pumpApp(tester, prefs: {'pref_quiz_length': 5});

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timed Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Basic Electrical').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Question 1 of 5'), findsOneWidget);
    expect(find.byType(TimerBadge), findsOneWidget);

    // 5 questions × 45s = 225s. Let the whole countdown elapse.
    await tester.pump(const Duration(seconds: 226));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Quiz Results'), findsOneWidget);
    expect(find.textContaining("Time's up"), findsOneWidget);
    expect(find.text('Unanswered'), findsOneWidget);
  });

  testWidgets('no flashcards due shows the caught-up state', (tester) async {
    final deps = await pumpApp(tester);

    // Push every card far into the future.
    final cards = await deps.flashcardRepository.getAllCards();
    final tomorrow = DateTime.now();
    for (final card in cards) {
      await deps.flashcardRepository.saveReview(
          FlashcardReview.fresh(card.id, tomorrow)
              .graded(ReviewGrade.easy, tomorrow));
    }

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    expect(find.text('All caught up!'), findsOneWidget);
  });

  testWidgets('bookmarks screen shows its empty state', (tester) async {
    await pumpApp(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tapQuickAction(tester, 'Bookmarks');
    expect(find.text('Nothing bookmarked yet'), findsOneWidget);
  });

  group('small viewport (320×568) renders without overflow', () {
    testWidgets('dashboard, chapters, theory and quiz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Chapters'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Basic Electrical').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await openBasicConceptsGroup(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining("1.1.1 Ohm's Law"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Quiz screen on a small viewport.
      await tester.tap(find.text('Practice MCQs'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Question 1 of'), findsOneWidget);
    });
  });
}
