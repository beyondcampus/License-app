# Content additions — candidates for the next round

Written 2026-09-25, after the 10-chapter restructure, from:
- the NEC syllabus in [nec-syllabus.md](nec-syllabus.md);
- the content now in `supabase/content/ch1–ch10`;
- the **public** feature list of a comparable NEC-prep site (engineer.prolinknepal.com.np): sample MCQs, subject-wise modules, chapter drills, full timed papers and a progress dashboard. Only its feature types were used. No content from its members-only area was accessed or copied; all content below is to be written from standard textbooks, as for chapters 1–10.

Current app content: 10 chapters · 351 topics · 281 theory pages · 1,274 MCQs · 1,035 formulas · 1,075 flashcards.

---

## 1. Practice formats (highest value)

| Addition | Why | Effort |
|---|---|---|
| **Full-length mock exam** that follows the official NEC paper pattern (question count, marks split, duration), drawing questions from every chapter in proportion | The current mock is 20 questions (`AppConstants.mockExamLength`), while competing apps offer full timed papers. Take the exact pattern from nec.gov.np before building it. | App: small (config + chapter-weighted sampling). Content: none. |
| **Model sets**: 5–10 fixed, pre-assembled full papers with an answer review | Learners want repeatable "sets" to compare scores over time | Content: select and balance questions from the existing bank; add new ones where chapters are thin |
| **Numericals-only drill** per chapter (filter to computational questions) | Numeric MCQs carry the most marks per unit of study time and need practice | App: a `kind: numeric|concept` tag on questions (a backfill script can guess it from digits in the stem) |

## 2. Question bank depth

| Addition | Detail |
|---|---|
| Raise every subtopic from about 5 to **10+ MCQs** | ~300 subtopics × 5 new ≈ 1,500 questions. Prioritise the numeric-heavy subtopics: ch1 circuits, ch2 number systems/K-maps, ch4 cache/pipelining, ch5 subnetting/CRC, ch7 scheduling/paging, ch9 search/probability, ch10 economics/CPM/PERT. |
| **Difficulty balance** | Target about 30% easy, 50% medium, 20% hard in each subtopic; the validator can report the current spread. |
| **Explanation with working** for every numeric MCQ | Many explanations are already full; make it a validator rule for any question whose stem has numbers. |

## 3. Reading content

| Addition | Where it fits |
|---|---|
| **Glossary / abbreviations** per chapter (e.g. ch5 network acronyms, ch8 UML/CMMI terms, ch10 procurement terms) | A new theory block type isn't needed: one "Glossary" subtopic per chapter under Quick Revision, or a searchable app screen |
| **"Compare & contrast" tables** collected per chapter (TCP vs UDP, BFS vs DFS, NEC vs NEA, CPM vs PERT …) | A second Quick Revision subtopic per chapter |
| **Worked-example pages**: 3–5 fully solved long numericals per chapter, step by step | A subtopic "Solved Numericals" under each chapter's Quick Revision parent |
| **Exam-info page**: official NEC exam pattern, eligibility, registration steps, links to nec.gov.np | Static page in the app, sourced from nec.gov.np and dated, since it changes |
| **Nepal-specific updates (ch10)**: verify and date the tax pool rates, VAT, procurement stages and NEC Act amendments against current official texts | Existing ch10 subtopics `ch10_i23`, `ch10_i43`, `ch10_i61` |

## 4. Other disciplines (bigger scope)

The comparable site covers Civil and Electrical as well as Computer Engineering. Chapter 10 (AALL10) is common to every discipline and could be reused unchanged if the app ever adds them.

---

## Suggested order
1. Full-length mock exam in the official pattern (app change only).
2. Solved-numericals and compare-and-contrast subtopics (reading content; same pipeline as chapters 1–10).
3. Question-bank expansion to 10+ per subtopic, numeric-heavy chapters first.
4. Glossary and exam-info page.
5. Verify the ch10 Nepal figures against current laws.
