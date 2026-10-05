import 'package:exam_prep_pro/core/services/app_dependencies.dart';
import 'package:exam_prep_pro/features/chapters/state/chapter_provider.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_config.dart';
import 'package:exam_prep_pro/features/quiz/state/quiz_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_deps.dart';

/// Topic practice continues where the user left off: questions whose latest
/// Practice answer is correct are skipped; wrong and unanswered ones stay, in
/// their normal order. Only Practice answers count.
void main() {
  setUpAll(setUpTestDatabase);

  late AppDependencies deps;
  setUp(() async => deps = await buildTestDeps());
  tearDown(() => deps.dbHelper.close());

  QuizProvider quiz(QuizConfig config) {
    final provider = QuizProvider(
      config: config,
      questions: deps.questionRepository,
      bookmarks: deps.bookmarkRepository,
      results: deps.resultsRepository,
      practice: deps.practiceProgressRepository,
    );
    addTearDown(provider.dispose);
    return provider;
  }

  Future<QuizConfig> ohmsLawPractice() async =>
      QuizConfig.topicPractice((await deps.chapterRepository.getTopic('ch1_t1'))!);

  test('answers are saved as they are given; correct ones are skipped next time',
      () async {
    final config = await ohmsLawPractice();
    final all = await deps.questionRepository.getByTopic('ch1_t1');
    expect(all.length, greaterThan(3));

    // Day 1: Q1 right, Q2 wrong, then leave without finishing.
    final day1 = quiz(config);
    await day1.load();
    expect(day1.skippedCorrect, 0);
    await day1.selectOption(all[0].correctIndex);
    await day1.next();
    await day1.selectOption((all[1].correctIndex + 1) % all[1].options.length);

    // Day 2: Q1 is gone; Q2 (wrong) comes first, the rest follow in order.
    final day2 = quiz(config);
    await day2.load();
    expect(day2.state, QuizState.ready);
    expect(day2.skippedCorrect, 1);
    expect(day2.session!.questions.map((q) => q.id),
        all.skip(1).map((q) => q.id));
  });

  test('a later wrong answer brings a question back', () async {
    final config = await ohmsLawPractice();
    final q = (await deps.questionRepository.getByTopic('ch1_t1')).first;
    await deps.practiceProgressRepository.record(q.id, isCorrect: true);
    await deps.practiceProgressRepository.record(q.id, isCorrect: false);

    final provider = quiz(config);
    await provider.load();
    expect(provider.skippedCorrect, 0);
    expect(provider.session!.questions.first.id, q.id);
  });

  test('all correct: nothing left, then "Practice all again" runs everything',
      () async {
    final config = await ohmsLawPractice();
    final all = await deps.questionRepository.getByTopic('ch1_t1');
    for (final q in all) {
      await deps.practiceProgressRepository.record(q.id, isCorrect: true);
    }

    final provider = quiz(config);
    await provider.load();
    expect(provider.state, QuizState.allCorrect);
    expect(provider.skippedCorrect, all.length);

    await provider.practiceAll();
    expect(provider.state, QuizState.ready);
    expect(provider.session!.total, all.length);
  });

  test('a topic group runs its subtopics in order and skips correct answers',
      () async {
    final chapters = ChapterProvider(deps.chapterRepository,
        deps.progressRepository, deps.practiceProgressRepository);
    await chapters.load();
    final group = chapters
        .topLevelTopics('ch1')
        .firstWhere(chapters.hasSubtopics);
    final subtopics = chapters.subtopicsOf(group);
    final expected = [
      for (final t in subtopics)
        ...await deps.questionRepository.getByTopic(t.id),
    ];
    await deps.practiceProgressRepository
        .record(expected.first.id, isCorrect: true);

    final provider = quiz(QuizConfig.subtopicsPractice(group, subtopics));
    await provider.load();
    expect(provider.session!.questions.map((q) => q.id),
        expected.skip(1).map((q) => q.id));

    // The card counts what is left.
    await chapters.refreshProgress();
    expect(chapters.practiceCorrectFor(group), 1);
    expect(chapters.questionCountFor(group), expected.length);
  });

  test('only Practice answers are recorded', () async {
    final chapter = (await deps.chapterRepository.getChapters()).first;
    final timed = quiz(QuizConfig.timedTest(chapter, 5));
    await timed.load();
    await timed.selectOption(timed.session!.current.correctIndex);
    expect(await deps.practiceProgressRepository.correctQuestionIds(), isEmpty);
  });

  group('exam modes come in a random order every time', () {
    test('Timed Test', () async {
      final chapter = (await deps.chapterRepository.getChapters()).first;
      final a = quiz(QuizConfig.timedTest(chapter, 20));
      final b = quiz(QuizConfig.timedTest(chapter, 20));
      await a.load();
      await b.load();
      expect(a.session!.questions.map((q) => q.id),
          isNot(b.session!.questions.map((q) => q.id)));
    });

    test('Mock Exam', () async {
      final a = await deps.questionRepository.getMockSample(20);
      final b = await deps.questionRepository.getMockSample(20);
      expect(a.map((q) => q.id), isNot(b.map((q) => q.id)));
    });

    test('Full Exam mixes the chapters', () async {
      final a = (await deps.questionRepository.getFullExamPaper()).questions;
      final b = (await deps.questionRepository.getFullExamPaper()).questions;
      expect(a.map((q) => q.id), isNot(b.map((q) => q.id)));
      // Not chapter 1 first, chapter 2 next, …
      final chapterOrder = a.map((q) => q.chapterId).toList();
      expect(chapterOrder.take(10).toSet().length, greaterThan(1));
    });
  });
}
