# Stage 2 — Flutter Architecture

Clean Architecture, feature-first, **Provider** only. UI ⇢ providers (state) ⇢
repositories (data) ⇢ sources (asset JSON / SQLite / SharedPreferences).

## Folder structure
```
lib/
├── main.dart                       (init: prefs, DB, ads → MultiProvider → App)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         (palette + AppColorsExtension ThemeExtension)
│   │   ├── app_constants.dart      (durations, quiz sizes, ad cooldown, SR intervals)
│   │   └── app_strings.dart
│   ├── theme/
│   │   ├── app_theme.dart          (buildLight/buildDark, typography, spacing, radius)
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   ├── utils/
│   │   ├── date_utils.dart         (streak logic, day diffs)
│   │   ├── math_utils.dart         (percentages, formatting)
│   │   └── validators.dart         (JSON guards)
│   └── widgets/                    (see component inventory in 01-design-system.md)
├── features/
│   ├── dashboard/   (presentation, state: DashboardProvider — streak, readiness)
│   ├── chapters/    (data, domain, presentation, state: ChapterProvider)
│   ├── theory/      (data, domain, presentation, state: TheoryProvider)
│   ├── quiz/        (data, domain, presentation, state: QuizProvider + QuizSession)
│   ├── analytics/   (data, domain, presentation, state: AnalyticsProvider)
│   ├── flashcards/  (data, domain, presentation, state: FlashcardProvider)
│   ├── formulas/    (data, domain, presentation: FormulaProvider)
│   ├── bookmarks/   (data, domain, presentation: BookmarkProvider)
│   ├── search/      (presentation, state: SearchProvider — queries repositories)
│   └── ads/
│       ├── ad_manager.dart         (init, banner factory, interstitial + cooldown)
│       └── widgets/ad_banner_slot.dart
└── routes/
    └── app_router.dart             (named routes + onGenerateRoute, typed args)
```

## Data sources
1. **Asset JSON** (read-only content): `assets/data/*.json`, loaded once via
   `AssetContentSource` (rootBundle), cached in memory, validated defensively
   (bad entry → skipped + logged, never crashes).
2. **SQLite** (`sqflite`, `DatabaseHelper` singleton, versioned schema) for
   user-generated data:
   - `quiz_results(id, mode, chapter_id, topic_ids, total, correct, incorrect,
     unanswered, time_seconds, taken_at)`
   - `question_attempts(id, result_id, question_id, topic_id, chapter_id,
     selected_index, is_correct, time_ms)`
   - `bookmarks(id, item_type, item_id, created_at)` — UNIQUE(item_type, item_id)
   - `flashcard_reviews(card_id PK, ease, interval_days, due_date, review_count,
     last_reviewed_at)`
   - `topic_progress(topic_id PK, completed, completion_pct, last_studied_at)`
3. **SharedPreferences** (`PrefsService`): themeMode, streakCount, lastStudyDate,
   onboarding flags, quiz defaults.

## Repositories (abstract class + impl, injected via Provider)
`ChapterRepository`, `TheoryRepository`, `QuestionRepository`, `FormulaRepository`,
`FlashcardRepository`, `BookmarkRepository`, `ProgressRepository` (topic progress +
streak + readiness), `ResultsRepository` (quiz results + attempts + aggregates).

## Domain models (immutable, manual fromJson/toJson)
`Chapter`, `Topic`, `TheoryContent` (list of `TheoryBlock`s — heading, paragraph,
bulletList, formula(LaTeX), code(language), table, note, warning, examTip),
`Formula`, `Question`, `QuizResult`, `QuestionAttempt`, `Bookmark`,
`Flashcard`, `FlashcardReview`, `TopicPerformance`, `UserProgress`.

## State management
- `MultiProvider` at root: services (prefs, db) → repositories → ChangeNotifier providers.
- `ThemeProvider` (mode), `DashboardProvider`, `ChapterProvider`, `TheoryProvider`,
  `QuizProvider` (owns a `QuizSession` object: questions, index, answers, timer,
  mode; disposes its `Timer` correctly), `AnalyticsProvider`, `FlashcardProvider`,
  `BookmarkProvider`, `FormulaProvider`, `SearchProvider`.
- Providers created lazily; screens use `context.watch/select` to limit rebuilds.

## Quiz engine design
`QuizMode { practice, timed, mock, bookmarked }`
- `QuizSession` is pure Dart (unit-testable): holds question list, answers map,
  submission state, elapsed/remaining time, scoring, per-topic tally.
- Practice: immediate feedback after submit, answer locked afterwards.
- Timed: per-quiz countdown (`AppConstants.timedSecondsPerQuestion × n`); zero → auto-finish.
- Mock: cross-chapter question sampling, results at the end only.
- Bookmarked: sourced from BookmarkRepository.
- Finish → persist `QuizResult` + attempts → results screen → interstitial (cooldown-gated).

## Spaced repetition (deterministic)
Stored per card in `flashcard_reviews`:
- Hard → interval = 1 day, ease −0.15 (floor 1.3)
- Good → interval = max(1, round(interval × ease)), initial 3 days
- Easy → interval = max(4, round(interval × ease × 1.5)), ease +0.15 (cap 2.8)
- `due = today + interval`. Review queue = cards with due ≤ today (new cards first-seen
  are due immediately). Deterministic, persisted, restart-safe.

## Recommendations (computed, never hardcoded)
`AnalyticsProvider` aggregates `question_attempts` per topic →
`TopicPerformance(topicId, attempted, correct, accuracy)`. Weak = accuracy < 60%
with ≥ N attempts (N=4). Recommendation strings are generated from the weakest
topics' names/chapters, e.g. "Focus on K-Maps and 8086 Addressing Modes before your
next mock test." Empty history → friendly "take a quiz first" empty state.

## AdManager
- `google_mobile_ads`, **Google test IDs only**, `// PROD: replace` markers.
- Banner slots on dashboard, theory reader, results; slot renders `SizedBox.shrink`
  on load failure or on unsupported platforms (guard `Platform.isAndroid/isIOS` so
  tests/desktop never touch the plugin).
- Interstitial after quiz completion with a 3-minute cooldown + max frequency guard.
- All ad failures are swallowed and logged; app never blocks on ads.

## Navigation map
```
RootShell (IndexedStack + bottom nav): Home | Chapters | Practice | Stats | Cards
push: /topics (chapter) → /theory (topic) → /quiz (config) → /results (result)
push: /formulas, /bookmarks, /search
```
Quiz screen wraps `PopScope` with exit-confirmation dialog.
