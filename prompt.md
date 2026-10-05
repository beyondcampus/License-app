# ROLE

Act as a **Senior Flutter Architect, Senior Dart Developer, UI/UX Engineer, and Code Reviewer** with extensive experience building production-grade educational applications.

You are going to build a complete, modular, production-ready **Flutter Engineering Board Exam Preparation App**.

The app is designed for engineering students preparing for licensing/board examinations and initially covers:

- **Chapter 1 — Basic Electrical & EDC**
- **Chapter 2 — Digital Logic & Microprocessors**
- **Chapter 3 — C/C++ Programming**

I will provide an **HTML file containing the generic UI/design that should be used as the primary visual reference**.

The HTML is a design reference, NOT something to embed in Flutter.

Your job is to carefully inspect the HTML and recreate its design natively using Flutter widgets while implementing the complete application functionality described below.

---

# CRITICAL DEVELOPMENT RULE

## DO NOT BUILD THE ENTIRE APPLICATION IN ONE PASS.

Work through the project in clearly separated stages.

You must complete and validate each stage before moving to the next stage.

The required workflow is:

**STAGE 1 → Inspect HTML & establish Design System**

**STAGE 2 → Design Flutter Architecture & Project Structure**

**STAGE 3 → Implement Core Application Shell & Navigation**

**STAGE 4 → Implement Local Data Layer & Sample Content**

**STAGE 5 → Implement Study/Theory Features**

**STAGE 6 → Implement MCQ/Quiz Engine**

**STAGE 7 → Implement Analytics, Results & Recommendations**

**STAGE 8 → Implement Flashcards & Spaced Repetition**

**STAGE 9 → Implement Formula/Notes/Bookmarks**

**STAGE 10 → Implement AdMob**

**STAGE 11 → Persistence, Offline Verification & Edge Cases**

**STAGE 12 → Full Compile/Error/UI Audit**

Do not skip stages.

Do not replace a stage with a vague explanation.

Do not create fake implementations merely to move to the next stage.

---

# STAGE 1 — INSPECT THE HTML FIRST

Before writing Flutter application code, thoroughly inspect the supplied HTML file.

Analyze:

- Overall page structure
- Navigation
- Header
- Bottom navigation
- Cards
- Buttons
- Icons
- Typography
- Font sizes
- Font weights
- Border radius
- Shadows
- Borders
- Spacing
- Padding
- Margins
- Colors
- Background colors
- Dark mode
- Light mode
- Progress indicators
- Charts
- Tabs
- Modals
- Bottom sheets
- Forms
- Empty states
- Loading states
- Error states
- Responsive behavior
- Mobile layout
- Desktop/tablet layout where applicable

Identify reusable UI components.

Create a Flutter design system based on the HTML.

The design system should include reusable constants such as:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppElevation
AppIcons
```

Also identify:

- Primary color
- Secondary color
- Accent color
- Surface colors
- Background colors
- Success color
- Error color
- Warning color
- Text colors
- Muted text colors

Do NOT arbitrarily redesign the interface if the HTML already provides a clear visual design.

The HTML is the source of truth for the visual direction.

However, adapt interactions appropriately for native Flutter/mobile UX.

### STAGE 1 OUTPUT

Before proceeding, provide:

1. HTML UI analysis
2. Extracted design tokens
3. Flutter theme strategy
4. Component inventory
5. Screen inventory
6. Navigation structure
7. Mapping of HTML components → Flutter widgets
8. Any design ambiguities that need reasonable interpretation

Then proceed with implementation using those decisions.

---

# STAGE 2 — FLUTTER ARCHITECTURE

Use **Clean Architecture with a Feature-First structure**.

Preferred state management:

**Provider**

Use Provider consistently rather than mixing multiple state-management solutions.

Recommended structure:

```text
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_constants.dart
│   │   └── app_strings.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── dark_theme.dart
│   │   └── light_theme.dart
│   │
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── math_utils.dart
│   │   └── validators.dart
│   │
│   └── widgets/
│       ├── app_card.dart
│       ├── progress_card.dart
│       ├── section_header.dart
│       ├── empty_state.dart
│       └── loading_indicator.dart
│
├── features/
│
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── state/
│   │
│   ├── chapters/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── state/
│   │
│   ├── theory/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── state/
│   │
│   ├── quiz/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── state/
│   │
│   ├── formulas/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── bookmarks/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── flashcards/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── state/
│   │
│   ├── analytics/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── state/
│   │
│   └── ads/
│       ├── ad_manager.dart
│       └── widgets/
│
└── routes/
    └── app_router.dart
```

Keep:

- UI separate from business logic
- Business logic separate from data access
- Models strongly typed
- Repositories abstracted
- State managed through Provider
- Reusable widgets centralized

Do not place the entire application inside `main.dart`.

---

# STAGE 3 — APPLICATION SHELL

Build:

- App initialization
- Material 3 theme
- Light mode
- Dark mode
- Navigation
- Dashboard
- Bottom navigation if appropriate according to the HTML
- Profile/avatar UI
- Daily streak
- Preparation percentage
- Subject cards
- Global reusable components

Dashboard should contain:

### Study Modules

- Chapter 1 — Basic Electrical & EDC
- Chapter 2 — Digital Logic & Microprocessors
- Chapter 3 — C/C++ Programming

### Practice Center

- Chapter-wise MCQs
- Timed mock tests
- Saved/bookmarked questions
- Explanations

### Analytics

- Topic mastery
- Accuracy
- Speed
- Weak topics
- Flashcards

Use the uploaded HTML design as the visual reference.

---

# STAGE 4 — LOCAL DATA & OFFLINE-FIRST ARCHITECTURE

The application must be **100% functional without internet access**.

Absolutely DO NOT use:

- REST APIs
- Firebase
- Supabase
- Remote databases
- Remote JSON
- Network-based study content
- External content APIs

All educational content must be bundled locally.

Use:

```text
assets/
└── data/
    ├── chapters.json
    ├── topics.json
    ├── questions.json
    ├── theory.json
    ├── formulas.json
    └── flashcards.json
```

Use SQLite for structured user-generated/progress data where appropriate.

Use:

```text
sqflite
path
```

Use:

```text
shared_preferences
```

for lightweight preferences and progress such as:

- Theme preference
- Daily streak
- Last study date
- Overall progress
- Quiz statistics
- Settings
- Flashcard state

Create repositories such as:

```text
QuestionRepository
TheoryRepository
FormulaRepository
ChapterRepository
BookmarkRepository
ProgressRepository
FlashcardRepository
```

The app must continue working in airplane mode.

---

# SAMPLE DATA REQUIREMENT

Do not create an empty application.

Provide meaningful sample content for all three chapters.

### Chapter 1 — Basic Electrical & EDC

Include examples covering topics such as:

- Ohm's Law
- Kirchhoff's Laws
- AC/DC fundamentals
- RMS values
- RLC circuits
- Impedance
- Resonance
- Power factor
- Transformers
- Basic electrical devices
- Electrical measurements
- Electronic Devices and Circuits

### Chapter 2 — Digital Logic & Microprocessors

Include:

- Number systems
- Boolean algebra
- Logic gates
- Truth tables
- K-Maps
- Combinational circuits
- Sequential circuits
- Flip-flops
- Counters
- Registers
- 8086 architecture
- Physical address calculation
- Addressing modes
- Assembly basics

### Chapter 3 — C/C++ Programming

Include:

- Variables
- Data types
- Operators
- Conditional statements
- Loops
- Functions
- Arrays
- Strings
- Pointers
- Structures
- Classes
- Inheritance
- Polymorphism
- Constructors
- OOP concepts

Include enough sample questions and theory to demonstrate every feature.

---

# STAGE 5 — THEORY/STUDY SYSTEM

Implement:

## Chapter Selection

Each chapter should display:

- Chapter title
- Description
- Number of topics
- Number of MCQs
- Progress
- Formula availability
- Quick notes availability

## Topic Selection

Show:

- Topic title
- Completion percentage
- Completed state
- Formula badge
- Quick notes badge
- MCQ count

## Theory Reader

Implement:

### Tab 1

**Core Concepts**

### Tab 2

**Key Formulas**

### Tab 3

**Exam Notes**

Support:

- Headings
- Paragraphs
- Lists
- Mathematical equations
- Code snippets
- Tables
- Important notes
- Warnings
- Exam tips

Use:

```text
flutter_math_fork
```

for LaTeX equations.

Use:

```text
flutter_highlight
```

for:

- C
- C++
- Assembly

Include floating actions for:

- Practice this topic
- Formula sheet

---

# STAGE 6 — MCQ ENGINE

Build a complete production-quality quiz engine.

Each Question should support:

```dart
id
chapterId
topicId
questionText
options
correctIndex
explanation
difficulty
codeSnippet
formula
```

Implement:

- Question counter
- Timer
- Progress indicator
- Option selection
- Immediate feedback
- Correct answer state
- Incorrect answer state
- Explanation
- Bookmark
- Next question
- Previous question where appropriate
- Finish quiz
- Restart quiz
- Exit confirmation
- Score calculation
- Accuracy
- Time taken
- Topic performance

The user must not be able to accidentally change an answer after submission unless the UI explicitly supports retry/review.

Code snippets must use monospace formatting.

Math questions must support LaTeX.

---

# QUIZ MODES

Support:

### Practice Mode

Immediate answer feedback.

### Timed Test

Questions are completed under a countdown.

### Mock Exam

Multiple topics/chapter questions with final results.

### Bookmarked Questions

Practice only saved questions.

---

# STAGE 7 — RESULTS & ANALYTICS

Create a detailed result screen.

Display:

- Total questions
- Correct
- Incorrect
- Unanswered
- Score percentage
- Accuracy
- Time taken
- Average time/question

Show topic performance.

Calculate weak areas based on actual user performance.

Example:

```text
Digital Logic — 42%
Microprocessors — 58%
K-Maps — 34%
Boolean Algebra — 81%
```

Provide recommendations such as:

> Focus on K-Maps and Digital Logic before attempting another mock test.

Do not hardcode recommendations.

Generate them from stored performance data.

---

# STAGE 8 — FLASHCARDS

Create an interactive flashcard system.

Each card should have:

- Front
- Back
- Topic
- Difficulty
- Review status

Implement:

- Flip animation
- Hard
- Good
- Easy

Persist review state locally.

Implement a practical spaced-repetition scheduling system.

It does not need to be scientifically perfect, but it must be deterministic and persistent.

Example:

```text
Hard → review sooner
Good → normal interval
Easy → longer interval
```

---

# STAGE 9 — FORMULAS, NOTES & BOOKMARKS

## Formula Cheatsheet

Create searchable formulas grouped by chapter/topic.

Examples:

```text
V = IR

Vrms = 0.707 Vm

XL = 2πfL

XC = 1/(2πfC)

Z = √(R² + (XL - XC)²)

fr = 1/(2π√LC)
```

Digital logic examples:

```text
Physical Address = (CS × 10H) + IP
```

Programming examples should include useful syntax/reference snippets.

## Search

Provide local search across:

- Chapters
- Topics
- Theory
- Formulas
- Questions

No network search.

## Bookmarks

Users can bookmark:

- Questions
- Formulas
- Theory topics

All bookmarks must persist after app restart.

---

# STAGE 10 — ADMOB

Integrate:

```text
google_mobile_ads
```

Use Google's official test ad IDs during development.

Clearly mark where production IDs must be replaced.

Implement:

### Banner Ads

Show persistent banners on appropriate major screens:

- Dashboard
- Theory Reader
- Results

Do not obstruct important content or navigation.

### Interstitial Ads

Show an interstitial after:

- Completing a practice test
- Appropriate major screen transitions

BUT implement a cooldown.

Do not show an ad after every question.

Do not create an annoying user experience.

Create an `AdManager` responsible for:

- Initialization
- Banner creation
- Interstitial loading
- Interstitial display
- Cooldown
- Failure handling

The application must remain fully functional if ads fail to load.

---

# STAGE 11 — PERSISTENCE & EDGE CASES

Test and handle:

- First app launch
- Empty progress
- No bookmarks
- No quiz history
- No flashcards due
- Quiz interruption
- App restart
- Theme changes
- Empty search results
- Missing optional code snippets
- Missing formulas
- Invalid local JSON
- Timer reaching zero
- Quiz completion
- Duplicate bookmarks
- Ad loading failure

Never allow an exception in one feature to crash the entire application.

Provide useful empty states.

---

# STAGE 12 — FINAL COMPILE & ERROR AUDIT

This stage is mandatory.

Before considering the project complete:

## Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

If possible also verify:

```bash
flutter build appbundle --debug
```

Fix all:

- Compilation errors
- Dart analyzer errors
- Missing imports
- Incorrect package APIs
- Null-safety issues
- Provider lifecycle issues
- Navigation errors
- Asset-loading errors
- SQLite initialization errors
- AdMob integration errors
- Layout overflow
- Runtime exceptions

Do NOT simply report errors.

Fix them.

Then run the checks again.

Continue until the project is clean.

---

# UI QUALITY AUDIT

After implementation, inspect every major screen.

Check:

- No overflow
- Correct spacing
- Correct typography
- Correct theme behavior
- Correct dark mode
- Buttons have appropriate states
- Loading states exist
- Empty states exist
- Navigation works
- Back navigation works
- Long text scrolls correctly
- Equations render correctly
- Code blocks render correctly
- Ads don't cover content
- Small screens remain usable

The application should feel like a polished commercial educational app rather than a demo.

---

# PUBSPEC

Create a complete `pubspec.yaml`.

Include appropriate stable versions of:

```text
flutter
provider
google_mobile_ads
shared_preferences
sqflite
path
flutter_math_fork
flutter_highlight
```

Add any additional dependency only when it provides a genuine requirement.

Avoid unnecessary packages.

Declare all assets correctly.

Example:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/data/
```

---

# DATA MODELS

Create strongly typed models.

At minimum:

```text
Chapter
Topic
TheoryContent
Formula
Question
QuizResult
Bookmark
Flashcard
FlashcardReview
UserProgress
TopicPerformance
```

Use JSON serialization manually or with appropriate tooling, but keep the architecture clean.

---

# PERFORMANCE REQUIREMENTS

The application should:

- Start quickly
- Avoid unnecessary rebuilds
- Use lazy lists
- Avoid loading huge datasets repeatedly
- Cache local data where appropriate
- Dispose timers/controllers correctly
- Avoid memory leaks
- Keep UI responsive

---

# ACCESSIBILITY

Implement reasonable accessibility:

- Semantic labels
- Sufficient contrast
- Large enough tap targets
- Readable typography
- Support system text scaling where practical
- Avoid relying solely on color to communicate correctness

For example:

Correct answers should use both:

- Color
- Icon/text

Incorrect answers should do the same.

---

# CODE QUALITY RULES

Use:

- Null safety
- `const` constructors where appropriate
- Small reusable widgets
- Clear naming
- Single responsibility
- Repository abstractions
- Dependency injection where useful
- Immutable domain models where practical

Avoid:

- Massive widgets
- Massive `build()` methods
- Global mutable state
- Hardcoded business logic in UI
- Duplicate components
- Unnecessary dependencies
- Dead code

Do not use:

```dart
// TODO: implement later
```

for anything required by the main application flow.

Every primary feature must actually work.

---

# NAVIGATION

Create a centralized navigation structure.

At minimum support:

```text
Dashboard
    ↓
Chapter Selection
    ↓
Topic Selection
    ↓
Theory Reader
    ↓
Quiz
    ↓
Results
```

Also support:

```text
Dashboard
    → Formula Cheatsheet

Dashboard
    → Flashcards

Dashboard
    → Analytics

Dashboard
    → Bookmarks
```

Back navigation must behave naturally.

---

# IMPORTANT DESIGN PRINCIPLE

The supplied HTML determines the **visual identity**.

The Flutter implementation determines the **native architecture and interaction model**.

Therefore:

DO:

- Recreate HTML visual styling
- Recreate cards
- Recreate colors
- Recreate typography
- Recreate layouts
- Recreate navigation concepts
- Recreate interactions where appropriate

DO NOT:

- Embed the HTML in a WebView
- Build the actual application as a website
- Depend on JavaScript
- Depend on a web server
- Require internet access
- Simply screenshot the HTML
- Replace the HTML design with a generic Flutter template

---

# RESPONSIVE DESIGN

The application should work properly on:

- Small Android phones
- Large Android phones
- Tablets
- Different aspect ratios

Use Flutter's responsive layout mechanisms appropriately.

Avoid fixed widths that cause overflow.

---

# DEVELOPMENT PROCESS

At the end of every stage:

1. Summarize what was implemented.
2. List the files created/modified.
3. Explain important architectural decisions.
4. Identify any problems discovered.
5. Fix problems before continuing.
6. Verify the stage builds successfully.

Do not generate fake completion claims.

If a stage has an error, fix it before moving forward.

---

# FINAL DELIVERABLE

The final project must contain:

```text
pubspec.yaml

lib/
  main.dart
  core/
  features/
  routes/

assets/
  data/
    chapters.json
    topics.json
    questions.json
    theory.json
    formulas.json
    flashcards.json
```

The project must be a real Flutter application that can be opened in Android Studio or VS Code and run.

It must work without a backend.

It must work offline.

It must include meaningful sample content.

It must include all primary screens.

It must include persistence.

It must include quiz functionality.

It must include analytics.

It must include flashcards.

It must include formulas.

It must include bookmarks.

It must include AdMob test integration.

It must use the supplied HTML as the visual reference.

---

# MOST IMPORTANT INSTRUCTION

**Do not rush to code.**

First understand the supplied HTML.

Then establish the design system.

Then establish the architecture.

Then implement the application incrementally.

Then test and audit everything.

The final result should be something a professional Flutter development team could realistically continue maintaining and expanding into Chapters 4, 5, 6, and beyond.

Start with **STAGE 1: HTML inspection and design-system analysis**.