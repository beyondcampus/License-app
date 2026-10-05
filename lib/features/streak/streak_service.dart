import 'package:supabase_flutter/supabase_flutter.dart';

class StreakService {
  StreakService(this._client, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _now;

  Future<void> recordActivity({String source = 'app'}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final today = _dateOnly(_now());
    await _client.from('study_activity').upsert(
      {
        'user_id': userId,
        'activity_date': _formatDate(today),
        'source': source,
      },
      onConflict: 'user_id,activity_date',
    );
  }

  /// Reconstructs current streak dynamically from study_activity dates
  Future<int> calculateCurrentStreak() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('study_activity')
        .select('activity_date')
        .eq('user_id', userId)
        .order('activity_date', ascending: false);

    final List<dynamic> rows = response as List<dynamic>;
    if (rows.isEmpty) return 0;

    final dates = rows
        .map((r) => DateTime.parse(r['activity_date'] as String))
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = _dateOnly(_now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (!dates.contains(today) && !dates.contains(yesterday)) {
      return 0; // Streak broken
    }

    int streak = 0;
    DateTime checkDate = dates.contains(today) ? today : yesterday;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}