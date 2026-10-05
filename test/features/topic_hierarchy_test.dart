import 'package:exam_prep_pro/core/services/app_dependencies.dart';
import 'package:exam_prep_pro/core/services/prefs_service.dart';
import 'package:exam_prep_pro/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixture_content.dart';
import '../helpers/test_deps.dart';

Map<String, Object> _topic(String id, String title, int order,
        {String? parent}) =>
    {
      'id': id,
      'chapterId': 'ch1',
      'title': title,
      'subtitle': '',
      'order': order,
      'hasFormulas': false,
      'hasNotes': false,
      'parentTopicId': ?parent,
    };

Map<String, Object> _theory(String topicId, String heading) => {
      'topicId': topicId,
      'concepts': [
        {'type': 'heading', 'text': heading},
        {'type': 'paragraph', 'text': 'Body text for $heading.'},
      ],
      'formulas': <Object>[],
      'notes': <Object>[],
    };

Map<String, Object> _question(String id, String topicId) => {
      'id': id,
      'chapterId': 'ch1',
      'topicId': topicId,
      'questionText': 'Question $id?',
      'options': ['A', 'B', 'C', 'D'],
      'correctIndex': 0,
      'explanation': 'Because.',
      'difficulty': 'easy',
    };

/// One chapter with a parent topic (two subtopics) and one plain leaf topic,
/// mirroring the Chapter 1 structure after the Supabase migration.
final _content = FixtureContentBackend({
  'chapters.json': [
    {
      'id': 'ch1',
      'title': 'Basic Electrical & EDC',
      'description': 'Test chapter',
      'emoji': '⚡',
      'order': 1,
    },
  ],
  'topics.json': [
    _topic('ch1_p1', 'Basic Concepts', 1),
    _topic('ch1_t1', "Ohm's Law & Basic Concepts", 1, parent: 'ch1_p1'),
    _topic('ch1_i11', 'Electric Voltage, Current, Power & Energy', 2,
        parent: 'ch1_p1'),
    _topic('ch1_t9', 'Semiconductor Diodes', 2),
  ],
  'theory.json': [
    _theory('ch1_t1', "Ohm's Law"),
    _theory('ch1_i11', 'Voltage and Current'),
    _theory('ch1_t9', 'The P-N Junction'),
  ],
  'questions.json': [
    _question('q1', 'ch1_t1'),
    _question('q2', 'ch1_t1'),
    _question('q3', 'ch1_i11'),
    _question('q4', 'ch1_t9'),
  ],
  'formulas.json': <Object>[],
  'flashcards.json': <Object>[],
});

Future<AppDependencies> _pumpHierarchyApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final deps = AppDependencies(
    prefs: await PrefsService.init(),
    dbPath: inMemoryDatabasePath,
    contentBackend: _content,
  );
  addTearDown(deps.dbHelper.close);
  await tester.pumpWidget(ExamPrepApp(deps: deps));
  await tester.pumpAndSettle();
  return deps;
}

Future<void> _openChapter(WidgetTester tester) async {
  await tester.tap(find.text('Chapters'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Basic Electrical').first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(setUpTestDatabase);

  testWidgets('chapter lists only top-level topics; a group shows its size',
      (tester) async {
    await _pumpHierarchyApp(tester);

    // Chapter card counts what the chapter screen lists: 2 top-level topics.
    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 Topics'), findsWidgets);
    expect(find.textContaining('4 MCQs'), findsWidgets);

    await tester.tap(find.textContaining('Basic Electrical').first);
    await tester.pumpAndSettle();

    expect(find.text('1.1 Basic Concepts'), findsOneWidget);
    expect(find.text('1.2 Semiconductor Diodes'), findsOneWidget);
    // Subtopics are not shown at this level.
    expect(find.textContaining("Ohm's Law"), findsNothing);
    // Group badges: subtopic count and summed question count.
    expect(find.text('2 Subtopics'), findsOneWidget);
    expect(find.text('3 MCQs'), findsOneWidget);
    expect(find.text('1 MCQs'), findsOneWidget);
  });

  testWidgets('tapping a group opens its subtopics, numbered 1.x.y',
      (tester) async {
    await _pumpHierarchyApp(tester);
    await _openChapter(tester);

    await tester.tap(find.text('1.1 Basic Concepts'));
    await tester.pumpAndSettle();

    expect(find.text('Basic Concepts'), findsOneWidget); // app bar
    expect(find.textContaining("1.1.1 Ohm's Law"), findsOneWidget);
    expect(find.textContaining('1.1.2 Electric Voltage'), findsOneWidget);
    expect(find.text('2 MCQs'), findsOneWidget);
    expect(find.text('1 MCQs'), findsOneWidget);

    // A leaf opens the theory reader.
    await tester.tap(find.textContaining("1.1.1 Ohm's Law"));
    await tester.pumpAndSettle();
    expect(find.text("Ohm's Law"), findsWidgets);
    expect(find.textContaining("Body text for Ohm's Law"), findsOneWidget);

    // Back returns to the subtopic list, and back again to the chapter.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('1.1.2 Electric Voltage'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1.1 Basic Concepts'), findsOneWidget);
  });

  testWidgets('a leaf topic at the top level still opens the reader directly',
      (tester) async {
    await _pumpHierarchyApp(tester);
    await _openChapter(tester);

    await tester.tap(find.text('1.2 Semiconductor Diodes'));
    await tester.pumpAndSettle();
    expect(find.text('The P-N Junction'), findsWidgets);
  });

  testWidgets('practising a group runs a quiz over all its subtopics',
      (tester) async {
    await _pumpHierarchyApp(tester);
    await _openChapter(tester);

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 MCQs'), findsOneWidget);

    await tester.tap(find.text('1.1 Basic Concepts'));
    await tester.pumpAndSettle();
    // 2 questions from ch1_t1 + 1 from ch1_i11.
    expect(find.textContaining('Question 1 of 3'), findsOneWidget);
  });

  testWidgets('group progress averages its subtopics and counts leaves only',
      (tester) async {
    final deps = await _pumpHierarchyApp(tester);

    // Complete one of the two subtopics directly in the repository.
    await deps.progressRepository.setTopicCompleted('ch1_t1', true);
    await _openChapter(tester);
    // Force a progress refresh, as the reader does on return.
    await tester.tap(find.text('1.1 Basic Concepts'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The group is not "Completed" until every subtopic is.
    expect(find.text('Completed'), findsNothing);

    await tester.tap(find.text('1.1 Basic Concepts'));
    await tester.pumpAndSettle();
    await deps.progressRepository.setTopicCompleted('ch1_i11', true);
    await tester.tap(find.textContaining('1.1.2 Electric Voltage'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
  });
}
