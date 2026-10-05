# Master Phase Plan (with verification gates)

Maps prompt.md's 12 stages onto 12 executable phases. **A phase is complete only when
its verification gate passes.** Gate baseline for every phase from P2 onward:
`flutter analyze` → 0 issues, `flutter test` → all pass.

---

## Phase 0 — Environment & Project Scaffold
**Covers:** tooling prerequisite (not a prompt stage).
- Install Flutter stable to `C:\flutter` (git clone + first-run Dart SDK). ✔ started
- `flutter doctor`; `flutter create` the app (org `com.maitri.examprep`, project
  `exam_prep_pro`) into the workspace; keep `plan/`, `prompt.md`, `UI desigb.html`.
- Write `pubspec.yaml` deps: provider, sqflite, path, shared_preferences,
  flutter_math_fork, flutter_highlight, google_mobile_ads; dev: flutter_lints,
  sqflite_common_ffi (tests). Run `flutter pub get`.
**Gate:** `flutter pub get` succeeds; template app passes `flutter analyze`.

## Phase 1 — Design System & Core Widgets (Stage 1 + part of 3)
- `core/constants` (colors incl. ThemeExtension, constants, strings),
  `core/theme` (M3 light + dark from 01-design-system.md), `core/utils`.
- Core widgets: AppCard, AppProgressBar, AppTabGroup, OptionButton, CodeBlock,
  FormulaBlock, ExplanationBox, StreakBadge, TimerBadge, Primary/SecondaryButton,
  SectionHeader, EmptyState, LoadingIndicator, ErrorState, AdBannerSlot (stub for now).
**Gate:** analyze clean; widget smoke tests for tokens + key widgets in both themes.

## Phase 2 — App Shell & Navigation (Stages 2–3)
- `main.dart` bootstrap, MultiProvider wiring (stubs where data layer pending),
  ThemeProvider (persisted), `routes/app_router.dart`.
- RootShell with IndexedStack + 5-tab bottom nav; Dashboard screen (app bar with
  avatar/streak/theme toggle, readiness card, subject cards); placeholder tab bodies
  where features are later phases.
**Gate:** analyze + tests; widget test: app boots, bottom nav switches tabs,
dashboard renders 3 subject cards, dark/light toggle works.

## Phase 3 — Data Layer & Sample Content (Stage 4 + sample-data requirement)
- All 6 JSON assets with full sample content per 03-data-and-content.md.
- Models, AssetContentSource, DatabaseHelper (sqflite, schema v1), PrefsService,
  all repositories. Wire real repositories into providers; dashboard shows real
  chapter data, streak logic live.
**Gate:** analyze + unit tests: JSON parses to models (all entries), repository CRUD
via sqflite_common_ffi, streak logic, malformed-JSON resilience.

## Phase 4 — Theory/Study System (Stage 5)
- Chapter list (Chapters tab), topic list screen (progress, badges, MCQ count),
  theory reader (Concepts/Formulas/Notes tabs, all TheoryBlock renderers, LaTeX,
  code highlight), topic-complete tracking, floating actions (Practice this topic /
  Formula sheet), theory bookmark toggle.
**Gate:** analyze + widget tests: navigate chapter→topic→reader, tabs switch,
LaTeX + code render, progress persists (fake prefs/db).

## Phase 5 — MCQ/Quiz Engine (Stage 6 + quiz modes)
- QuizSession (pure Dart), QuizProvider with timer, quiz setup screen (Practice tab),
  quiz screen per HTML (counter, timer, options with correct/incorrect states,
  explanation, bookmark, prev/next, finish, restart), exit confirmation,
  4 modes (practice/timed/mock/bookmarked), answer locking.
**Gate:** analyze + tests: QuizSession scoring/locking/timer-expiry unit tests;
widget test: full practice quiz run through results handoff.

## Phase 6 — Results & Analytics (Stage 7)
- Results persisted (results + attempts), results screen (score, accuracy, time,
  avg time/question, per-topic breakdown), Stats tab: latest score card,
  accuracy-by-chapter bar chart, weak topics, generated recommendations.
**Gate:** analyze + tests: aggregation math, weak-topic detection, recommendation
generation from seeded attempts; widget test for results + analytics screens.

## Phase 7 — Flashcards & Spaced Repetition (Stage 8)
- Cards tab: due queue, flip animation, Hard/Good/Easy with computed interval labels,
  SR scheduler (per 02-architecture.md), persistence, "all caught up" empty state.
**Gate:** analyze + tests: scheduler determinism (fixed clock), persistence round-trip;
widget test: flip + grade advances queue.

## Phase 8 — Formulas, Search & Bookmarks (Stage 9)
- Formula cheatsheet (chapter tabs + search field, LaTeX cards, bookmark),
  global Search screen (chapters/topics/theory/formulas/questions),
  Bookmarks screen (grouped: questions/formulas/topics), duplicate-bookmark guard.
**Gate:** analyze + tests: search ranking/filtering units, bookmark uniqueness &
persistence; widget tests for the three screens incl. empty states.

## Phase 9 — AdMob (Stage 10)
- google_mobile_ads with **test IDs** (`// PROD: replace`), AdManager (init, banner,
  interstitial, 3-min cooldown, failure handling), banners on dashboard/theory/results,
  interstitial post-quiz, platform guards so tests/desktop skip plugin calls.
**Gate:** analyze + tests: cooldown logic unit test (injected clock); widget tests
still green (slots collapse in test env); Android manifest has test App ID.

## Phase 10 — Persistence, Offline & Edge Cases (Stage 11)
- Harden every Stage-11 case: first launch, empty everything, quiz interruption,
  restart, theme change, empty search, missing snippets/formulas, invalid JSON,
  timer-zero, duplicate bookmarks, ad failure. Add error boundaries so no feature
  exception crashes the app.
**Gate:** analyze + dedicated edge-case test suite green.

## Phase 11 — Final Audit (Stage 12 + UI quality audit)
- `flutter pub get`, `flutter analyze`, `flutter test` — all clean, fix & re-run loop.
- `flutter build apk --debug` **documented caveat:** no Android SDK on this machine;
  ensure Gradle/manifest config is correct by inspection + `flutter build` config checks.
- UI audit pass per prompt checklist (overflow tests at small sizes via widget tests
  with constrained viewports; theme audit; long-text scroll).
- Write final README (run instructions, prod-ID replacement, extension guide).
**Gate:** all checks clean; PROGRESS.md finalized.

---

## Working rules (apply to every phase)
1. Never move on with analyzer errors or failing tests.
2. Update [PROGRESS.md](PROGRESS.md) at each phase end: what was built, files, decisions,
   problems found & fixed, gate results.
3. No `// TODO` on required functionality; no fake implementations.
4. Each feature guards against its own failures (offline-first, crash-free).
