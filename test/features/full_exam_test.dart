import 'dart:math';

import 'package:exam_prep_pro/core/services/content_source.dart';
import 'package:exam_prep_pro/features/quiz/domain/full_exam_paper.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_config.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_result.dart';
import 'package:exam_prep_pro/features/quiz/domain/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixture_content.dart';

/// The full exam is 100 one-mark MCQs, 10 per chapter. Within a chapter
/// every syllabus section contributes at least one question and no section
/// more than two.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = ContentSource(FixtureContentBackend.snapshot());

  Future<FullExamPaper> build(int seed) async => FullExamPaper.build(
        chapters: await source.chapters(),
        topics: await source.topics(),
        questions: await source.questions(),
        random: Random(seed),
      );

  test('paper has 100 distinct questions, 10 per chapter, 100 marks', () async {
    final paper = await build(1);
    expect(paper.questions.length, 100);
    expect(paper.totalMarks, 100);
    expect(paper.questions.map((q) => q.id).toSet().length, 100,
        reason: 'no question appears twice');
    final perChapter = <String, int>{};
    for (final q in paper.questions) {
      perChapter[q.chapterId] = (perChapter[q.chapterId] ?? 0) + 1;
    }
    expect(perChapter.length, 10);
    expect(perChapter.values.every((n) => n == 10), isTrue);
  });

  test('every section is covered once or twice; revision topic is skipped',
      () async {
    final topics = await source.topics();
    final parentOf = {for (final t in topics) t.id: t.parentTopicId ?? t.id};
    final revisionIds = topics
        .where((t) => t.title.toLowerCase().startsWith('quick revision'))
        .map((t) => t.id)
        .toSet();

    for (final seed in [3, 7, 11]) {
      final paper = await build(seed);
      final perSection = <String, int>{};
      for (final q in paper.questions) {
        final section = parentOf[q.topicId]!;
        perSection[section] = (perSection[section] ?? 0) + 1;
      }
      expect(perSection.keys.where(revisionIds.contains), isEmpty);
      expect(perSection.length, 60, reason: 'all 10 × 6 sections appear');
      expect(perSection.values.every((n) => n == 1 || n == 2), isTrue);
    }
  });

  test('scoring gives one mark per correct answer', () async {
    final paper = await build(5);
    final session = QuizSession(
      questions: paper.questions,
      mode: QuizMode.fullExam,
    );
    session.selectOption(paper.questions[0].correctIndex);
    session.goTo(1);
    session.selectOption((paper.questions[1].correctIndex + 1) % 4);
    session.goTo(99);
    session.selectOption(paper.questions[99].correctIndex);
    final outcome = session.finish(elapsedSeconds: 10);
    expect(outcome.maxMarks, 100);
    expect(outcome.marksScored, 2);
    expect(outcome.result.correct, 2);
    expect(outcome.result.incorrect, 1);
    expect(outcome.result.unanswered, 97);
  });

  test('each answer is marked at once and cannot be changed', () async {
    final paper = await build(6);
    final session = QuizSession(
      questions: paper.questions,
      mode: QuizMode.fullExam,
    );
    expect(session.immediateFeedback, isTrue);
    final wrong = (paper.questions[0].correctIndex + 1) % 4;
    expect(session.selectOption(wrong), isTrue);
    expect(session.isCurrentLocked, isTrue);
    expect(session.isCurrentCorrect, isFalse);
    // Seeing the correct answer must not allow switching to it.
    expect(session.selectOption(paper.questions[0].correctIndex), isFalse);
    expect(session.currentSelection, wrong);
  });

  test('only the Timed Test and the Full Exam run against a clock', () async {
    final chapter = (await source.chapters()).first;
    expect(QuizConfig.timedTest(chapter, 10).timed, isTrue);
    expect(QuizConfig.fullExam().timed, isTrue);
    expect(QuizConfig.chapterPractice(chapter).timed, isFalse);
    expect(QuizConfig.mockExam(20).timed, isFalse);
    expect(QuizConfig.bookmarked().timed, isFalse);
  });
}
