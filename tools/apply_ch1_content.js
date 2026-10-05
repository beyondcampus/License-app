// tools/apply_ch1_content.js
//
// Uploads the reviewed Chapter 1 content (supabase/content/ch1/*.json) to Supabase
// AFTER the structural migration (supabase/migrations/20260923_ch1_topic_hierarchy.sql)
// has been run in the SQL Editor. Run it once; it is safe to re-run (upserts).
//
//   PowerShell:  $env:SUPABASE_SERVICE_ROLE_KEY = '<service role key>'
//                node tools/validate_ch1_content.js --strict
//                node tools/apply_ch1_content.js [--dry-run]
//
// What it does, in order:
//   1. Checks the migration has been applied (ch1_p1 … ch1_p7 exist).
//   2. topics:          title + description (subtitle) for every subtopic.
//   3. theory_content:  upsert one row per subtopic.
//   4. formulas:        upsert the new rows; delete old ch1 rows not in the new set.
//   5. flashcards:      upsert the new rows; delete old ch1 rows (and their reviews)
//                       not in the new set.
//   6. questions:       re-point existing questions per question_topics.json,
//                       insert the new MCQs (+ options), and import
//                       supabase/content/ch9/questions_new.json if present.
//   7. Prints a per-subtopic verification table.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const contentDir = path.join(root, 'supabase', 'content', 'ch1');
const URL_BASE = (process.env.SUPABASE_URL || 'https://dgzvuidzpfbvvoaivquu.supabase.co') + '/rest/v1';
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const dryRun = process.argv.includes('--dry-run');

if (!KEY) {
  console.error('SUPABASE_SERVICE_ROLE_KEY is not set. Never paste it into a file; set it in the shell.');
  process.exit(1);
}

const headers = {
  apikey: KEY,
  Authorization: `Bearer ${KEY}`,
  'Content-Type': 'application/json',
};

async function request(method, pathAndQuery, body, extraHeaders = {}) {
  const res = await fetch(`${URL_BASE}/${pathAndQuery}`, {
    method,
    headers: { ...headers, ...extraHeaders },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${method} ${pathAndQuery} → ${res.status}: ${text}`);
  }
  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

async function selectAll(pathAndQuery) {
  const rows = [];
  for (let from = 0; ; from += 1000) {
    const page = await request('GET', pathAndQuery, undefined, { Range: `${from}-${from + 999}`, 'Range-Unit': 'items' });
    rows.push(...page);
    if (page.length < 1000) return rows;
  }
}

const inList = (ids) => `(${ids.map((id) => `"${String(id).replace(/"/g, '\\"')}"`).join(',')})`;

async function upsert(table, rows, onConflict = 'id') {
  if (rows.length === 0) return;
  if (dryRun) return console.log(`  [dry-run] upsert ${rows.length} → ${table}`);
  for (let i = 0; i < rows.length; i += 200) {
    await request('POST', `${table}?on_conflict=${onConflict}`, rows.slice(i, i + 200), {
      Prefer: 'resolution=merge-duplicates,return=minimal',
    });
  }
}

async function deleteWhere(table, filter) {
  if (dryRun) return console.log(`  [dry-run] delete from ${table} where ${filter}`);
  await request('DELETE', `${table}?${filter}`, undefined, { Prefer: 'return=minimal' });
}

async function patch(table, filter, values) {
  if (dryRun) return console.log(`  [dry-run] update ${table} where ${filter} set ${JSON.stringify(values)}`);
  await request('PATCH', `${table}?${filter}`, values, { Prefer: 'return=minimal' });
}

function loadContent() {
  const files = fs.readdirSync(contentDir).filter((f) => /^topic\d+\.json$/.test(f)).sort();
  const subtopics = [];
  for (const file of files) {
    const doc = JSON.parse(fs.readFileSync(path.join(contentDir, file), 'utf8'));
    for (const sub of doc.subtopics) subtopics.push({ ...sub, parentId: doc.parent.id });
  }
  const mapPath = path.join(contentDir, 'question_topics.json');
  const questionTopics = fs.existsSync(mapPath) ? JSON.parse(fs.readFileSync(mapPath, 'utf8')) : {};
  delete questionTopics._comment;
  const ch9Path = path.join(root, 'supabase', 'content', 'ch9', 'questions_new.json');
  const extraQuestions = fs.existsSync(ch9Path) ? JSON.parse(fs.readFileSync(ch9Path, 'utf8')) : [];
  return { subtopics, questionTopics, extraQuestions };
}

const toQuestionRow = (q, chapterId, topicId) => ({
  id: q.id,
  chapter_id: chapterId,
  topic_id: topicId,
  question_text: q.questionText,
  correct_index: q.correctIndex,
  explanation: q.explanation || '',
  difficulty: q.difficulty || 'medium',
  formula: q.formula || null,
  code_snippet: q.codeSnippet || null,
  code_language: q.codeLanguage || null,
});

async function insertQuestions(questions, chapterIdFor, topicIdFor) {
  if (questions.length === 0) return;
  const rows = questions.map((q) => toQuestionRow(q, chapterIdFor(q), topicIdFor(q)));
  await upsert('questions', rows);
  // Options are replaced wholesale so re-runs stay idempotent.
  await deleteWhere('question_options', `question_id=in.${inList(rows.map((r) => r.id))}`);
  const options = questions.flatMap((q) =>
    q.options.map((text, index) => ({ question_id: q.id, option_index: index, option_text: text })),
  );
  if (dryRun) return console.log(`  [dry-run] insert ${options.length} question_options`);
  for (let i = 0; i < options.length; i += 500) {
    await request('POST', 'question_options', options.slice(i, i + 500), { Prefer: 'return=minimal' });
  }
}

async function main() {
  const { subtopics, questionTopics, extraQuestions } = loadContent();
  console.log(`Loaded ${subtopics.length} subtopics from ${path.relative(root, contentDir)}${dryRun ? ' (dry run)' : ''}`);

  // 1. Migration applied?
  const parents = await selectAll('topics?id=like.ch1_p*&select=id');
  if (parents.length < 7) {
    console.error(`Found ${parents.length}/7 parent topics. Run supabase/migrations/20260923_ch1_topic_hierarchy.sql first.`);
    process.exit(1);
  }
  const existingTopicIds = new Set((await selectAll('topics?chapter_id=eq.ch1&select=id')).map((t) => t.id));
  const missing = subtopics.filter((s) => !existingTopicIds.has(s.id)).map((s) => s.id);
  if (missing.length) {
    console.error(`These subtopics are not in Supabase (migration/content mismatch): ${missing.join(', ')}`);
    process.exit(1);
  }

  // 2. Titles and subtitles.
  console.log('Updating topic titles/descriptions…');
  for (const sub of subtopics) {
    await patch('topics', `id=eq.${sub.id}`, { title: sub.title, description: sub.subtitle || sub.title });
  }

  // 3. Theory.
  console.log('Upserting theory_content…');
  await upsert(
    'theory_content',
    subtopics.map((s) => ({
      topic_id: s.id,
      concepts: s.theory.concepts,
      formulas: s.theory.formulas,
      notes: s.theory.notes,
    })),
    'topic_id',
  );

  // 4. Formulas.
  console.log('Replacing ch1 formulas…');
  const formulaRows = subtopics.flatMap((s) =>
    s.formulas.map((f) => ({
      id: f.id,
      chapter_id: 'ch1',
      topic_id: s.id,
      title: f.title,
      description: f.description || '',
      latex: f.latex || null,
      plain_text: f.plainText,
      is_code: false,
    })),
  );
  await upsert('formulas', formulaRows);
  const oldFormulas = (await selectAll('formulas?chapter_id=eq.ch1&select=id')).map((r) => r.id)
    .filter((id) => !formulaRows.some((r) => r.id === id));
  if (oldFormulas.length) {
    await deleteWhere('bookmarks', `item_type=eq.formula&item_id=in.${inList(oldFormulas)}`).catch(() => {});
    await deleteWhere('formulas', `id=in.${inList(oldFormulas)}`);
  }

  // 5. Flashcards.
  console.log('Replacing ch1 flashcards…');
  const cardRows = subtopics.flatMap((s) =>
    s.flashcards.map((c) => ({
      id: c.id,
      chapter_id: 'ch1',
      topic_id: s.id,
      front: c.front,
      back: c.back,
      difficulty: c.difficulty || 'medium',
    })),
  );
  await upsert('flashcards', cardRows);
  // Keep the hand-written cards (fc_0NN): the migration already re-pointed them
  // to their new subtopics and they may carry users' review history. Remove only
  // the auto-generated "What should you remember about …?" cards (fc_ch1_<slug>)
  // and hand-written cards that a new card duplicates.
  const SUPERSEDED_CARDS = new Set(['fc_001']); // = fc_ch1_t1_01 "State Ohm's law …"
  const oldCards = (await selectAll('flashcards?chapter_id=eq.ch1&select=id')).map((r) => r.id)
    .filter((id) => !cardRows.some((r) => r.id === id))
    .filter((id) => id.startsWith('fc_ch1_') || SUPERSEDED_CARDS.has(id));
  if (oldCards.length) {
    await deleteWhere('flashcard_reviews', `card_id=in.${inList(oldCards)}`);
    await deleteWhere('flashcards', `id=in.${inList(oldCards)}`);
  }

  // 6. Questions.
  console.log('Re-pointing existing questions…');
  const byTarget = new Map();
  for (const [qid, tid] of Object.entries(questionTopics)) {
    if (!byTarget.has(tid)) byTarget.set(tid, []);
    byTarget.get(tid).push(qid);
  }
  for (const [tid, qids] of byTarget) {
    await patch('questions', `id=in.${inList(qids)}`, { topic_id: tid });
    await patch('question_attempts', `question_id=in.${inList(qids)}`, { topic_id: tid }).catch(() => {});
  }
  console.log('Inserting new ch1 MCQs…');
  const newQuestions = subtopics.flatMap((s) => s.questions.map((q) => ({ ...q, _topic: s.id })));
  await insertQuestions(newQuestions, () => 'ch1', (q) => q._topic);
  if (extraQuestions.length) {
    console.log(`Importing ${extraQuestions.length} questions from supabase/content/ch9/questions_new.json…`);
    await insertQuestions(extraQuestions, (q) => q.chapterId, (q) => q.topicId);
  }

  // 7. Verify.
  if (dryRun) return console.log('Dry run complete — nothing was written.');
  const [theory, formulas, cards, questions] = await Promise.all([
    selectAll('theory_content?topic_id=like.ch1_*&select=topic_id,concepts'),
    selectAll('formulas?chapter_id=eq.ch1&select=topic_id'),
    selectAll('flashcards?chapter_id=eq.ch1&select=topic_id'),
    selectAll('questions?chapter_id=eq.ch1&select=topic_id'),
  ]);
  const count = (rows, id) => rows.filter((r) => r.topic_id === id).length;
  console.log('\nsubtopic   blocks formulas cards questions');
  for (const s of subtopics) {
    const t = theory.find((r) => r.topic_id === s.id);
    console.log(
      `${s.id.padEnd(10)} ${String(t ? t.concepts.length : 0).padStart(6)} ${String(count(formulas, s.id)).padStart(8)} ` +
      `${String(count(cards, s.id)).padStart(5)} ${String(count(questions, s.id)).padStart(9)}`,
    );
  }
  const orphans = questions.filter((q) => !subtopics.some((s) => s.id === q.topic_id)).length;
  console.log(`\n${questions.length} ch1 questions total, ${orphans} on topics without content.`);
  console.log('Done. Now refresh the test snapshot: node tools/export_supabase_assets.js');
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
