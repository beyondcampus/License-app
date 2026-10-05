import 'package:flutter/foundation.dart';

import '../../../core/utils/math_utils.dart';
import '../../analytics/domain/topic_performance.dart';
import '../../quiz/data/practice_progress_repository.dart';
import '../data/chapter_repository.dart';
import '../data/progress_repository.dart';
import '../domain/chapter.dart';
import '../domain/topic.dart';

enum LoadState { initial, loading, ready, error }

/// Chapters, topics, per-chapter stats and overall user progress —
/// backs the dashboard and the Chapters tab.
class ChapterProvider extends ChangeNotifier {
  ChapterProvider(this._chapters, this._progress, [this._practice]);

  final ChapterRepository _chapters;
  final ProgressRepository _progress;
  final PracticeProgressRepository? _practice;

  LoadState state = LoadState.initial;
  String? errorMessage;

  List<Chapter> chapters = [];
  Map<String, List<Topic>> topicsByChapter = {};
  Map<String, int> topicCountByChapter = {};
  Map<String, ChapterStats> statsByChapter = {};
  Map<String, TopicProgress> topicProgress = {};
  Map<String, int> questionCountByTopic = {};

  /// Question ids per topic, and the ids whose latest Practice answer is
  /// correct — for the "12 left of 50" practice cards.
  Map<String, List<String>> questionIdsByTopic = {};
  Set<String> practiceCorrect = {};
  UserProgress userProgress = UserProgress.empty;

  /// Topics that carry theory/questions: every topic that is not a parent
  /// group. Progress is measured over these.
  int get totalTopics => topicsByChapter.values.fold(
    0,
    (sum, topics) => sum + topics.where(isLeafTopic).length,
  );

  Set<String> _parentIds = {};

  Future<void> load() async {
    if (state == LoadState.loading) return;
    state = LoadState.loading;
    notifyListeners();
    try {
      chapters = await _chapters.getChapters();
      final allTopics = await _chapters.getAllTopics();
      _parentIds = {
        for (final topic in allTopics)
          if (topic.parentTopicId != null) topic.parentTopicId!,
      };
      topicsByChapter = {
        for (final chapter in chapters)
          chapter.id: allTopics
              .where((topic) => topic.chapterId == chapter.id)
              .toList(),
      };
      topicCountByChapter = {
        for (final chapter in chapters)
          chapter.id: (topicsByChapter[chapter.id] ?? const [])
              .where((topic) => topic.parentTopicId == null)
              .length,
      };
      final questionCounts = await _chapters.questionCountsByChapter();
      statsByChapter = {
        for (final chapter in chapters)
          chapter.id: ChapterStats(
            topicCount: topicCountByChapter[chapter.id] ?? 0,
            questionCount: questionCounts[chapter.id] ?? 0,
          ),
      };
      await refreshProgress();
      state = LoadState.ready;
    } catch (e) {
      debugPrint('ChapterProvider.load: $e');
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// Kept for screens that open a chapter directly; all chapters are
  /// loaded up front by [load], so this only fills a gap after an error.
  Future<void> loadChapter(String chapterId) async {
    final topics = topicsByChapter[chapterId] ??= await _chapters.getTopics(
      chapterId,
    );
    statsByChapter[chapterId] ??= await _chapters.getStats(chapterId);
    final missingTopicCounts = topics
        .where((topic) => !questionCountByTopic.containsKey(topic.id))
        .toList();
    if (missingTopicCounts.isEmpty) return;
    final ids = await _chapters.questionIdsForChapter(chapterId);
    questionIdsByTopic.addAll(ids);
    questionCountByTopic.addAll({
      for (final e in ids.entries) e.key: e.value.length,
    });
    notifyListeners();
  }

  /// Content changed underneath us (sign-in / sign-out invalidates the
  /// cache): drop everything and load again from the sources.
  Future<void> reloadContent() async {
    clearContent();
    await load();
  }

  void clearContent() {
    chapters = [];
    topicsByChapter = {};
    topicCountByChapter = {};
    statsByChapter = {};
    questionCountByTopic = {};
    questionIdsByTopic = {};
    practiceCorrect = {};
    _parentIds = {};
    state = LoadState.initial;
  }

  // ---- Topic → subtopic hierarchy -----------------------------------------

  /// True when other topics point to [topic] as their parent.
  bool hasSubtopics(Topic topic) => _parentIds.contains(topic.id);

  bool isLeafTopic(Topic topic) => !hasSubtopics(topic);

  /// What the chapter screen lists: topics without a parent. A topic whose
  /// parent is missing from the data is shown at the top level too.
  List<Topic> topLevelTopics(String chapterId) {
    final topics = topicsByChapter[chapterId] ?? const [];
    final ids = {for (final t in topics) t.id};
    return topics
        .where((t) => t.parentTopicId == null || !ids.contains(t.parentTopicId))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Topic> subtopicsOf(Topic parent) =>
      (topicsByChapter[parent.chapterId] ?? const [])
          .where((t) => t.parentTopicId == parent.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// Question count shown on a card: a parent group sums its subtopics.
  int questionCountFor(Topic topic) => hasSubtopics(topic)
      ? subtopicsOf(topic)
            .fold(0, (sum, t) => sum + (questionCountByTopic[t.id] ?? 0))
      : questionCountByTopic[topic.id] ?? 0;

  /// Re-reads progress rows (cheap) — called after studying, completing or
  /// practising.
  Future<void> refreshProgress() async {
    topicProgress = await _progress.getAllTopicProgress();
    userProgress = await _progress.getUserProgress(totalTopics);
    try {
      practiceCorrect = await _practice?.correctQuestionIds() ?? {};
    } catch (e) {
      // Practice progress is extra; the chapter screens work without it.
      debugPrint('ChapterProvider: failed to read practice progress: $e');
    }
    notifyListeners();
  }

  /// Questions of [topic] (a group sums its subtopics) whose latest Practice
  /// answer is correct.
  int practiceCorrectFor(Topic topic) => hasSubtopics(topic)
      ? subtopicsOf(topic).fold(0, (sum, t) => sum + _practiceCorrectIn(t.id))
      : _practiceCorrectIn(topic.id);

  int _practiceCorrectIn(String topicId) =>
      (questionIdsByTopic[topicId] ?? const [])
          .where(practiceCorrect.contains)
          .length;

  double topicCompletion(String topicId) =>
      topicProgress[topicId]?.completionPct ?? 0;

  bool isTopicCompleted(String topicId) =>
      topicProgress[topicId]?.completed ?? false;

  /// Completion of a card: a parent group averages its subtopics.
  double completionFor(Topic topic) => hasSubtopics(topic)
      ? _averageCompletion(subtopicsOf(topic))
      : topicCompletion(topic.id);

  bool isCompletedFor(Topic topic) => hasSubtopics(topic)
      ? subtopicsOf(topic).every((t) => isTopicCompleted(t.id))
      : isTopicCompleted(topic.id);

  /// Average completion across a chapter's leaf topics.
  double chapterCompletion(String chapterId) => _averageCompletion(
    (topicsByChapter[chapterId] ?? const []).where(isLeafTopic).toList(),
  );

  double _averageCompletion(List<Topic> topics) {
    if (topics.isEmpty) return 0;
    final sum = topics.fold<double>(0, (acc, t) => acc + topicCompletion(t.id));
    return MathUtils.ratio(sum, topics.length);
  }

  Future<void> markTopicStudied(String topicId) async {
    await _progress.recordTopicStudied(topicId);
    await refreshProgress();
  }

  Future<void> setTopicCompleted(String topicId, bool completed) async {
    await _progress.setTopicCompleted(topicId, completed);
    await refreshProgress();
  }
}
