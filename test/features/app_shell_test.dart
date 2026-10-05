import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  testWidgets('bottom navigation switches between all five tabs',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Select Subject Module'), findsOneWidget);

    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Results & Analytics'), findsOneWidget);

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    expect(find.text('Flashcards'), findsWidgets);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Select Subject Module'), findsOneWidget);
  });

  testWidgets('dashboard shows the real subject modules with stats',
      (tester) async {
    final deps = await pumpApp(tester);

    expect(find.textContaining('Basic Electrical'), findsOneWidget);
    expect(find.textContaining('Digital Logic'), findsOneWidget);
    expect(find.textContaining('C & C++'), findsOneWidget);
    expect(find.textContaining('🔥'), findsOneWidget);
    // Meta line derived from real content counts: a chapter card counts the
    // top-level topics its chapter screen lists (7 once Chapter 1 has parents).
    final topLevel = await tester.runAsync(() async =>
        (await deps.contentSource.topics(chapterId: 'ch1'))
            .where((t) => t.parentTopicId == null)
            .length);
    expect(find.textContaining(RegExp('^$topLevel Topics')), findsWidgets);
  });

  testWidgets('theme toggle flips brightness and persists', (tester) async {
    await pumpApp(tester);

    BuildContext ctx = tester.element(find.text('Select Subject Module'));
    expect(Theme.of(ctx).brightness, Brightness.dark);

    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();

    ctx = tester.element(find.text('Select Subject Module'));
    expect(Theme.of(ctx).brightness, Brightness.light);

    final stored = await SharedPreferences.getInstance();
    expect(stored.getString('pref_theme_mode'), 'light');
  });

  testWidgets('quick actions navigate to their tabs', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(find.text('Practice Center'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Practice Center'));
    await tester.pumpAndSettle();
    expect(find.text('Practice'), findsWidgets);
  });
}
