import 'dart:math';

import '../../../core/services/content_source.dart';
import '../domain/full_exam_paper.dart';
import '../domain/question.dart';

abstract class QuestionRepository {
  Future<List<Question>> getAll();
  Future<List<Question>> getByChapter(String chapterId);
  Future<List<Question>> getByTopic(String topicId);
  Future<List<Question>> getByTopics(List<String> topicIds);
  Future<List<Question>> getByIds(List<String> ids);

  /// Random cross-chapter sample for mock exams (deterministic with [seed]).
  Future<List<Question>> getMockSample(int count, {int? seed});

  /// Full-length paper in the exam-hall pattern (deterministic with [seed]).
  Future<FullExamPaper> getFullExamPaper({int? seed});
}

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._source);

  final ContentSource _source;

  @override
  Future<List<Question>> getAll() => _source.questions();

  @override
  Future<List<Question>> getByChapter(String chapterId) =>
      _source.questions(chapterId: chapterId);

  @override
  Future<List<Question>> getByTopic(String topicId) =>
      _source.questions(topicId: topicId);

  @override
  Future<List<Question>> getByTopics(List<String> topicIds) async {
    final wanted = topicIds.toSet();
    return (await _source.questions())
        .where((q) => wanted.contains(q.topicId))
        .toList();
  }

  @override
  Future<List<Question>> getByIds(List<String> ids) async {
    final wanted = ids.toSet();
    return (await _source.questions())
        .where((q) => wanted.contains(q.id))
        .toList();
  }

  @override
  Future<List<Question>> getMockSample(int count, {int? seed}) async {
    final all = [...await _source.questions()];
    all.shuffle(Random(seed));
    return all.take(count).toList();
  }

  @override
  Future<FullExamPaper> getFullExamPaper({int? seed}) async =>
      FullExamPaper.build(
        chapters: await _source.chapters(),
        topics: await _source.topics(),
        questions: await _source.questions(),
        random: Random(seed),
      );
}
