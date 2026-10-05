import 'package:exam_prep_pro/core/services/content_source.dart';
import 'package:exam_prep_pro/features/bookmarks/domain/bookmark.dart';
import 'package:exam_prep_pro/features/search/state/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixture_content.dart';
import '../helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  group('SearchProvider (unit)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final source = ContentSource(FixtureContentBackend.snapshot());

    test('finds matches across content types, case-insensitively', () async {
      final provider = SearchProvider(source);
      await provider.search('THEVENIN');
      expect(provider.results.isEmpty, isFalse);
      // Topic subtitle mentions Thevenin's.
      expect(provider.results.topics.any((t) => t.id == 'ch1_t2'), isTrue);

      await provider.search('pointer');
      expect(provider.results.topics.any((t) => t.id == 'ch3_t2'), isTrue);
      expect(provider.results.formulas, isNotEmpty);
      expect(provider.results.questions, isNotEmpty);
    });

    test('theory-only matches roll up into their topic', () async {
      final provider = SearchProvider(source);
      // "race-around" appears in ch2_t6 theory and subtitle... use a
      // phrase only present in theory body text:
      await provider.search('acceptor circuit');
      expect(provider.results.topics.any((t) => t.id == 'ch1_i26'), isTrue);
    });

    test('empty and no-match queries', () async {
      final provider = SearchProvider(source);
      await provider.search('   ');
      expect(provider.results.isEmpty, isTrue);
      await provider.search('zzzz-not-in-content-zzzz');
      expect(provider.results.isEmpty, isTrue);
    });
  });

  testWidgets('formula sheet: chapter tabs, search filter and bookmarking',
      (tester) async {
    final deps = await pumpApp(tester);

    // Open from dashboard quick action (drag past the bottom nav overlap).
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tapQuickAction(tester, 'Formula Sheet');

    expect(find.text('Formula Cheatsheet'), findsOneWidget);
    // Chapter 1 formulas are listed by id; the first visible one is from ch1_i11.
    expect(find.text('Current from charge flow'), findsOneWidget);

    // Chapter 2 tab filters to digital content.
    await tester.tap(find.text('Chapter 2'));
    await tester.pumpAndSettle();
    expect(find.text('Current from charge flow'), findsNothing);
    expect(find.textContaining('XOR definition'), findsOneWidget);

    // Search narrows within the tab.
    await tester.enterText(
        find.widgetWithText(TextField, 'Search formulas...'), 'de morgan');
    await tester.pumpAndSettle();
    // Both the topic row and the revision sheet carry a De Morgan formula.
    expect(find.textContaining("De Morgan's theorems"), findsWidgets);
    expect(find.textContaining('XOR definition'), findsNothing);

    // Bookmark it.
    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(
        await deps.bookmarkRepository
            .isBookmarked(BookmarkType.formula, 'f_ch2_i12_01'),
        isTrue);

    // No-results state.
    await tester.enterText(
        find.widgetWithText(TextField, 'de morgan'), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);
  });

  testWidgets('bookmarks screen groups and removes saved items',
      (tester) async {
    final deps = await pumpApp(tester);
    await deps.bookmarkRepository.add(BookmarkType.question, 'q_ch2_020');
    await deps.bookmarkRepository.add(BookmarkType.formula, 'f_ch1_i26_01');
    await deps.bookmarkRepository.add(BookmarkType.topic, 'ch3_t2');

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tapQuickAction(tester, 'Bookmarks');

    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Formulas'), findsOneWidget);
    expect(find.textContaining('Pointers'), findsWidgets);
    expect(find.textContaining('CS = 2000H'), findsOneWidget);
    expect(find.textContaining('Resonant frequency'), findsOneWidget);

    // Remove the question bookmark.
    await tester.tap(find.byIcon(Icons.delete_outline).at(1));
    await tester.pumpAndSettle();
    expect(
        await deps.bookmarkRepository
            .isBookmarked(BookmarkType.question, 'q_ch2_020'),
        isFalse);
  });

  testWidgets('search screen navigates to a topic result', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tapQuickAction(tester, 'Search');

    await tester.enterText(find.byType(TextField), 'karnaugh');
    await tester.pumpAndSettle();
    expect(find.text('Topics & Theory'), findsOneWidget);

    await tester.tap(find.text('Karnaugh Maps').first);
    await tester.pumpAndSettle();
    // Landed in the theory reader for that topic.
    expect(find.text('Concepts'), findsOneWidget);
    expect(find.text('Practice MCQs'), findsOneWidget);
  });

  testWidgets('bookmarked questions become a playable quiz', (tester) async {
    final deps = await pumpApp(tester);
    await deps.bookmarkRepository.add(BookmarkType.question, 'q_ch1_001');
    await deps.bookmarkRepository.add(BookmarkType.question, 'q_ch1_003');

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Bookmarked Questions'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Bookmarked Questions'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Question 1 of 2'), findsOneWidget);

    // Clean exit.
    await tester.pageBack();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Exit'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
