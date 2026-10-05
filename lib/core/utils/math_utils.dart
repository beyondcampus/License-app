/// Numeric helpers for scores, accuracy and progress.
abstract final class MathUtils {
  /// Safe ratio in [0, 1]; returns 0 when the denominator is 0.
  static double ratio(num numerator, num denominator) {
    if (denominator == 0) return 0;
    final r = numerator / denominator;
    if (r.isNaN || r.isInfinite) return 0;
    return r.clamp(0.0, 1.0).toDouble();
  }

  /// Percentage 0–100 (rounded).
  static int percent(num numerator, num denominator) =>
      (ratio(numerator, denominator) * 100).round();

  static String percentLabel(num numerator, num denominator) =>
      '${percent(numerator, denominator)}%';

  /// Average with a safe denominator.
  static double average(num total, int count) =>
      count == 0 ? 0 : (total / count).toDouble();
}
