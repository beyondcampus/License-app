# Progress Tracker

Updated at the end of every phase. Gate = `flutter analyze` clean + `flutter test` green
+ phase-specific checks (see 04-phase-plan.md / 05-testing-and-verification.md).

| Phase | Description | Status | Gate result |
|---|---|---|---|
| 0 | Environment & scaffold | ✅ done | pub get OK (all packages resolve on Flutter 3.47.4); analyze: 0 issues |
| 1 | Design system & core widgets | ✅ done | analyze: 0 issues; tests 8/8 green (both themes, LaTeX fallback) |
| 2 | App shell & navigation | ✅ done | analyze: 0; tests 12/12 (tabs, theme toggle+persist, dashboard) |
| 3 | Data layer & sample content | ✅ done | analyze: 0; tests 30/30 (content integrity, repos on ffi SQLite, streak) |
| 4 | Theory/study system | ✅ done | analyze: 0; tests 34/34 (reader tabs, LaTeX/code blocks, progress+bookmark persist) |
| 5 | Quiz engine & modes | ✅ done | analyze: 0; tests 47/47 (session unit tests, full quiz flow, 4 modes, exit dialog, countdown) |
| 6 | Results & analytics | ✅ done | analyze: 0; tests 53/53 (weak-topic detection, generated recommendations, chart, stats tab) |
| 7 | Flashcards & spaced repetition | ✅ done | analyze: 0; tests 62/62 (SR determinism, flip+grade flow, persistence) |
| 8 | Formulas, search & bookmarks | ✅ done | analyze: 0; tests 69/69 (search units, formula sheet filters+bookmark, grouped bookmarks, bookmarked quiz) |
| 9 | AdMob | ✅ done | analyze: 0; tests 73/73 (cooldown gate units, off-platform no-ops); manifest test app id + minSdk 23 |
| 10 | Persistence & edge cases | ✅ done | analyze: 0; tests 79/79. Found+fixed 2 narrow-screen overflows (SectionHeader, quiz header) |
| 11 | Final audit & README | ✅ done | pub get ✓, analyze 0 ✓, tests 79/79 ✓, **apk --debug built ✓**, appbundle --debug built ✓ |

## Log

### 2026-09-14 — Planning + Phase 0 start
- Read prompt.md + UI desigb.html; wrote full plan set (00–06).
- Environment: no Flutter/Android SDK found. Installed Flutter stable 3.47.4
  (Dart 3.13.3) to `C:\flutter` via git clone.
- No Android SDK/JDK17 on machine → APK build documented as external step;
  verification via analyze + tests (see 06-risks).
- Disabled sleep on AC per user request (`powercfg /change standby-timeout-ac 0`;
  restore: `powercfg /change standby-timeout-ac 20`).

### 2026-09-15 — Phase 11 (final audit) — PROJECT COMPLETE
- Installed JDK 17 (`C:\java\jdk-17.0.20.1+1`) and Android SDK (`C:\Android`,
  platform 36 + build-tools 36.0.0) so the Stage-12 build could run for real.
- Build fixes: `google_mobile_ads` 6.0.0 is incompatible with modern Gradle →
  upgraded to ^9.1.0 (API source-compatible, analyze+tests stayed green);
  `kotlin.incremental=false` added to gradle.properties (Windows cache-close flake).
- Final gate: `flutter pub get` ✓ · `flutter analyze` 0 issues ✓ ·
  `flutter test` 79/79 ✓ · `flutter build apk --debug` ✓ (160.5 MB) ·
  `flutter build appbundle --debug` ✓.
- Audits: no TODO/FIXME in lib/, no raw print(), no network imports; README written.
- Restored AC sleep timeout to its previous 20 minutes.

### 2026-09-15 — Phases 4–10
- P4 theory: reader with 3 tabs and 9 block renderers; progress + streak wired.
- P5 quiz: pure-Dart QuizSession (locking, scoring, per-question ms timing),
  4 modes, exit dialog, timer; results handoff.
- P6 analytics: attempts-derived weak topics + generated recommendations,
  chapter bar chart; results screen topic breakdown.
- P7 flashcards: 3D flip, Hard/Good/Easy SR persisted in SQLite.
- P8 formulas/search/bookmarks screens + dashboard quick actions row 2.
- P9 AdMob: AdManager + InterstitialGate (3-min cooldown, session cap 5),
  banner slots (dashboard/theory/results), test ids marked `PROD:`,
  manifest test app id, minSdk 23, platform-guarded (no-op in tests/desktop).
- P10 edge cases: malformed-JSON tolerance test, restart persistence test,
  timer-zero auto-finish test, caught-up flashcards, empty bookmarks,
  320×568 no-overflow sweep. Bugs found & fixed: SectionHeader and quiz
  header rows overflowed on narrow screens (missing Expanded).

### Phase 3 notes
- Content shipped: 3 chapters, 35 topics, 78 MCQs, 28 formulas, 30 flashcards,
  theory blocks for all 35 topics (12 in depth). Integrity enforced by tests.
- Test infra gotchas solved (documented for future phases):
  1. Widget tests must use `databaseFactoryFfiNoIsolate` — isolate responses
     never arrive under the fake-async clock.
  2. `DatabaseHelper` opens with `singleInstance: false` for override paths so
     tests don't inherit a stale cached connection.
  3. `pumpApp` warms the asset cache inside `tester.runAsync` — rootBundle disk
     reads also don't complete under fake-async.
