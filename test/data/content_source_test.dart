import 'package:exam_prep_pro/core/services/content_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixture_content.dart';

/// Content integrity: parses the snapshot of the Supabase content
/// (test/fixtures/content, from tools/export_supabase_assets.js) and enforces
/// the minimum content targets and referential integrity from
/// plan/03-data-and-content.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = ContentSource(FixtureContentBackend.snapshot());

  test('chapters: 10 chapters in order', () async {
    final chapters = await source.chapters();
    expect(chapters.length, 10);
    expect(chapters.map((c) => c.id),
        ['ch1', 'ch2', 'ch3', 'ch4', 'ch5', 'ch6', 'ch7', 'ch8', 'ch9', 'ch10']);
    for (final c in chapters) {
      expect(c.title, isNotEmpty);
      expect(c.description, isNotEmpty);
    }
  });

  test('topics: all referencing valid chapters and parents', () async {
    final chapters = await source.chapters();
    final chapterIds = chapters.map((c) => c.id).toSet();
    final topics = await source.topics();
    // Chapter 1 is a topic → subtopic tree (2026-09 restructure), so its count
    // changes with the migration; the other chapters are still flat lists.
    expect(topics.length, greaterThanOrEqualTo(148));
    for (final t in topics) {
      expect(chapterIds.contains(t.chapterId), isTrue,
          reason: 'topic ${t.id} references unknown chapter');
      expect(t.title, isNotEmpty);
    }
    // A subtopic's parent exists, sits in the same chapter and is top-level.
    final byId = {for (final t in topics) t.id: t};
    for (final t in topics.where((t) => t.parentTopicId != null)) {
      final parent = byId[t.parentTopicId];
      expect(parent, isNotNull,
          reason: 'topic ${t.id} references unknown parent ${t.parentTopicId}');
      expect(parent!.chapterId, t.chapterId,
          reason: 'topic ${t.id} and its parent are in different chapters');
      expect(parent.parentTopicId, isNull,
          reason: 'topic ${t.id} is nested more than one level deep');
    }
    expect(topics.where((t) => t.chapterId == 'ch1').length,
        greaterThanOrEqualTo(28));
    // Chapters are restructured one by one; each keeps at least its original
    // topic count and every chapter has content.
    for (final (chapter, minimum) in [
      ('ch2', 23), ('ch3', 20), ('ch4', 14), ('ch5', 14),
      ('ch6', 11), ('ch7', 13), ('ch8', 10), ('ch9', 15),
    ]) {
      expect(topics.where((t) => t.chapterId == chapter).length,
          greaterThanOrEqualTo(minimum),
          reason: '$chapter lost topics');
    }
  });

  test('questions: ≥75 valid questions with integrity', () async {
    final topics = await source.topics();
    final topicIds = topics.map((t) => t.id).toSet();
    final questions = await source.questions();
    expect(questions.length, greaterThanOrEqualTo(75));
    final ids = <String>{};
    for (final q in questions) {
      expect(ids.add(q.id), isTrue, reason: 'duplicate question id ${q.id}');
      expect(topicIds.contains(q.topicId), isTrue,
          reason: 'question ${q.id} references unknown topic ${q.topicId}');
      expect(q.options.length, greaterThanOrEqualTo(2));
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
      expect(q.explanation, isNotEmpty,
          reason: 'question ${q.id} has no explanation');
    }
    // Every chapter has at least 25 questions.
    for (final ch in [
      'ch1',
      'ch2',
      'ch3',
      'ch4',
      'ch5',
      'ch6',
      'ch7',
      'ch8',
      'ch9'
    ]) {
      expect(questions.where((q) => q.chapterId == ch).length,
          greaterThanOrEqualTo(25));
    }
  });

  test('theory: content exists for every topic', () async {
    final topics = await source.topics();
    final theory = await source.theory();
    final byTopic = {for (final t in theory) t.topicId: t};
    // Parent topics only group their subtopics and carry no theory of their own.
    final parentIds = {
      for (final t in topics)
        if (t.parentTopicId != null) t.parentTopicId!,
    };
    for (final topic in topics.where((t) => !parentIds.contains(t.id))) {
      final content = byTopic[topic.id];
      expect(content, isNotNull,
          reason: 'no theory content for topic ${topic.id}');
      expect(content!.concepts, isNotEmpty,
          reason: 'topic ${topic.id} has no concept blocks');
      expect(content.notes, isNotEmpty,
          reason: 'topic ${topic.id} has no notes');
    }
  });

  test('formulas: ≥24 with chapter coverage and plainText fallback', () async {
    final formulas = await source.formulas();
    expect(formulas.length, greaterThanOrEqualTo(24));
    for (final f in formulas) {
      expect(f.plainText, isNotEmpty);
      expect(f.title, isNotEmpty);
    }
    expect(formulas.map((f) => f.chapterId).toSet(), containsAll(['ch1', 'ch2', 'ch3', 'ch4']));
  });

  test('flashcards: ≥24 with chapter coverage', () async {
    final cards = await source.flashcards();
    expect(cards.length, greaterThanOrEqualTo(24));
    for (final ch in [
      'ch1',
      'ch2',
      'ch3',
      'ch4',
      'ch5',
      'ch6',
      'ch7',
      'ch8',
      'ch9'
    ]) {
      expect(cards.where((c) => c.chapterId == ch).length,
          greaterThanOrEqualTo(1));
    }
    for (final c in cards) {
      expect(c.front, isNotEmpty);
      expect(c.back, isNotEmpty);
    }
  });

  test('difficulty mix: all three difficulties present', () async {
    final questions = await source.questions();
    final names = questions.map((q) => q.difficulty.name).toSet();
    expect(names, containsAll(['easy', 'medium', 'hard']));
  });
}
