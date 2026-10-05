import 'dart:math';

import '../../chapters/domain/chapter.dart';
import '../../chapters/domain/topic.dart';
import 'question.dart';

/// A full-length paper for the exam-hall simulation: 100 one-mark MCQs,
/// 10 from each of the 10 chapters.
///
/// Within a chapter every syllabus section (top-level topic) contributes at
/// least one question; the remaining questions come from different sections
/// chosen at random, so no section gets more than one extra. Built purely
/// from content so it is testable.
class FullExamPaper {
  const FullExamPaper({required this.questions});

  /// In random order: chapters and sections are mixed, so no two papers run
  /// the same way.
  final List<Question> questions;

  /// Every question carries one mark.
  int get totalMarks => questions.length;

  static const int questionsPerChapter = 10;
  static const int sectionsPerChapter = 6;

  static FullExamPaper build({
    required List<Chapter> chapters,
    required List<Topic> topics,
    required List<Question> questions,
    Random? random,
  }) {
    final rng = random ?? Random();
    final byTopic = <String, List<Question>>{};
    for (final q in questions) {
      byTopic.putIfAbsent(q.topicId, () => []).add(q);
    }

    final paper = <Question>[];
    for (final chapter in [...chapters]
      ..sort((a, b) => a.order.compareTo(b.order))) {
      final pools = [
        for (final pool in _sectionPools(chapter, topics, byTopic))
          [...pool]..shuffle(rng),
      ];
      final picked = <Question>[];
      // Round 1 takes one question from every section in syllabus order;
      // later rounds visit the sections in random order, one question each.
      for (var round = 0; picked.length < questionsPerChapter; round++) {
        final order = [for (var s = 0; s < pools.length; s++) s];
        if (round > 0) order.shuffle(rng);
        var progressed = false;
        for (final s in order) {
          if (picked.length == questionsPerChapter) break;
          if (pools[s].isEmpty) continue;
          picked.add(pools[s].removeLast());
          progressed = true;
        }
        if (!progressed) break;
      }
      paper.addAll(picked);
    }
    paper.shuffle(rng);
    return FullExamPaper(questions: paper);
  }

  /// The question pool of each syllabus section of [chapter], in order.
  /// A section is a top-level topic; its pool is the questions of its
  /// subtopics (or its own questions for a flat chapter). The chapter-wide
  /// revision topic is not a syllabus section and is skipped.
  static List<List<Question>> _sectionPools(
    Chapter chapter,
    List<Topic> topics,
    Map<String, List<Question>> byTopic,
  ) {
    final chapterTopics = topics.where((t) => t.chapterId == chapter.id);
    final parents = chapterTopics
        .where((t) => t.parentTopicId == null && !_isRevision(t))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final pools = <List<Question>>[];
    for (final parent in parents.take(sectionsPerChapter)) {
      final children = chapterTopics.where((t) => t.parentTopicId == parent.id);
      final pool = <Question>[
        ...?byTopic[parent.id],
        for (final child in children) ...?byTopic[child.id],
      ];
      if (pool.isNotEmpty) pools.add(pool);
    }
    return pools;
  }

  static bool _isRevision(Topic t) =>
      t.title.toLowerCase().startsWith('quick revision');
}
