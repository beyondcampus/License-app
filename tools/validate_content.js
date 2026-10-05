// tools/validate_content.js
//
// Validates a chapter's content files in supabase/content/<chapter>/*.json against
// the block schema the app renders (lib/features/theory/domain/theory_content.dart)
// and the planned topic tree, before they are applied with apply_ch1_content.js.
//
//   node tools/validate_content.js <chapter> [--existing <questions snapshot .json>] [--strict]
//
// --existing: a JSON array of existing questions ({question_text|questionText})
//             used to flag new MCQs that duplicate an existing one.
// --strict:   missing subtopics are errors instead of warnings.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const chapter = (process.argv[2] || '').match(/^ch\d+$/) ? process.argv[2] : null;
if (!chapter) { console.error('usage: node tools/validate_content.js <chN> [--existing <file>] [--strict]'); process.exit(1); }
const contentDir = path.join(root, 'supabase', 'content', chapter);

// The tree the chapter's migration creates (supabase/content/<chapter>/tree.json).
const treeDoc = JSON.parse(fs.readFileSync(path.join(contentDir, 'tree.json'), 'utf8'));
const TREE = Object.fromEntries(treeDoc.parents.map((p) => [p.id, p.subtopics.map((s) => s.id)]));
const ALL_SUBTOPICS = new Set(Object.values(TREE).flat());
const BLOCK_TYPES = new Set(['heading', 'paragraph', 'bulletList', 'formula', 'code', 'table', 'note', 'warning', 'examTip']);
const DIFFICULTIES = new Set(['easy', 'medium', 'hard']);

const args = process.argv.slice(3);
const strict = args.includes('--strict');
const existingIdx = args.indexOf('--existing');
const existingPath = existingIdx >= 0 ? args[existingIdx + 1] : null;

const errors = [];
const warnings = [];
const err = (where, msg) => errors.push(`${where}: ${msg}`);
const warn = (where, msg) => warnings.push(`${where}: ${msg}`);

// Unicode-aware so that superscripts, Greek letters and units (10⁻⁸ Ω·m) stay distinct.
const normalize = (s) => String(s || '').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
const isNonEmptyString = (v) => typeof v === 'string' && v.trim().length > 0;

const checkLatex = (where, latex) => {
  let depth = 0;
  for (const ch of latex) {
    if (ch === '{') depth++;
    if (ch === '}') depth--;
    if (depth < 0) break;
  }
  if (depth !== 0) err(where, `unbalanced braces in latex: ${latex}`);
  if (latex.includes('$')) err(where, `latex must not contain $: ${latex}`);
  // Matrix environments render in flutter_math_fork (src/parser/tex/environments/array.dart);
  // anything else (align, cases, …) is not guaranteed to.
  const envs = [...latex.matchAll(/\\begin\{([A-Za-z*]+)\}/g)].map((m) => m[1]);
  const badEnv = envs.find((e) => !['matrix', 'pmatrix', 'bmatrix', 'vmatrix', 'Bmatrix', 'Vmatrix'].includes(e));
  if (badEnv) err(where, `latex environment \\begin{${badEnv}} is not supported: ${latex}`);
  const limit = envs.length ? 160 : 140;
  if (latex.length > limit) warn(where, `long latex (${latex.length} chars) may not fit a phone width`);
};

const checkBlock = (where, block) => {
  if (!block || typeof block !== 'object') return err(where, 'block is not an object');
  const type = block.type;
  if (!BLOCK_TYPES.has(type)) return err(where, `unknown block type "${type}"`);
  switch (type) {
    case 'heading':
    case 'paragraph':
    case 'note':
    case 'warning':
    case 'examTip':
    case 'code':
      if (!isNonEmptyString(block.text)) err(where, `${type} needs non-empty "text"`);
      if (type === 'paragraph' && /[*_#`]{2}|<\/?[a-z]+>/.test(block.text)) warn(where, 'paragraph looks like markdown/HTML');
      break;
    case 'bulletList':
      if (!Array.isArray(block.items) || block.items.length === 0) err(where, 'bulletList needs non-empty "items"');
      else block.items.forEach((item, i) => { if (!isNonEmptyString(item)) err(`${where}.items[${i}]`, 'item must be a non-empty string'); });
      if (!isNonEmptyString(block.text)) err(where, 'bulletList needs a non-empty lead "text" (reading content: no blanks)');
      break;
    case 'formula':
      if (!isNonEmptyString(block.latex)) err(where, 'formula needs "latex"');
      else checkLatex(where, block.latex);
      if (!isNonEmptyString(block.plainText)) err(where, 'formula needs "plainText" fallback');
      break;
    case 'table': {
      const rows = block.rows;
      if (!Array.isArray(rows) || rows.length < 2) return err(where, 'table needs a header row and at least one data row');
      const width = Array.isArray(rows[0]) ? rows[0].length : 0;
      if (width < 2 || width > 4) err(where, `table should have 2–4 columns, has ${width}`);
      if (rows.length > 9) warn(where, `table has ${rows.length} rows; long tables read badly on a phone`);
      rows.forEach((row, r) => {
        if (!Array.isArray(row)) return err(`${where}.rows[${r}]`, 'row must be an array');
        if (row.length !== width) err(`${where}.rows[${r}]`, `has ${row.length} cells, header has ${width}`);
        row.forEach((cell, c) => { if (!isNonEmptyString(cell)) err(`${where}.rows[${r}][${c}]`, 'table cell must be a non-empty string (no blanks)'); });
      });
      break;
    }
  }
};

const files = fs.existsSync(contentDir)
  ? fs.readdirSync(contentDir).filter((f) => /^topic\d+\.json$/.test(f)).sort()
  : [];
if (files.length === 0) err('content', `no topic*.json files in ${path.relative(root, contentDir)}`);

const seenIds = { subtopic: new Map(), formula: new Map(), flashcard: new Map(), question: new Map() };
const questionTexts = new Map();
const summary = [];

for (const file of files) {
  const where = file;
  let doc;
  try {
    doc = JSON.parse(fs.readFileSync(path.join(contentDir, file), 'utf8'));
  } catch (e) {
    err(where, `invalid JSON: ${e.message}`);
    continue;
  }
  const parent = doc.parent || {};
  if (!TREE[parent.id]) { err(where, `unknown parent id "${parent.id}"`); continue; }
  if (!isNonEmptyString(parent.title)) err(where, 'parent.title missing');
  if (!Array.isArray(doc.subtopics)) { err(where, 'subtopics must be an array'); continue; }

  const expected = TREE[parent.id];
  const got = doc.subtopics.map((s) => s && s.id);
  if (JSON.stringify(got) !== JSON.stringify(expected)) {
    err(where, `subtopic ids/order must be exactly [${expected.join(', ')}], got [${got.join(', ')}]`);
  }

  doc.subtopics.forEach((sub, si) => {
    const sw = `${file} › ${sub.id || `subtopics[${si}]`}`;
    if (!ALL_SUBTOPICS.has(sub.id)) err(sw, 'id is not in the planned tree');
    if (seenIds.subtopic.has(sub.id)) err(sw, `duplicate subtopic (also in ${seenIds.subtopic.get(sub.id)})`);
    seenIds.subtopic.set(sub.id, file);
    if (!isNonEmptyString(sub.title)) err(sw, 'title missing');
    if (!isNonEmptyString(sub.subtitle)) err(sw, 'subtitle missing');
    else if (sub.subtitle.length > 95) warn(sw, `subtitle is ${sub.subtitle.length} chars (keep ≤ 90)`);

    const theory = sub.theory || {};
    const counts = {};
    for (const section of ['concepts', 'formulas', 'notes']) {
      const blocks = theory[section];
      if (!Array.isArray(blocks)) { err(sw, `theory.${section} must be an array`); counts[section] = 0; continue; }
      counts[section] = blocks.length;
      blocks.forEach((b, i) => checkBlock(`${sw} › theory.${section}[${i}]`, b));
      if (section === 'formulas') blocks.forEach((b, i) => { if (b && b.type !== 'formula') err(`${sw} › theory.formulas[${i}]`, 'only formula blocks belong in theory.formulas'); });
      if (section === 'notes') blocks.forEach((b, i) => { if (b && !['note', 'warning', 'examTip'].includes(b.type)) err(`${sw} › theory.notes[${i}]`, 'notes accept note/warning/examTip only'); });
    }
    if (counts.concepts < 5) warn(sw, `only ${counts.concepts} concept blocks`);
    if (counts.concepts < 1) err(sw, 'no concept blocks');
    if (counts.formulas < 1) err(sw, 'theory.formulas is empty');
    if (counts.notes < 2) err(sw, `only ${counts.notes} note blocks (need ≥ 2)`);
    if (Array.isArray(theory.concepts) && theory.concepts[0] && theory.concepts[0].type !== 'heading') warn(sw, 'concepts should start with a heading');

    const rows = (key, prefix, check) => {
      const list = sub[key];
      if (!Array.isArray(list)) { err(sw, `${key} must be an array`); return 0; }
      list.forEach((row, i) => {
        const rw = `${sw} › ${key}[${i}]`;
        if (!isNonEmptyString(row.id)) return err(rw, 'id missing');
        if (!row.id.startsWith(`${prefix}${sub.id}_`)) err(rw, `id "${row.id}" should start with "${prefix}${sub.id}_"`);
        if (seenIds[key === 'formulas' ? 'formula' : key === 'flashcards' ? 'flashcard' : 'question'].has(row.id)) err(rw, `duplicate id ${row.id}`);
        seenIds[key === 'formulas' ? 'formula' : key === 'flashcards' ? 'flashcard' : 'question'].set(row.id, file);
        check(rw, row);
      });
      return list.length;
    };
    counts.formulaRows = rows('formulas', 'f_', (rw, f) => {
      if (!isNonEmptyString(f.title)) err(rw, 'title missing');
      if (!isNonEmptyString(f.latex)) err(rw, 'latex missing'); else checkLatex(rw, f.latex);
      if (!isNonEmptyString(f.plainText)) err(rw, 'plainText missing');
      if (!isNonEmptyString(f.description)) err(rw, 'description missing (no blanks)');
    });
    counts.flashcards = rows('flashcards', 'fc_', (rw, c) => {
      if (!isNonEmptyString(c.front)) err(rw, 'front missing');
      if (!isNonEmptyString(c.back)) err(rw, 'back missing');
      if (!DIFFICULTIES.has(c.difficulty)) err(rw, `difficulty must be easy|medium|hard, got "${c.difficulty}"`);
    });
    counts.questions = rows('questions', 'q_', (rw, q) => {
      if (!isNonEmptyString(q.questionText)) err(rw, 'questionText missing');
      if (!Array.isArray(q.options) || q.options.length < 2) err(rw, 'needs at least 2 options');
      else {
        if (q.options.length !== 4) warn(rw, `${q.options.length} options (NEC style is 4)`);
        q.options.forEach((o, i) => { if (!isNonEmptyString(o)) err(`${rw}.options[${i}]`, 'option must be a non-empty string'); });
        // Signs matter here (−10 vs 10, +200 vs −200), and so does letter case
        // (printf %x vs %X, "ff" vs "FF", toupper output), so only whitespace is normalised.
        if (new Set(q.options.map((o) => o.replace(/\s+/g, ' ').trim())).size !== q.options.length) err(rw, 'options repeat');
        if (!Number.isInteger(q.correctIndex) || q.correctIndex < 0 || q.correctIndex >= q.options.length) err(rw, `correctIndex ${q.correctIndex} out of range`);
        if (q.options.some((o) => /all of the above|none of the above/i.test(o))) warn(rw, 'avoid "all/none of the above"');
      }
      if (!isNonEmptyString(q.explanation)) err(rw, 'explanation missing');
      if (!DIFFICULTIES.has(q.difficulty)) err(rw, `difficulty must be easy|medium|hard, got "${q.difficulty}"`);
      const key = normalize(q.questionText);
      if (questionTexts.has(key)) err(rw, `same question text as ${questionTexts.get(key)}`);
      questionTexts.set(key, q.id);
    });
    if (counts.formulaRows < 2) err(sw, `only ${counts.formulaRows} formula rows (need ≥ 2)`);
    if (counts.flashcards < 2) err(sw, `only ${counts.flashcards} flashcards (need ≥ 2)`);
    summary.push({ file, id: sub.id, ...counts });
  });
}

// Every planned subtopic should be covered.
for (const id of ALL_SUBTOPICS) {
  if (!seenIds.subtopic.has(id)) (strict ? err : warn)('coverage', `subtopic ${id} has no content file yet`);
}

// Existing questions: flag duplicates of new MCQs.
if (existingPath) {
  try {
    const existing = JSON.parse(fs.readFileSync(existingPath, 'utf8'));
    const existingKeys = new Map(existing.map((q) => [normalize(q.question_text || q.questionText), q.id]));
    for (const [key, id] of questionTexts) {
      if (existingKeys.has(key)) err(`question ${id}`, `duplicates existing question ${existingKeys.get(key)}`);
    }
  } catch (e) {
    warn('existing', `could not read ${existingPath}: ${e.message}`);
  }
}

// question_topics.json: every target must be a planned subtopic.
const mapPath = path.join(contentDir, 'question_topics.json');
if (fs.existsSync(mapPath)) {
  try {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'));
    for (const [qid, tid] of Object.entries(map)) {
      if (qid.startsWith('_')) continue;
      if (!ALL_SUBTOPICS.has(tid)) err('question_topics.json', `${qid} → "${tid}" is not a planned subtopic`);
    }
  } catch (e) {
    err('question_topics.json', `invalid JSON: ${e.message}`);
  }
} else {
  warn('question_topics.json', 'missing');
}

// Report.
if (summary.length) {
  console.log('subtopic   concepts formulaBlk notes formulaRows flashcards questions  file');
  for (const s of summary) {
    console.log(
      `${s.id.padEnd(10)} ${String(s.concepts).padStart(8)} ${String(s.formulas).padStart(10)} ${String(s.notes).padStart(5)} ` +
      `${String(s.formulaRows).padStart(11)} ${String(s.flashcards).padStart(10)} ${String(s.questions).padStart(9)}  ${s.file}`,
    );
  }
  const total = (k) => summary.reduce((n, s) => n + (s[k] || 0), 0);
  console.log(`\n${summary.length} subtopics · ${total('concepts') + total('formulas') + total('notes')} theory blocks · ` +
    `${total('formulaRows')} formula rows · ${total('flashcards')} flashcards · ${total('questions')} new questions`);
}
for (const w of warnings) console.log(`warning: ${w}`);
for (const e of errors) console.error(`error: ${e}`);
console.log(`\n${errors.length} error(s), ${warnings.length} warning(s)`);
process.exit(errors.length ? 1 : 0);
