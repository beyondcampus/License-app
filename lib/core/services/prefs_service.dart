import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/date_utils.dart';

/// Thin wrapper over SharedPreferences for lightweight settings and progress.
/// All reads have safe defaults so a fresh install never crashes.
class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> init() async =>
      PrefsService(await SharedPreferences.getInstance());

  // --- Theme ---

  ThemeMode get themeMode {
    switch (_prefs.getString(AppConstants.prefThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark; // The design reference is dark-first.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(AppConstants.prefThemeMode, mode.name);

  // --- Streak ---

  int get streakCount => _prefs.getInt(AppConstants.prefStreakCount) ?? 0;

  DateTime? get lastStudyDate =>
      AppDateUtils.tryParseIsoDate(
          _prefs.getString(AppConstants.prefLastStudyDate));

  /// Records study activity for [now], updating the daily streak.
  /// Returns the new streak count.
  Future<int> recordStudyActivity([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final next = AppDateUtils.nextStreak(
      lastStudyDate: lastStudyDate,
      currentStreak: streakCount,
      now: today,
    );
    await _prefs.setInt(AppConstants.prefStreakCount, next);
    await _prefs.setString(
        AppConstants.prefLastStudyDate, AppDateUtils.toIsoDate(today));
    return next;
  }

  /// Streak shown on the dashboard: an old streak that was broken by a gap
  /// of more than one day reads as 0 until the user studies again.
  int get effectiveStreak {
    final last = lastStudyDate;
    if (last == null) return 0;
    final gap = AppDateUtils.daysBetween(last, DateTime.now());
    return gap > 1 ? 0 : streakCount;
  }

  // --- Quiz defaults ---

  int get preferredQuizLength =>
      _prefs.getInt(AppConstants.prefQuizLength) ??
      AppConstants.defaultQuizLength;

  Future<void> setPreferredQuizLength(int value) =>
      _prefs.setInt(AppConstants.prefQuizLength, value);
}
