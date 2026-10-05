/// User-facing strings, centralized for consistency (and future localization).
abstract final class AppStrings {
  static const String appName = 'ExamPrep Pro';

  // Dashboard.
  static const String overallReadiness = 'Overall Readiness';
  static const String selectSubjectModule = 'Select Subject Module';
  static const String practiceCenter = 'Practice Center';
  static const String quickActions = 'Quick Actions';

  // Navigation.
  static const String navHome = 'Home';
  static const String navChapters = 'Chapters';
  static const String navPractice = 'Practice';
  static const String navStats = 'Stats';
  static const String navCards = 'Cards';

  // Theory.
  static const String tabConcepts = 'Concepts';
  static const String tabFormulas = 'Formulas';
  static const String tabNotes = 'Notes';
  static const String tabTheory = 'Theory';
  static const String tabPractice = 'Practice';
  static const String practiceThisTopic = 'Practice MCQs';
  static const String formulaSheet = 'Formula Sheet';
  static const String markComplete = 'Mark as Complete';
  static const String completed = 'Completed';

  // Quiz.
  static const String question = 'Question';
  static const String singleChoice = 'Single Choice';
  static const String bookmark = 'Bookmark';
  static const String bookmarked = 'Bookmarked';
  static const String nextQuestion = 'Next Question';
  static const String previous = 'Previous';
  static const String finishQuiz = 'Finish Quiz';
  static const String submitAnswer = 'Submit Answer';
  static const String restartQuiz = 'Restart Quiz';
  static const String exitQuizTitle = 'Exit Quiz?';
  static const String exitQuizMessage =
      'Your progress in this quiz will be lost. Are you sure you want to exit?';
  static const String exit = 'Exit';
  static const String cancel = 'Cancel';
  static const String explanation = 'Explanation';
  static const String correct = 'Correct';
  static const String incorrect = 'Incorrect';
  static const String timeUp = "Time's up! Quiz submitted automatically.";

  // Quiz modes.
  static const String practiceMode = 'Practice Mode';
  static const String practiceModeDesc = 'Instant feedback after every answer';
  static const String timedTest = 'Timed Test';
  static const String timedTestDesc = 'Beat the countdown clock';
  static const String fullExam = 'Full Exam';
  static const String fullExamDesc =
      'Exam-hall pattern: 100 questions × 1 mark, 10 per chapter';
  static const String mockExam = 'Mock Exam';
  static const String mockExamDesc = 'Mixed chapters, results at the end';
  static const String bookmarkedQuestions = 'Bookmarked Questions';
  static const String bookmarkedQuestionsDesc = 'Practice your saved questions';

  // Practice progress (topic practice skips questions answered correctly).
  static String allAnsweredCorrectly(int count) =>
      'All $count questions answered correctly';
  static const String allAnsweredCorrectlyMessage =
      'You have answered every question in this topic correctly.';
  static const String practiceAllAgain = 'Practice all again';
  static String practiceLeft(int left, int total) => '$left left of $total';
  static String practiceAllCorrect(int total) => 'All $total correct ✓';

  // Results & analytics.
  static const String resultsAndAnalytics = 'Results & Analytics';
  static const String quizResults = 'Quiz Results';
  static const String latestMockScore = 'Latest Score';
  static const String accuracyByChapter = 'Accuracy by Chapter';
  static const String topicsToReview = 'Topics to Review';
  static const String recommendations = 'Recommendations';
  static const String totalQuestions = 'Total';
  static const String unanswered = 'Unanswered';
  static const String accuracy = 'Accuracy';
  static const String timeTaken = 'Time Taken';
  static const String avgTimePerQuestion = 'Avg / Question';
  static const String topicPerformance = 'Topic Performance';
  static const String backToHome = 'Back to Home';

  // Flashcards.
  static const String flashcards = 'Flashcards';
  static const String tapToReveal = 'Tap to Reveal Answer';
  static const String tapToFlipBack = 'Tap to Flip Back';
  static const String hard = 'Hard';
  static const String good = 'Good';
  static const String easy = 'Easy';
  static const String allCaughtUp = 'All caught up!';
  static const String noCardsDue =
      'No flashcards due for review. Come back later or study some theory.';
  static const String startReview = 'Start Review';
  static const String cardsDue = 'cards due';

  // Formulas / bookmarks / search.
  static const String formulaCheatsheet = 'Formula Cheatsheet';
  static const String bookmarks = 'Bookmarks';
  static const String search = 'Search';
  static const String searchHint = 'Search topics, formulas, questions...';
  static const String noResults = 'No results found';
  static const String noBookmarks = 'Nothing bookmarked yet';
  static const String noBookmarksMessage =
      'Bookmark questions, formulas and topics to find them here.';

  // Generic states.
  static const String loading = 'Loading...';
  static const String somethingWentWrong = 'Something went wrong';
  static const String contentUnavailable =
      "Couldn't load the study content. Check your internet connection "
      'and try again.';
  static const String retry = 'Retry';
  static const String noData = 'Nothing here yet';
  static const String takeFirstQuiz =
      'Take your first quiz to unlock analytics and recommendations.';
  static const String startQuiz = 'Start Quiz';
  static const String topics = 'Topics';
  static const String subtopics = 'Subtopics';
  static const String mcqs = 'MCQs';
  static const String questions = 'Questions';
  static const String theory = 'Theory';
  static const String dayStreak = 'Day Streak';
}
