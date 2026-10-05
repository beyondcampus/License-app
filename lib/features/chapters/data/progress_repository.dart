import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/database_helper.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/math_utils.dart';
import '../../analytics/domain/topic_performance.dart';
import '../../streak/streak_service.dart';

/// Per-topic study progress row.
class TopicProgress {
  const TopicProgress({
    required this.topicId,
    required this.completed,
    required this.completionPct,
  });

  final String topicId;
  final bool completed;
  final double completionPct;
}

abstract class ProgressRepository {
  Future<Map<String, TopicProgress>> getAllTopicProgress();
  Future<TopicProgress?> getTopicProgress(String topicId);

  /// Marks study progress on a topic (also bumps the daily streak).
  Future<void> recordTopicStudied(String topicId, {double? completionPct});
  Future<void> setTopicCompleted(String topicId, bool completed);

  /// Overall readiness snapshot for the dashboard.
  Future<UserProgress> getUserProgress(int totalTopics);
}

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._dbHelper, this._prefs);

  final DatabaseHelper _dbHelper;
  final PrefsService _prefs;

  @override
  Future<Map<String, TopicProgress>> getAllTopicProgress() async {
    final db = await _dbHelper.database;
    final rows = await db.query('topic_progress');
    return {
      for (final row in rows)
        row['topic_id'] as String: TopicProgress(
          topicId: row['topic_id'] as String,
          completed: (row['completed'] as num?) == 1,
          completionPct: (row['completion_pct'] as num?)?.toDouble() ?? 0,
        ),
    };
  }

  @override
  Future<TopicProgress?> getTopicProgress(String topicId) async =>
      (await getAllTopicProgress())[topicId];

  @override
  Future<void> recordTopicStudied(String topicId,
      {double? completionPct}) async {
    final db = await _dbHelper.database;
    final existing = await getTopicProgress(topicId);
    final pct = completionPct ??
        ((existing?.completionPct ?? 0) < 0.5
            ? 0.5
            : existing?.completionPct ?? 0.5);
    await db.insert(
      'topic_progress',
      {
        'topic_id': topicId,
        'completed': (existing?.completed ?? false) ? 1 : 0,
        'completion_pct': pct.clamp(0.0, 1.0),
        'last_studied_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _prefs.recordStudyActivity();
  }

  @override
  Future<void> setTopicCompleted(String topicId, bool completed) async {
    final db = await _dbHelper.database;
    await db.insert(
      'topic_progress',
      {
        'topic_id': topicId,
        'completed': completed ? 1 : 0,
        'completion_pct': completed ? 1.0 : 0.5,
        'last_studied_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (completed) await _prefs.recordStudyActivity();
  }

  @override
  Future<UserProgress> getUserProgress(int totalTopics) async {
    final progress = await getAllTopicProgress();
    final completed = progress.values.where((p) => p.completed).length;
    final pctSum = progress.values
        .fold<double>(0, (sum, p) => sum + p.completionPct.clamp(0.0, 1.0));
    return UserProgress(
      readiness: MathUtils.ratio(pctSum, totalTopics),
      streak: _prefs.effectiveStreak,
      completedTopics: completed,
      totalTopics: totalTopics,
    );
  }
}

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this._client, this._streakService,
      {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final StreakService _streakService;
  final DateTime Function() _now;

  String get _userId => _client.auth.currentUser?.id ??
      (throw StateError('A signed-in user is required'));

  @override
  Future<Map<String, TopicProgress>> getAllTopicProgress() async {
    final rows = await _client
        .from('user_topic_progress')
        .select('topic_id, completed, completion_pct')
        .eq('user_id', _userId);
    return {
      for (final row in rows)
        row['topic_id'] as String: TopicProgress(
          topicId: row['topic_id'] as String,
          completed: row['completed'] as bool? ?? false,
          completionPct: (((row['completion_pct'] as num?)?.toDouble() ?? 0) /
                  100)
              .clamp(0.0, 1.0),
        ),
    };
  }

  @override
  Future<TopicProgress?> getTopicProgress(String topicId) async =>
      (await getAllTopicProgress())[topicId];

  @override
  Future<void> recordTopicStudied(String topicId,
      {double? completionPct}) async {
    final existing = await getTopicProgress(topicId);
    final pct = completionPct ??
        ((existing?.completionPct ?? 0) < 0.5
            ? 0.5
            : existing?.completionPct ?? 0.5);
    await _client.from('user_topic_progress').upsert({
      'user_id': _userId,
      'topic_id': topicId,
      'completed': existing?.completed ?? false,
      'completion_pct': (pct.clamp(0.0, 1.0) * 100).roundToDouble(),
      'last_studied_at': _now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,topic_id');
    await _streakService.recordActivity(source: 'topic');
  }

  @override
  Future<void> setTopicCompleted(String topicId, bool completed) async {
    await _client.from('user_topic_progress').upsert({
      'user_id': _userId,
      'topic_id': topicId,
      'completed': completed,
      'completion_pct': completed ? 100 : 50,
      'last_studied_at': _now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,topic_id');
    if (completed) await _streakService.recordActivity(source: 'topic');
  }

  @override
  Future<UserProgress> getUserProgress(int totalTopics) async {
    final progress = await getAllTopicProgress();
    final completed = progress.values.where((p) => p.completed).length;
    final pctSum = progress.values.fold<double>(
        0, (sum, p) => sum + p.completionPct.clamp(0.0, 1.0));
    return UserProgress(
      readiness: MathUtils.ratio(pctSum, totalTopics),
      streak: await _streakService.calculateCurrentStreak(),
      completedTopics: completed,
      totalTopics: totalTopics,
    );
  }
}
