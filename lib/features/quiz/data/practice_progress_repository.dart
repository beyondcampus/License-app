import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/database_helper.dart';

/// Each user's latest Practice-mode answer per question. Topic practice skips
/// the questions answered correctly, so a user continues with what is wrong
/// or not yet tried. Answers from other modes are not recorded.
abstract class PracticeProgressRepository {
  /// Ids of the questions whose latest Practice answer is correct.
  Future<Set<String>> correctQuestionIds();

  /// Records an answer the moment it is locked in, so leaving a quiz midway
  /// loses nothing.
  Future<void> record(String questionId, {required bool isCorrect});
}

class SupabasePracticeProgressRepository implements PracticeProgressRepository {
  SupabasePracticeProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser?.id ??
      (throw StateError('A signed-in user is required'));

  @override
  Future<Set<String>> correctQuestionIds() async {
    const pageSize = 1000;
    final ids = <String>{};
    for (var offset = 0; ; offset += pageSize) {
      final page = await _client
          .from('question_progress')
          .select('question_id')
          .eq('user_id', _userId)
          .eq('is_correct', true)
          .order('question_id', ascending: true)
          .range(offset, offset + pageSize - 1);
      ids.addAll(page.map((row) => row['question_id'] as String));
      if (page.length < pageSize) return ids;
    }
  }

  @override
  Future<void> record(String questionId, {required bool isCorrect}) =>
      _client.from('question_progress').upsert({
        'user_id': _userId,
        'question_id': questionId,
        'is_correct': isCorrect,
        'answered_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,question_id');
}

/// Local implementation, used without Supabase (tests).
class PracticeProgressRepositoryImpl implements PracticeProgressRepository {
  PracticeProgressRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<Set<String>> correctQuestionIds() async {
    final db = await _dbHelper.database;
    final rows = await db.query('practice_progress',
        columns: ['question_id'], where: 'is_correct = 1');
    return {for (final row in rows) row['question_id'] as String};
  }

  @override
  Future<void> record(String questionId, {required bool isCorrect}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'practice_progress',
      {
        'question_id': questionId,
        'is_correct': isCorrect ? 1 : 0,
        'answered_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
