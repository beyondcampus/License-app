/// Date helpers for streak tracking and spaced repetition.
abstract final class AppDateUtils {
  /// Strips the time component.
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Whole days between two dates (ignoring time of day).
  static int daysBetween(DateTime a, DateTime b) =>
      dateOnly(b).difference(dateOnly(a)).inDays;

  static bool isSameDay(DateTime a, DateTime b) => daysBetween(a, b) == 0;

  /// Computes the new streak given the previous study date and streak.
  /// Same day → unchanged; yesterday → +1; otherwise → reset to 1.
  static int nextStreak({
    required DateTime? lastStudyDate,
    required int currentStreak,
    required DateTime now,
  }) {
    if (lastStudyDate == null) return 1;
    final gap = daysBetween(lastStudyDate, now);
    if (gap <= 0) return currentStreak == 0 ? 1 : currentStreak;
    if (gap == 1) return currentStreak + 1;
    return 1;
  }

  /// ISO date string (yyyy-MM-dd) for prefs storage.
  static String toIsoDate(DateTime dt) {
    final d = dateOnly(dt);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime? tryParseIsoDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Formats seconds as `m:ss` (or `h:mm:ss` above an hour).
  static String formatDuration(int totalSeconds) {
    final seconds = totalSeconds < 0 ? 0 : totalSeconds;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }
}
