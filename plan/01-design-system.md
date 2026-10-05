# Stage 1 — HTML Inspection & Design System

Source: `UI desigb.html` ("ExamPrep Pro — Interactive Prototype"), a 380×780 phone-frame
prototype with 7 screens switched via JS. Dark theme only; light theme must be derived.

## 1. HTML UI analysis

### Page structure
- Phone frame → status bar → **screen** (app bar + scrollable content) → **bottom nav**
  (dashboard only) → **ad banner** (every screen, 48px, bottom).
- Content area: `padding: 16px`, vertical `gap: 16px`, scrollable.

### Screens in the prototype
1. **Dashboard** — profile app bar (avatar, app name, "Offline Mode" subtitle, 🔥 streak
   pill), "Overall Readiness" progress card, "Select Subject Module" section, 3 subject
   cards (emoji icon, name, meta line "12 Topics • 75 MCQs • Formula Sheet"), bottom nav
   (Home/Chapters/Practice/Stats/Cards), ad banner.
2. **Chapter list (topics)** — back app bar, Theory/Practice tab group, topic cards with
   title, subtitle, and progress bar.
3. **Theory reader** — back app bar + ❤️ bookmark, Concepts/Formulas/Notes tab group,
   content card (section title, paragraph, centered formula block, footnote), action row
   (secondary "Formula Sheet" + primary "Practice MCQs").
4. **MCQ practice** — back app bar + red timer badge "⏱ 28s", "Question 5 of 20 /
   Single Choice" row, question card containing question text, monospace code block,
   4 option rows (correct state = green tint + ✓), blue explanation box; action row
   (Bookmark / Next Question).
5. **Formula cheatsheet** — back app bar, Chapter 1/2/3 tab group, formula cards
   (muted title + centered dashed monospace formula block).
6. **Analytics** — centered score card ("18 / 20", green, "90% Accuracy Rate"),
   "Accuracy by Chapter" bar chart (3 colored bars), "Topics to Review" card with ⚠️ lines.
7. **Flashcards** — back app bar + "5 / 30" counter, tall (240px) centered flashcard
   (topic label in blue caps, question, "Tap to Reveal Answer"), Hard/Good/Easy button
   row (red/yellow/green) with interval sublabels.

### States present in HTML
Correct option (green), timer (red badge), progress fills at various %, active/inactive
tabs and nav items, ad placeholder. **Not present** (must be designed consistently):
incorrect option state (red tint + ✗), loading, empty, error states, light mode, modals
(exit-quiz confirmation), search field.

## 2. Extracted design tokens

### Colors (dark = source of truth)
| Token | Value | Usage |
|---|---|---|
| `scaffoldBackground` | `#0F172A` | screen bg (`--bg-color`) |
| `surface` / card | `#1E293B` | cards, app bar, tab group |
| `primary` (blue) | `#3B82F6` | active tabs/nav, buttons, progress fill, avatar |
| `success` (green) | `#22C55E` | correct answers, easy, score |
| `warning` (orange) | `#F97316` | streak, weak chapter bar |
| `error` (red) | `#EF4444` | hard button, incorrect (derived), timer base |
| `timerText` | `#F87171` | timer badge text on `rgba(239,68,68,.15)` |
| `yellow` | `#EAB308` | "Good" flashcard button |
| `textPrimary` | `#F8FAFC` | main text |
| `textSecondary` | `#94A3B8` | subtitles, meta |
| `border` | `#334155` | card borders, dividers, progress track |
| `codeBackground` | `#090D16` | code blocks, formula math blocks |
| `navBackground` | `#0B1329` | bottom nav |
| `correctText` | `#86EFAC` | text on correct option |
| `codeText` | `#A7F3D0` | code block text |
| `formulaText` | `#60A5FA` | formula math text |
| `explanationText` | `#93C5FD` | explanation box text |

Tinted fills used in HTML: correct `#22C55E @ 15%`, timer `#EF4444 @ 15%`,
explanation `#3B82F6 @ 10%`, streak `#F97316 @ 20%`.

### Light theme (derived, same hues)
Background `#F1F5F9`, surface `#FFFFFF`, border `#E2E8F0`, text `#0F172A` /
secondary `#64748B`, code bg `#F8FAFC` with dark code text, accents unchanged
(blue/green/orange/red read well on light). Tint fills keep the same alphas.

### Radius
| Token | px | Usage |
|---|---|---|
| `sm` | 6 | timer badge |
| `md` | 8 | code block, formula math, flash buttons, nav btn |
| `lg` | 10 | option buttons, primary/secondary buttons |
| `xl` | 12 | tab group, formula card (tab item inner = 9) |
| `xxl` | 16 | cards, subject cards |
| `flashcard` | 20 | flashcard |
| `pill` | 999 | streak badge, progress bar (4) |

### Spacing
Base unit 4. Screen padding 16, card padding 16 (formula card 12), list gap 16,
inner gaps 8–12, option padding 12, button padding 12 vertical.

### Typography (system font / Roboto default)
| Style | Size | Weight |
|---|---|---|
| Score display | 32 | bold |
| Flashcard question | 18 | bold |
| App bar title | 16 | 600 |
| Formula math | 16 | mono |
| Section title / subject name | 15 | 600 |
| Question text | 14 | 500 |
| Body / options / buttons | 13 | 400–500 |
| Meta / explanation / code / timer | 12 | varies |
| Caption / streak sub | 10–11 | — |

### Elevation
Mostly **flat + 1px border** style; flashcard gets a soft shadow
(`0 10px 15px -3px rgba(0,0,0,.3)`). Use elevation 0 with borders everywhere,
a themed shadow only on flashcards.

## 3. Flutter theme strategy
- Material 3, `ThemeData(useMaterial3: true)` with a hand-built `ColorScheme` for dark
  and light; **do not** use `ColorScheme.fromSeed` (it would drift from the HTML palette).
- `AppColors` exposes semantic getters resolved via a `ThemeExtension`
  (`AppColorsExtension`) so widgets never branch on brightness manually.
- `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation` as const classes.
- Theme mode persisted in SharedPreferences (`system` default), toggle in dashboard app bar.

## 4. Component inventory (core/widgets)
| Component | From HTML | Notes |
|---|---|---|
| `AppCard` | `.card` | surface + border + radius 16 + padding 16 |
| `SubjectCard` | `.subject-card` | icon, title, meta, optional progress; InkWell |
| `ProgressCard` / `AppProgressBar` | `.progress-bar-*` | 8px track, animated fill |
| `AppTabGroup` | `.tab-group` | segmented control, animated active pill |
| `OptionButton` | `.option-btn` | idle / selected / correct / incorrect / disabled |
| `ExplanationBox` | `.explanation-box` | blue tinted info box |
| `CodeBlock` | `.code-block` | flutter_highlight, mono, h-scroll |
| `FormulaBlock` | `.formula-math` | flutter_math_fork (LaTeX) with mono fallback |
| `StreakBadge` | `.badge-streak` | orange pill |
| `TimerBadge` | `.timer-badge` | red pill, mm:ss |
| `PrimaryButton` / `SecondaryButton` | `.btn-*` | full-width pair in `ActionRow` |
| `AppBottomNav` | `.bottom-nav` | 5 items |
| `AdBannerSlot` | `.ad-banner` | collapses when ad unavailable |
| `SectionHeader`, `EmptyState`, `LoadingIndicator`, `ErrorState` | — | designed to match |
| `FlashcardWidget` | `.flashcard` | 3D flip animation |
| `StatBarChart` | analytics bars | custom paint/flex bars |

## 5. Screen inventory (full app, superset of HTML)
Dashboard · Chapter list · Topic list · Theory reader (3 tabs) · Quiz setup ·
Quiz (4 modes) · Quiz results · Analytics · Flashcards home + review ·
Formula cheatsheet · Bookmarks · Search · Settings (theme toggle; lives in dashboard).

## 6. Navigation structure
- Root `Scaffold` with `IndexedStack` + bottom nav: **Home / Chapters / Practice /
  Stats / Cards** (exactly the HTML's 5 tabs).
- Push routes (named, central `AppRouter`): topic list → theory reader → quiz →
  results; formula sheet; bookmarks; search.
- Back handling: quiz screens intercept back with an exit-confirmation dialog.

## 7. HTML → Flutter mapping
| HTML | Flutter |
|---|---|
| phone frame / status bar | not reproduced (device chrome) |
| `.app-bar` | `AppBar` (surface color, bottom border via shape/divider) |
| `.desktop-nav` | not reproduced (prototype-only control) |
| emoji icons 🏠📚📝📊🎴⚡💻 | Material icons (home, menu_book, quiz, insights, style, bolt, memory, code) |
| `.tab-group` | custom `AppTabGroup` (not Material `TabBar` — visual fidelity) |
| ❤️ bookmark | `IconButton` favorite/favorite_border |
| bar chart divs | custom `StatBarChart` |
| `.ad-banner` | `AdBannerSlot` wrapping `google_mobile_ads` `BannerAd` |

## 8. Design ambiguities → decisions
1. **Incorrect option state** absent in HTML → red tint (`#EF4444 @ 15%`), red border, ✗ icon
   (mirrors the correct state; color + icon per accessibility rule).
2. **Light mode** absent → derived palette above.
3. Status bar/phone frame are prototype chrome → skipped.
4. HTML bottom nav has 5 tabs but only some screens exist → all 5 tabs get real screens
   (Chapters, Practice = quiz setup hub, Stats = analytics, Cards = flashcards).
5. Emoji icons → Material icons for consistent rendering; subject cards keep an emoji
   accent since the HTML leans on them for identity (rendered in a colored icon chip).
6. HTML formula blocks are plain monospace → upgraded to LaTeX where the content is
   mathematical; code-style formulas (C++ syntax) stay in `CodeBlock`.
