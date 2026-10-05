# Risks, Edge Cases & Mitigations

## Environment risks
| Risk | Impact | Mitigation |
|---|---|---|
| No Android SDK/JDK on this machine | `flutter build apk` can't run locally | Gates use analyze+test (full compile check via test builds). Android config verified by inspection; README documents the build step for a tooled machine. |
| Flutter 3.47 is very new — package incompatibility (esp. `flutter_math_fork`, `flutter_highlight`) | pub get / analyze failures | Verify at Phase 0 pub get. Fallbacks: `flutter_math_fork` → latest fork or render formulas with styled mono text via our `FormulaBlock` abstraction (single point of change); `flutter_highlight` → `highlight` core + own renderer, or `syntax_highlight` package. The widget wrappers (`FormulaBlock`, `CodeBlock`) isolate the dependency so swapping costs one file. |
| `google_mobile_ads` needs Android embedding config | analyze/test breakage on desktop | AdManager is platform-guarded; plugin never invoked in tests. Manifest gets Google's test App ID. |
| Laptop sleep interrupting long runs | lost progress | AC sleep disabled (`powercfg`); restore with `powercfg /change standby-timeout-ac 20`. All state is on disk; every phase ends committed to files. |

## Technical edge cases (Stage 11 checklist → owner)
| Case | Handling |
|---|---|
| First launch / empty progress | Defaults (0%, streak 0) seeded by PrefsService; friendly empty states |
| No bookmarks / no history / no due flashcards | Dedicated `EmptyState` per screen with CTA |
| Quiz interruption (back/kill) | Exit dialog; unfinished sessions are discarded by design (documented); timer disposed in provider `dispose()` |
| App restart | All persistence via SQLite/prefs; providers rehydrate on start |
| Theme change | ThemeExtension-driven colors everywhere; no hardcoded brightness branches in widgets |
| Empty search results | EmptyState with query echo |
| Missing optional codeSnippet/formula | Nullable model fields; renderers skip null |
| Invalid local JSON | Per-entry try/catch: bad entries skipped + debug log; whole-file failure → ErrorState screen section, app keeps running |
| Timer reaching zero | Auto-submit + navigate to results (tested) |
| Duplicate bookmarks | SQLite UNIQUE + INSERT OR IGNORE |
| Ad load failure | Slot collapses; interstitial silently skipped; retries capped |
| Exception isolation | try/catch at repository boundaries; `runZonedGuarded` + FlutterError handler logs instead of crashing |

## Content risks
- LaTeX strings must be valid for flutter_math_fork → every formula also carries
  `plainText`; renderer falls back on parse error (onErrorFallback).
- IDs referenced by SQLite rows must stay stable → content_source_test enforces
  referential integrity so future content edits fail tests, not users.

## Scope guards
- No extra packages beyond pubspec list unless a gate genuinely requires one.
- No feature creep beyond prompt.md; extension points (Chapters 4+) documented in README.
