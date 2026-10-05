import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../chapters/data/chapter_repository.dart';
import '../../quiz/domain/quiz_result.dart';
import '../data/results_repository.dart';
import '../domain/topic_performance.dart';

/// A weak topic with its display names, ready for the UI.
class WeakTopic {
  const WeakTopic({
    required this.topicId,
    required this.topicTitle,
    required this.chapterTitle,
    required this.accuracy,
    required this.attempted,
  });

  final String topicId;
  final String topicTitle;
  final String chapterTitle;
  final double accuracy;
  final int attempted;
}

/// Per-chapter accuracy with its title, for the bar chart.
class ChapterAccuracy {
  const ChapterAccuracy({
    required this.chapterId,
    required this.title,
    required this.shortTitle,
    required this.accuracy,
    required this.attempted,
  });

  final String chapterId;
  final String title;
  final String shortTitle;
  final double accuracy;
  final int attempted;
}

/// Aggregates stored quiz history into the analytics shown on the Stats tab.
/// Everything here is computed from question_attempts — nothing is hardcoded.
class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._results, this._chapters);

  final ResultsRepository _results;
  final ChapterRepository _chapters;

  bool loading = false;
  bool loaded = false;
  String? error;

  QuizResult? latestResult;
  int totalQuizzes = 0;
  List<ChapterAccuracy> chapterAccuracy = [];
  List<TopicPerformance> topicPerformance = [];
  List<WeakTopic> weakTopics = [];
  List<String> recommendations = [];

  bool get hasHistory => totalQuizzes > 0;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      latestResult = await _results.getLatestResult();
      totalQuizzes = await _results.totalQuizCount();
      topicPerformance = await _results.getTopicPerformance();

      final chapters = await _chapters.getChapters();
      final chapterPerf = {
        for (final p in await _results.getChapterPerformance())
          p.chapterId: p,
      };
      chapterAccuracy = [
        for (final chapter in chapters)
          ChapterAccuracy(
            chapterId: chapter.id,
            title: chapter.title,
            shortTitle: 'Chap ${chapter.order}',
            accuracy: chapterPerf[chapter.id]?.accuracy ?? 0,
            attempted: chapterPerf[chapter.id]?.attempted ?? 0,
          ),
      ];

      weakTopics = await _computeWeakTopics();
      recommendations = _buildRecommendations();
      error = null;
    } catch (e) {
      debugPrint('AnalyticsProvider.load: $e');
      error = e.toString();
    }
    loading = false;
    loaded = true;
    notifyListeners();
  }

  Future<List<WeakTopic>> _computeWeakTopics() async {
    final topics = await _chapters.getAllTopics();
    final chapters = await _chapters.getChapters();
    final topicById = {for (final t in topics) t.id: t};
    final chapterById = {for (final c in chapters) c.id: c};

    final weak = topicPerformance
        .where((p) =>
            p.attempted >= AppConstants.weakTopicMinAttempts &&
            p.accuracy < AppConstants.weakTopicThreshold)
        .toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return [
      for (final p in weak)
        WeakTopic(
          topicId: p.topicId,
          topicTitle: topicById[p.topicId]?.title ?? p.topicId,
          chapterTitle:
              chapterById[p.chapterId]?.title ?? p.chapterId,
          accuracy: p.accuracy,
          attempted: p.attempted,
        ),
    ];
  }

  /// Builds recommendation sentences from actual performance data.
  List<String> _buildRecommendations() {
    if (!hasHistory) return const [];
    final recs = <String>[];
    final top = weakTopics.take(AppConstants.maxRecommendations).toList();
    if (top.isNotEmpty) {
      final names = top.map((t) => t.topicTitle).toList();
      final joined = names.length == 1
          ? names.first
          : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
      recs.add('Focus on $joined before attempting another mock test.');
      for (final t in top) {
        recs.add(
            'Revisit the theory for ${t.topicTitle} (${t.chapterTitle}) — '
            '${(t.accuracy * 100).round()}% accuracy over ${t.attempted} '
            'answered questions.');
      }
    } else {
      final practiced =
          topicPerformance.where((p) => p.attempted > 0).length;
      final enoughData = topicPerformance
          .any((p) => p.attempted >= AppConstants.weakTopicMinAttempts);
      if (!enoughData) {
        recs.add('Keep practicing — answer a few more questions per topic '
            'to unlock personalized recommendations.');
      } else {
        recs.add('Great work! Your accuracy is above '
            '${(AppConstants.weakTopicThreshold * 100).round()}% across all '
            '$practiced practiced topics. Try a timed mock exam next.');
      }
    }
    return recs;
  }
}
