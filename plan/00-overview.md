# ExamPrep Pro — Project Overview

## What we are building
A complete, production-ready, **offline-first Flutter app** for engineering board-exam
preparation, covering:

- **Chapter 1 — Basic Electrical & EDC**
- **Chapter 2 — Digital Logic & Microprocessors**
- **Chapter 3 — C/C++ Programming**

The supplied `UI desigb.html` ("ExamPrep Pro — Interactive Prototype") is the **visual
source of truth**. It is a design reference only — the app is rebuilt natively in Flutter,
never embedded as a WebView.

## Hard requirements (from prompt.md)
1. **100% offline** — no REST, Firebase, Supabase, remote JSON, or network content.
   All study content bundled as local JSON assets; user data in SQLite + SharedPreferences.
2. **Clean Architecture, feature-first** folder layout, **Provider** for state management.
3. Material 3, **light + dark themes** (dark derived directly from the HTML palette).
4. Features: dashboard, chapters → topics → theory reader (Concepts/Formulas/Notes tabs),
   MCQ engine (practice / timed / mock / bookmarked modes), results & analytics with
   data-driven weak-topic recommendations, flashcards with spaced repetition,
   searchable formula cheatsheet, bookmarks, AdMob (test IDs, with cooldown).
5. LaTeX via `flutter_math_fork`, code highlighting via `flutter_highlight`.
6. Meaningful sample content for all three chapters (enough to exercise every feature).
7. Final audit: `flutter pub get`, `flutter analyze`, `flutter test` must be clean.
   (`flutter build apk` requires the Android SDK — see environment constraints below.)

## Environment constraints (this machine)
- Windows 11, no Flutter SDK pre-installed → **we install Flutter (stable) to `C:\flutter`
  via git clone** as Phase 0.
- **No Android SDK / modern JDK** on this machine → `flutter build apk` cannot run here.
  Verification gates therefore rely on `flutter analyze` + `flutter test` + widget tests,
  which fully validate compilation and logic. The APK build step is documented for a
  machine with Android tooling; the project is structured so it builds without changes.
- No physical device/emulator → runtime verification is done through **widget tests**
  that pump real screens (navigation, quiz flow, flashcards, etc.).

## Deliverable layout
```
license_app/
├── plan/                  ← this planning folder
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/              (constants, theme, utils, shared widgets)
│   ├── features/          (dashboard, chapters, theory, quiz, analytics,
│   │                       flashcards, formulas, bookmarks, search, ads)
│   └── routes/
├── assets/data/           (chapters, topics, theory, questions, formulas, flashcards JSON)
├── test/                  (unit + widget tests)
└── android/ ios/ ...      (platform scaffolding via `flutter create`)
```

## Plan documents
| File | Contents |
|------|----------|
| [01-design-system.md](01-design-system.md) | Stage 1 output: HTML analysis, design tokens, component & screen inventory, HTML→Flutter mapping |
| [02-architecture.md](02-architecture.md) | Stage 2: folder structure, models, repositories, providers, navigation |
| [03-data-and-content.md](03-data-and-content.md) | JSON schemas + sample-content plan per chapter |
| [04-phase-plan.md](04-phase-plan.md) | **The master phase-wise implementation plan with verification gates** |
| [05-testing-and-verification.md](05-testing-and-verification.md) | Per-phase test strategy and checklists |
| [06-risks-and-mitigations.md](06-risks-and-mitigations.md) | Known risks, edge cases, fallback decisions |
| [PROGRESS.md](PROGRESS.md) | Live tracker — updated at the end of every phase |
