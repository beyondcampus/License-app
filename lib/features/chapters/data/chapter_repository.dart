import '../../../core/services/content_source.dart';
import '../domain/chapter.dart';
import '../domain/topic.dart';

/// Chapter/topic counts shown on cards.
class ChapterStats {
  const ChapterStats({required this.topicCount, required this.questionCount});
  final int topicCount;
  final int questionCount;
}

abstract class ChapterRepository {
  Future<List<Chapter>> getChapters();
  Future<Chapter?> getChapter(String chapterId);
  Future<List<Topic>> getTopics(String chapterId);
  Future<List<Topic>> getAllTopics();
  Future<Topic?> getTopic(String topicId);
  Future<ChapterStats> getStats(String chapterId);
  Future<Map<String, int>> questionCountsForChapter(String chapterId);

  /// Question ids per topic, in content order.
  Future<Map<String, List<String>>> questionIdsForChapter(String chapterId);
  Future<int> questionCountForChapter(String chapterId);
  Future<Map<String, int>> questionCountsByChapter();
  Future<int> questionCountForTopic(String topicId);
}

class ChapterRepositoryImpl implements ChapterRepository {
  ChapterRepositoryImpl(this._source);

  final ContentSource _source;

  @override
  Future<List<Chapter>> getChapters() => _source.chapters();

  @override
  Future<Chapter?> getChapter(String chapterId) async =>
      (await _source.chapters()).where((c) => c.id == chapterId).firstOrNull;

  @override
  Future<List<Topic>> getTopics(String chapterId) =>
      _source.topics(chapterId: chapterId);

  @override
  Future<List<Topic>> getAllTopics() => _source.topics();

  @override
  Future<Topic?> getTopic(String topicId) async =>
      (await _source.topics()).where((t) => t.id == topicId).firstOrNull;

  @override
  Future<ChapterStats> getStats(String chapterId) async {
    // Count what the chapter screen lists: top-level topics only.
    final topics = (await getTopics(chapterId))
        .where((t) => t.parentTopicId == null)
        .length;
    final questions = await questionCountForChapter(chapterId);
    return ChapterStats(topicCount: topics, questionCount: questions);
  }

  @override
  Future<int> questionCountForChapter(String chapterId) =>
      _source.questionCount(chapterId: chapterId);

  @override
  Future<Map<String, int>> questionCountsByChapter() async => {
        for (final row in await _source.questionCountsByChapter())
          if (row['chapter_id'] != null)
            row['chapter_id'].toString():
                (row['mcq_count'] as num?)?.toInt() ?? 0,
      };

  @override
  Future<Map<String, int>> questionCountsForChapter(String chapterId) async {
    final counts = <String, int>{};
    for (final question in await _source.questions(chapterId: chapterId)) {
      counts.update(question.topicId, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Future<Map<String, List<String>>> questionIdsForChapter(
    String chapterId,
  ) async {
    final ids = <String, List<String>>{};
    for (final question in await _source.questions(chapterId: chapterId)) {
      ids.putIfAbsent(question.topicId, () => []).add(question.id);
    }
    return ids;
  }

  @override
  Future<int> questionCountForTopic(String topicId) async =>
      (await _source.questions(topicId: topicId)).length;
}
