import 'package:exam_prep_pro/core/utils/date_utils.dart';
import 'package:exam_prep_pro/core/utils/math_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils.nextStreak', () {
    final today = DateTime(2026, 9, 14, 18, 30);

    test('first ever study starts at 1', () {
      expect(
          AppDateUtils.nextStreak(
              lastStudyDate: null, currentStreak: 0, now: today),
          1);
    });

    test('same-day study keeps the streak', () {
      expect(
          AppDateUtils.nextStreak(
              lastStudyDate: DateTime(2026, 9, 14, 8),
              currentStreak: 5,
              now: today),
          5);
    });

    test('consecutive day increments', () {
      expect(
          AppDateUtils.nextStreak(
              lastStudyDate: DateTime(2026, 9, 13, 23, 59),
              currentStreak: 5,
              now: today),
          6);
    });

    test('gap of 2+ days resets to 1', () {
      expect(
          AppDateUtils.nextStreak(
              lastStudyDate: DateTime(2026, 9, 11),
              currentStreak: 30,
              now: today),
          1);
    });
  });

  group('formatting', () {
    test('formatDuration', () {
      expect(AppDateUtils.formatDuration(28), '0:28');
      expect(AppDateUtils.formatDuration(605), '10:05');
      expect(AppDateUtils.formatDuration(3700), '1:01:40');
      expect(AppDateUtils.formatDuration(-5), '0:00');
    });

    test('iso date round trip', () {
      final date = DateTime(2026, 1, 5, 14);
      final iso = AppDateUtils.toIsoDate(date);
      expect(iso, '2026-01-05');
      expect(AppDateUtils.tryParseIsoDate(iso), DateTime(2026, 1, 5));
      expect(AppDateUtils.tryParseIsoDate('garbage'), isNull);
      expect(AppDateUtils.tryParseIsoDate(null), isNull);
    });
  });

  group('MathUtils', () {
    test('safe ratios', () {
      expect(MathUtils.ratio(1, 0), 0);
      expect(MathUtils.ratio(3, 4), 0.75);
      expect(MathUtils.ratio(9, 4), 1.0); // clamped
      expect(MathUtils.percent(2, 3), 67);
      expect(MathUtils.percentLabel(1, 2), '50%');
      expect(MathUtils.average(10, 0), 0);
    });
  });
}
