# Stage 4 prep — Data Schemas & Sample Content Plan

All study content ships as bundled JSON under `assets/data/`. Everything below is
offline; no network anywhere.

## JSON schemas

### chapters.json
```json
[{ "id": "ch1", "title": "Basic Electrical & EDC", "description": "...",
   "icon": "bolt", "emoji": "⚡", "order": 1 }]
```

### topics.json
```json
[{ "id": "ch1_t1", "chapterId": "ch1", "title": "Circuit Theorems",
   "subtitle": "Thevenin's, Norton's, KCL, KVL", "order": 1,
   "hasFormulas": true, "hasNotes": true }]
```

### theory.json — one entry per topic
```json
[{ "topicId": "ch1_t1",
   "concepts": [TheoryBlock...], "formulas": [TheoryBlock...], "notes": [TheoryBlock...] }]
```
`TheoryBlock`: `{ "type": "heading|paragraph|bulletList|formula|code|table|note|warning|examTip",
"text": "...", "items": [...], "latex": "...", "language": "cpp", "rows": [[..]] }`

### questions.json
```json
[{ "id": "q_ch2_001", "chapterId": "ch2", "topicId": "ch2_t8",
   "questionText": "...", "options": ["A", "B", "C", "D"], "correctIndex": 1,
   "explanation": "...", "difficulty": "easy|medium|hard",
   "codeSnippet": null, "codeLanguage": null, "formula": null }]
```

### formulas.json
```json
[{ "id": "f_ch1_001", "chapterId": "ch1", "topicId": "ch1_t4",
   "title": "Resonant Frequency (LC Circuit)",
   "latex": "f_r = \\frac{1}{2\\pi\\sqrt{LC}}",
   "plainText": "fr = 1 / (2π√(LC))", "isCode": false, "description": "..." }]
```
(`isCode: true` + plainText for programming "formulas" like `int *ptr = &var;`.)

### flashcards.json
```json
[{ "id": "fc_001", "chapterId": "ch3", "topicId": "ch3_t9",
   "front": "What is a Pointer?", "back": "...", "difficulty": "medium" }]
```

## Sample content targets (minimum, per prompt coverage lists)

### Chapter 1 — Basic Electrical & EDC (~12 topics)
Topics: Ohm's Law & Basic Concepts · Kirchhoff's Laws & Circuit Theorems · AC
Fundamentals & RMS · RLC Circuits & Impedance · Resonance · Power & Power Factor ·
Transformers · Electrical Measurements · Semiconductor Diodes · Transistors (BJT & FET) ·
Op-Amps & Basic Devices · Rectifiers & Power Supplies.
Content: theory for ≥4 topics (full blocks incl. LaTeX), **≥25 MCQs** spread across
topics/difficulties, ≥8 formulas, ≥8 flashcards.

### Chapter 2 — Digital Logic & Microprocessors (~12 topics)
Topics: Number Systems · Boolean Algebra · Logic Gates & Truth Tables · K-Maps ·
Combinational Circuits · Sequential Circuits & Flip-Flops · Counters & Registers ·
8086 Architecture · Physical Address Calculation · Addressing Modes · Assembly Basics ·
Memory & Interfacing.
Content: theory for ≥4 topics, **≥25 MCQs** (incl. the CS×10H+IP physical-address
style from the HTML), ≥8 formulas (incl. `Physical Address = (CS × 10H) + IP`),
≥8 flashcards.

### Chapter 3 — C/C++ Programming (~11 topics)
Topics: Variables & Data Types · Operators · Control Flow (if/switch) · Loops ·
Functions · Arrays & Strings · Pointers · Structures & Unions · Classes & Objects ·
Constructors & Destructors · Inheritance & Polymorphism.
Content: theory for ≥4 topics (with highlighted C/C++ code blocks), **≥25 MCQs**
(several with `codeSnippet`), ≥8 syntax-reference formulas, ≥8 flashcards.

**Totals: ≥75 questions, ≥24 formulas, ≥24 flashcards, 35 topics, 12+ full theory sets.**
Every feature must have enough data to demo: each quiz mode can assemble ≥10 questions;
every chapter tab of the formula sheet is non-empty; flashcard queue is non-empty on
first launch.

## Content quality rules
- Explanations mandatory on every question (exam-style, 1–3 sentences).
- LaTeX used for all real math; `plainText` fallback always present.
- Difficulty distribution roughly 40% easy / 40% medium / 20% hard.
- IDs are stable strings (bookmarks/attempts reference them).
- JSON is loaded defensively: malformed entries skipped, never crash (Stage 11 test).
