# Testing & Verification Plan

## Tooling
- `flutter analyze` — zero errors/warnings tolerated at every gate.
- `flutter test` — unit + widget tests; sqflite backed by `sqflite_common_ffi`
  in tests (in-memory DB), SharedPreferences via `SharedPreferences.setMockInitialValues`.
- Ads: `AdBannerSlot`/`AdManager` no-op off Android/iOS → tests never touch the plugin.
- Widget tests pump real screens with real providers over test doubles
  (in-memory DB + mock prefs + real asset JSON via `flutter_test` asset bundle).

## Test inventory by area

### Unit tests
| Suite | Verifies |
|---|---|
| `models_test` | fromJson/toJson round-trips for every model; tolerant parsing (missing optionals, wrong types skipped) |
| `content_source_test` | all 6 asset JSONs load, counts ≥ targets in 03-data-and-content.md, referential integrity (topic.chapterId exists, question.topicId exists, correctIndex in range) |
| `quiz_session_test` | answer locking after submit, scoring, accuracy, unanswered, per-topic tally, timer expiry auto-finish, restart resets |
| `spaced_repetition_test` | Hard/Good/Easy interval math with fixed clock, determinism, ease bounds |
| `analytics_test` | per-topic accuracy aggregation, weak-topic threshold, recommendation text generated from seeded data, empty-history behavior |
| `streak_test` | same-day no-op, consecutive-day increment, gap reset |
| `bookmark_repo_test` | add/remove/list, duplicate insert is idempotent, persists across repo re-instantiation (same DB) |
| `results_repo_test` | save result + attempts, query latest, aggregates |
| `search_test` | matches across all 5 content types, case-insensitive, empty query, no-results |
| `ad_cooldown_test` | interstitial gate honors cooldown with injected clock |

### Widget tests
| Suite | Verifies |
|---|---|
| `app_shell_test` | boots, 5 tabs switch, theme toggle flips brightness |
| `dashboard_test` | readiness card, 3 subject cards, streak badge, navigation to chapters |
| `theory_flow_test` | chapter→topic→reader navigation, 3 tabs, LaTeX widget present, code block present, back nav |
| `quiz_flow_test` | start practice quiz, select option, correct/incorrect visuals (icon+color), explanation shows, answer locked, finish → results |
| `timed_quiz_test` | countdown shows, zero → auto-finish |
| `results_analytics_test` | score numbers correct, chart bars, recommendations shown |
| `flashcards_test` | card flips, grading advances, empty-queue state |
| `formulas_bookmarks_search_test` | chapter tabs filter, search filters, bookmark toggle persists, empty states |
| `edge_cases_test` | first-launch empty states, malformed JSON asset injection doesn't crash, small-viewport (320×568) no-overflow pump of major screens |

## Manual/inspection checks (no emulator on this machine)
- Android config review: manifest AdMob test App ID, min/target SDK, INTERNET permission
  (needed by AdMob only), asset declarations.
- UI audit vs HTML: side-by-side token check (colors/radius/spacing/typography).
- Grep audits: no `TODO` in lib/, no `http`/network imports, no `print` in release paths.

## Per-phase gate = analyze clean + all tests green + that phase's suites added.
