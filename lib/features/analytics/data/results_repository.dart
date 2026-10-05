import '../../../core/services/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../quiz/domain/quiz_result.dart';
import '../domain/topic_performance.dart';

abstract class ResultsRepository {
  /// Persists a finished quiz and its attempts. Returns the result row id.
  Future<int> saveResult(QuizResult result, List<QuestionAttempt> attempts);

  Future<QuizResult?> getLatestResult();
  Future<List<QuizResult>> getAllResults();
  Future<List<QuestionAttempt>> getAttemptsForResult(int resultId);
  Future<List<TopicPerformance>> getTopicPerformance();
  Future<List<ChapterPerformance>> getChapterPerformance();
  Future<int> totalQuizCount();
}

class ResultsRepositoryImpl implements ResultsRepository {
  ResultsRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<int> saveResult(
      QuizResult result, List<QuestionAttempt> attempts) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final resultId = await txn.insert('quiz_results', result.toDbMap());
      final batch = txn.batch();
      for (final attempt in attempts) {
        batch.insert('question_attempts', attempt.toDbMap(resultId));
      }
      await batch.commit(noResult: true);
      return resultId;
    });
  }

  @override
  Future<QuizResult?> getLatestResult() async {
    final db = await _dbHelper.database;
    final rows =
        await db.query('quiz_results', orderBy: 'taken_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    return QuizResult.fromDbMap(rows.first);
  }

  @override
  Future<List<QuizResult>> getAllResults() async {
    final db = await _dbHelper.database;
    final rows = await db.query('quiz_results', orderBy: 'taken_at DESC');
    return rows.map(QuizResult.fromDbMap).toList();
  }

  @override
  Future<List<QuestionAttempt>> getAttemptsForResult(int resultId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('question_attempts',
        where: 'result_id = ?', whereArgs: [resultId]);
    return rows.map(QuestionAttempt.fromDbMap).toList();
  }

  @override
  Future<List<TopicPerformance>> getTopicPerformance() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT topic_id, chapter_id,
             COUNT(*) AS attempted,
             SUM(is_correct) AS correct
      FROM question_attempts
      WHERE selected_index >= 0
      GROUP BY topic_id, chapter_id
    ''');
    return rows
        .map((row) => TopicPerformance(
              topicId: row['topic_id'] as String,
              chapterId: row['chapter_id'] as String,
              attempted: (row['attempted'] as num?)?.toInt() ?? 0,
              correct: (row['correct'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  @override
  Future<List<ChapterPerformance>> getChapterPerformance() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT chapter_id,
             COUNT(*) AS attempted,
             SUM(is_correct) AS correct
      FROM question_attempts
      WHERE selected_index >= 0
      GROUP BY chapter_id
    ''');
    return rows
        .map((row) => ChapterPerformance(
              chapterId: row['chapter_id'] as String,
              attempted: (row['attempted'] as num?)?.toInt() ?? 0,
              correct: (row['correct'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  @override
  Future<int> totalQuizCount() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM quiz_results');
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }
}

class SupabaseResultsRepository implements ResultsRepository {
  SupabaseResultsRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser?.id ??
      (throw StateError('A signed-in user is required'));

  @override
  Future<int> saveResult(
      QuizResult result, List<QuestionAttempt> attempts) async {
    final response = await _client.rpc('save_quiz_result', params: {
      'p_mode': result.mode.name,
      'p_chapter_id': result.chapterId,
      'p_score_achieved': result.correct,
      'p_score_total': result.total,
      'p_percentage': result.accuracy * 100,
      'p_time_seconds': result.timeSeconds,
      'p_attempts': attempts
          .map((attempt) => {
                'question_id': attempt.questionId,
                'chapter_id': attempt.chapterId,
                'topic_id': attempt.topicId,
                'selected_index': attempt.selectedIndex,
                'is_correct': attempt.isCorrect,
                'time_ms': attempt.timeMs,
              })
          .toList(),
    });
    // The current feature contract uses local integer IDs. Supabase owns the
    // UUID returned by the RPC; no caller relies on this legacy return value.
    if (response == null) throw StateError('Supabase did not return a result');
    return 0;
  }

  @override
  Future<QuizResult?> getLatestResult() async {
    final rows = await _client
        .from('quiz_results')
        .select()
        .eq('user_id', _userId)
        .order('taken_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return _resultFromRow(rows.first);
  }

  @override
  Future<List<QuizResult>> getAllResults() async {
    final rows = await _client
        .from('quiz_results')
        .select()
        .eq('user_id', _userId)
        .order('taken_at', ascending: false);
    return rows.map(_resultFromRow).toList();
  }

  @override
  Future<List<QuestionAttempt>> getAttemptsForResult(int resultId) async =>
      const [];

  @override
  Future<List<TopicPerformance>> getTopicPerformance() async {
    final rows = await _client
        .from('question_attempts')
        .select('topic_id, chapter_id, selected_index, is_correct')
        .eq('user_id', _userId)
        .gte('selected_index', 0);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final key = '${row['topic_id']}|${row['chapter_id']}';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    return grouped.values.map((items) {
      final first = items.first;
      return TopicPerformance(
        topicId: first['topic_id'] as String,
        chapterId: first['chapter_id'] as String,
        attempted: items.length,
        correct: items.where((row) => row['is_correct'] == true).length,
      );
    }).toList();
  }

  @override
  Future<List<ChapterPerformance>> getChapterPerformance() async {
    final rows = await _client
        .from('question_attempts')
        .select('chapter_id, selected_index, is_correct')
        .eq('user_id', _userId)
        .gte('selected_index', 0);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row['chapter_id'] as String, () => []).add(row);
    }
    return grouped.entries.map((entry) => ChapterPerformance(
          chapterId: entry.key,
          attempted: entry.value.length,
          correct:
              entry.value.where((row) => row['is_correct'] == true).length,
        )).toList();
  }

  @override
  Future<int> totalQuizCount() async {
    final rows = await _client
        .from('quiz_results')
        .select('id')
        .eq('user_id', _userId);
    return rows.length;
  }

  QuizResult _resultFromRow(Map<String, dynamic> row) => QuizResult(
        mode: QuizMode.values
                .where((mode) => mode.name == row['mode'])
                .firstOrNull ??
            QuizMode.practice,
        chapterId: row['chapter_id'] as String?,
        total: (row['score_total'] as num?)?.toInt() ?? 0,
        correct: (row['score_achieved'] as num?)?.toInt() ?? 0,
        incorrect: ((row['score_total'] as num?)?.toInt() ?? 0) -
            ((row['score_achieved'] as num?)?.toInt() ?? 0),
        unanswered: 0,
        timeSeconds: (row['time_seconds'] as num?)?.toInt() ?? 0,
        takenAt: DateTime.tryParse(row['taken_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
