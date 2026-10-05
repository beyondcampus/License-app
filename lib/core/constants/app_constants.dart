/// Global non-visual constants: quiz behaviour, spaced repetition, ads.
abstract final class AppConstants {
  // Quiz.
  static const int defaultQuizLength = 10;
  static const int mockExamLength = 20;
  static const int timedSecondsPerQuestion = 45;
  static const List<int> quizLengthChoices = [5, 10, 15, 20];

  // Full exam: 100 one-mark questions (10 per chapter), 120 minutes.
  static const int fullExamMinutes = 120;

  // Analytics.
  static const double weakTopicThreshold = 0.60;
  static const int weakTopicMinAttempts = 4;
  static const int maxRecommendations = 3;

  // Spaced repetition.
  static const double initialEase = 2.0;
  static const double minEase = 1.3;
  static const double maxEase = 2.8;
  static const double easeStep = 0.15;
  static const int hardIntervalDays = 1;
  static const int initialGoodIntervalDays = 3;
  static const int minEasyIntervalDays = 4;
  static const double easyBonus = 1.5;

  // Ads.
  static const Duration interstitialCooldown = Duration(minutes: 3);
  static const int maxInterstitialsPerSession = 5;

  // Persistence keys.
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefStreakCount = 'pref_streak_count';
  static const String prefLastStudyDate = 'pref_last_study_date';
  static const String prefQuizLength = 'pref_quiz_length';

  // Database.
  static const String dbName = 'exam_prep_pro.db';
  static const int dbVersion = 4;
}
