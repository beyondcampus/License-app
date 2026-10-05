// tools/validate_ch1_content.js
//
// Validates the Chapter 1 content files in supabase/content/ch1/*.json against
// the block schema the app renders (lib/features/theory/domain/theory_content.dart)
// and the planned topic tree, before they are applied with apply_ch1_content.js.
//
//   node tools/validate_ch1_content.js [--existing <questions snapshot .json>] [--strict]
//
// --existing: a JSON array of existing questions ({question_text|questionText})
//             used to flag new MCQs that duplicate an existing one.
// --strict:   missing subtopics are errors instead of warnings.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const contentDir = path.join(root, 'supabase', 'content', 'ch1');

// The tree the migration creates (supabase/migrations/20260923_ch1_topic_hierarchy.sql).
const TREE = {
  ch1_p1: ['ch1_t1', 'ch1_i11', 'ch1_i12', 'ch1_i13', 'ch1_i14', 'ch1_i15'],
  ch1_p2: ['ch1_t2', 'ch1_i21', 'ch1_i22', 'ch1_i23', 'ch1_i24', 'ch1_i25', 'ch1_i26', 'ch1_i27'],
  ch1_p3: ['ch1_t3', 'ch1_i31', 'ch1_i32', 'ch1_i33'],
  ch1_p4: ['ch1_t4', 'ch1_i41', 'ch1_i42', 'ch1_i43', 'ch1_i44', 'ch1_i45', 'ch1_i46'],
  ch1_p5: ['ch1_t5', 'ch1_i51', 'ch1_i52', 'ch1_i53', 'ch1_i54', 'ch1_i55'],
  ch1_p6: ['ch1_t6', 'ch1_i61', 'ch1_i62', 'ch1_i63', 'ch1_i64', 'ch1_i65', 'ch1_i66', 'ch1_i67'],
  ch1_p7: ['ch1_i71'],
};
const ALL_SUBTOPICS = new Set(Object.values(TREE).flat());
const BLOCK_TYPES = new Set(['heading', 'paragraph', 'bulletList', 'formula', 'code', 'table', 'note', 'warning', 'examTip']);
const DIFFICULTIES = new Set(['easy', 'medium', 'hard']);

const args = process.argv.slice(2);
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
  if (latex.includes('\\begin{')) err(where, `latex must not use environments: ${latex}`);
  if (latex.length > 140) warn(where, `long latex (${latex.length} chars) may not fit a phone width`);
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
      if (block.text !== undefined && typeof block.text !== 'string') err(where, 'bulletList "text" must be a string');
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
        row.forEach((cell, c) => { if (typeof cell !== 'string') err(`${where}.rows[${r}][${c}]`, 'cell must be a string'); });
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
      if (f.description !== undefined && typeof f.description !== 'string') err(rw, 'description must be a string');
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
        // Signs matter here (−10 vs 10, +200 vs −200), so compare lightly normalised text.
        if (new Set(q.options.map((o) => o.toLowerCase().replace(/\s+/g, ' ').trim())).size !== q.options.length) err(rw, 'options repeat');
        if (!Number.isInteger(q.correctIndex) || q.correctIndex < 0 || q.correctIndex >= q.options.length) err(rw, `correctIndex ${q.correctIndex} out of range`);
        if (q.options.some((o) => /all of the above|none of the above/i.test(o))) warn(rw, 'avoid "all/none of the above"');
      }
      if (!isNonEmptyString(q.explanation)) err(rw, 'explanation missing');
      if (!DIFFICULTIES.has(q.difficulty)) err(rw, `difficulty must be easy|medium|hard, got "${q.difficulty}"`);
      const key = normalize(q.questionText);
      if (questionTexts.has(key)) err(rw, `same question text as ${questionTexts.get(key)}`);
      questionTexts.set(key, q.id);
    });
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
