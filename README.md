# ExamPrep Pro

An **online Flutter app** for engineering board/licensing exam preparation,
covering:

- **Chapter 1 — Basic Electrical & EDC** (12 topics)
- **Chapter 2 — Digital Logic & Microprocessors** (12 topics)
- **Chapter 3 — C & C++ Programming** (11 topics)

Built with Clean Architecture (feature-first) + Provider and Material 3 with light
and dark themes. **All study content lives in Supabase** and is rendered from
there — the app bundle ships none. The visual design follows the supplied HTML
prototype (`UI desigb.html`).

## Features

| Area | What you get |
|---|---|
| **Dashboard** | Overall readiness, daily streak (🔥), subject modules, quick actions, theme toggle |
| **Study** | Chapter → topic → theory reader with **Concepts / Formulas / Notes** tabs, LaTeX math (`flutter_math_fork`), highlighted C/C++/assembly code (`flutter_highlight`), tables, notes, warnings, exam tips, per-topic progress and completion |
| **Quiz engine** | 4 modes — Practice (instant feedback), Timed Test (countdown), Mock Exam (mixed chapters), Bookmarked. Answer locking, explanations, code/LaTeX in questions, bookmark, prev/next, exit confirmation, auto-submit at 0:00 |
| **Results & analytics** | Score, accuracy, time, avg time/question, per-topic breakdown, accuracy-by-chapter chart, weak-topic detection and **recommendations generated from your stored answers** (never hardcoded) |
| **Flashcards** | 30 cards, 3D flip animation, Hard/Good/Easy grading with a deterministic, persistent spaced-repetition scheduler |
| **Formulas** | Searchable LaTeX cheatsheet grouped by chapter, bookmarkable |
| **Search** | Search across chapters, topics, theory, formulas and questions |
| **Bookmarks** | Questions, formulas and topics; survive restarts; duplicates impossible (SQLite unique index) |
| **Ads** | AdMob banners (dashboard/theory/results) + post-quiz interstitial with a 3-minute cooldown and session cap. **Test ad ids** — search for `PROD:` to find every id to replace. The app is fully functional if ads fail or never load |

## Content

Chapters, topics, theory, MCQs, formulas and flashcards are rows in Supabase
(`chapters`, `topics`, `theory_content`, `questions` + `question_options`,
`formulas`, `flashcards`). Authoring sources live in `supabase/content/` and
are applied with the scripts in `tools/`. The app fetches the content after
sign-in and keeps a local copy for up to 6 hours for speed; if it can't reach
Supabase and has no copy, each screen shows an error with **Retry**.

`test/fixtures/content/*.json` is a snapshot of the Supabase content that the
tests run on — refresh it with `node tools/export_supabase_assets.js`.

## Getting started

```bash
flutter pub get
flutter run          # Android device/emulator
```

Requirements: Flutter 3.35+ (developed on 3.47 / Dart 3.13), Android SDK
(minSdk 23 — required by google_mobile_ads).

### Verify

```bash
flutter analyze      # 0 issues
flutter test         # ~80 unit + widget tests, all green
flutter build apk --debug
```

## Architecture

```
lib/
├── main.dart                  # runZonedGuarded bootstrap, MultiProvider wiring
├── core/
│   ├── constants/             # AppColors (+ ThemeExtension), constants, strings
│   ├── theme/                 # Material 3 light/dark from the HTML design tokens
│   ├── services/              # ContentSource + SupabaseContentSource, ContentCache,
│   │                          # DatabaseHelper (sqflite), PrefsService,
│   │                          # AppDependencies (composition root)
│   ├── utils/                 # date/math/JSON helpers
│   └── widgets/               # AppCard, AppTabGroup, OptionButton, CodeBlock,
│                              # FormulaBlock, badges, buttons, states, bottom nav
├── features/                  # feature-first: data / domain / presentation / state
│   ├── dashboard/  chapters/  theory/  quiz/  analytics/
│   ├── flashcards/ formulas/  bookmarks/ search/  ads/
│   └── shell/                 # RootShell (IndexedStack + bottom nav)
└── routes/app_router.dart     # centralized typed routes
```

- **Content** (read-only) is fetched from Supabase and parsed defensively —
  malformed rows are skipped, the app never crashes on bad content.
- **User data** lives in SQLite (`quiz_results`, `question_attempts`,
  `bookmarks`, `flashcard_reviews`, `topic_progress`) and SharedPreferences
  (theme, streak, quiz length).
- **State** is Provider throughout: app-level providers (theme, chapters,
  analytics, flashcards) plus screen-scoped providers (theory, quiz, search).

## Spaced repetition

Deterministic and persisted per card: Hard → 1 day (ease −0.15, floor 1.3);
Good → first 3 days, then interval × ease; Easy → interval × ease × 1.5
(min 4 days, ease +0.15, cap 2.8). Due = review date + interval.

## Adding content

1. Write the chapter's content under `supabase/content/` and check it with
   `node tools/validate_content.js <chN> --strict`.
2. Apply it to Supabase with `node tools/apply_content.js <chN>` (needs
   `SUPABASE_SERVICE_ROLE_KEY` in the environment).
3. Done — every screen (dashboard, chapters, quiz modes, formula tabs, search,
   analytics) derives from the Supabase content. Refresh the test snapshot
   (`node tools/export_supabase_assets.js`); `content_source_test.dart`
   enforces referential integrity on it.

## Release checklist

- Replace every `PROD:` marked AdMob id (`lib/features/ads/ad_manager.dart`,
  `android/app/src/main/AndroidManifest.xml`).
- Set a real `applicationId` signing config in `android/app/build.gradle.kts`.
- `flutter build appbundle --release`.

## Planning docs

The `plan/` folder contains the full phase-wise plan, design-token extraction
from the HTML reference, architecture decisions, test strategy, risk register
and the per-phase progress log with gate results.
