import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/analytics/data/results_repository.dart';
import '../../features/bookmarks/data/bookmark_repository.dart';
import '../../features/chapters/data/chapter_repository.dart';
import '../../features/chapters/data/progress_repository.dart';
import '../../features/flashcards/data/flashcard_repository.dart';
import '../../features/formulas/data/formula_repository.dart';
import '../../features/quiz/data/practice_progress_repository.dart';
import '../../features/quiz/data/question_repository.dart';
import '../../features/theory/data/theory_repository.dart';
import '../../features/streak/streak_service.dart';
import 'content_cache.dart';
import 'content_source.dart';
import 'database_helper.dart';
import 'prefs_service.dart';
import 'supabase_content_source.dart';

/// Composition root: constructs the data sources and repositories once.
///
/// All study content comes from Supabase. Tests build this with an
/// in-memory database path, mock preferences and a [contentBackend] serving
/// fixtures in place of Supabase.
class AppDependencies {
  AppDependencies({
    required this.prefs,
    String? dbPath,
    this.supabaseClient,
    ContentBackend? contentBackend,
  }) : dbHelper = DatabaseHelper(overridePath: dbPath) {
    contentCache = ContentCache(dbHelper);
    if (contentBackend == null && supabaseClient == null) {
      throw ArgumentError(
        'Study content is served from Supabase: pass a supabaseClient.',
      );
    }
    contentSource = ContentSource(
      contentBackend ?? SupabaseContentSource(supabaseClient!, contentCache),
    );
    chapterRepository = ChapterRepositoryImpl(contentSource);
    theoryRepository = TheoryRepositoryImpl(contentSource);
    questionRepository = QuestionRepositoryImpl(contentSource);
    formulaRepository = FormulaRepositoryImpl(contentSource);
    flashcardRepository = FlashcardRepositoryImpl(contentSource, dbHelper);
    if (supabaseClient != null) {
      authRepository = AuthRepository(supabaseClient!);
      streakService = StreakService(supabaseClient!);
      bookmarkRepository = SupabaseBookmarkRepository(supabaseClient!);
      progressRepository = SupabaseProgressRepository(
        supabaseClient!,
        streakService!,
      );
      resultsRepository = SupabaseResultsRepository(supabaseClient!);
      practiceProgressRepository =
          SupabasePracticeProgressRepository(supabaseClient!);
    } else {
      bookmarkRepository = BookmarkRepositoryImpl(dbHelper);
      progressRepository = ProgressRepositoryImpl(dbHelper, prefs);
      resultsRepository = ResultsRepositoryImpl(dbHelper);
      practiceProgressRepository = PracticeProgressRepositoryImpl(dbHelper);
    }
    // Ads disabled temporarily.
    // adManager = AdManager();
  }

  final PrefsService prefs;
  final SupabaseClient? supabaseClient;
  late final ContentSource contentSource;
  final DatabaseHelper dbHelper;
  late final ContentCache contentCache;

  AuthRepository? authRepository;
  StreakService? streakService;

  late final ChapterRepository chapterRepository;
  late final TheoryRepository theoryRepository;
  late final QuestionRepository questionRepository;
  late final FormulaRepository formulaRepository;
  late final FlashcardRepository flashcardRepository;
  late final BookmarkRepository bookmarkRepository;
  late final ResultsRepository resultsRepository;
  late final ProgressRepository progressRepository;
  late final PracticeProgressRepository practiceProgressRepository;
  // late final AdManager adManager;
}
