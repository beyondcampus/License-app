// tools/export_supabase_assets.js
//
// Snapshots the Supabase content into test/fixtures/content/*.json, the data the
// Flutter tests run on. The app itself ships no content — it reads everything from
// Supabase. Read-only against Supabase; uses the public (publishable) key unless
// SUPABASE_KEY is set. Run after every content change:
//
//   node tools/export_supabase_assets.js [--out <dir>]
//   node tools/validate_assets.js
//
// --out writes somewhere other than test/fixtures/content (e.g. to inspect a dry run).
// Output is sorted deterministically so diffs stay small.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const outIdx = process.argv.indexOf('--out');
const dataDir = outIdx >= 0 ? path.resolve(process.argv[outIdx + 1]) : path.join(root, 'test', 'fixtures', 'content');
fs.mkdirSync(dataDir, { recursive: true });
const URL_BASE = (process.env.SUPABASE_URL || 'https://dgzvuidzpfbvvoaivquu.supabase.co') + '/rest/v1';
const KEY = process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRnenZ1aWR6cGZidnZvYWl2cXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMTk5MDAsImV4cCI6MjEwNTg5NTkwMH0.HmWl1EqCWmWVEto0rpHtmufrr1GL0LV5e17xiLb3g80';

// Pages of 1,000 (the API's row cap). `order` makes paging deterministic: without a
// stable sort, pages of a large table can overlap or skip rows.
async function selectAll(table, query = 'select=*', order = 'id') {
  const rows = [];
  for (let from = 0; ; from += 1000) {
    const res = await fetch(`${URL_BASE}/${table}?${query}&order=${order}`, {
      headers: { apikey: KEY, Authorization: `Bearer ${KEY}`, Range: `${from}-${from + 999}`, 'Range-Unit': 'items' },
    });
    if (!res.ok) throw new Error(`${table}: ${res.status} ${await res.text()}`);
    const page = await res.json();
    rows.push(...page);
    if (page.length < 1000) return rows;
  }
}

const byId = (a, b) => String(a.id).localeCompare(String(b.id));
const byOrder = (a, b) => (a.order ?? 0) - (b.order ?? 0) || byId(a, b);
const compact = (obj) => Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== null && v !== undefined));
const write = (file, value) => {
  fs.writeFileSync(path.join(dataDir, file), `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  console.log(`  ${file.padEnd(16)} ${value.length} entries`);
};

async function main() {
  console.log(`Exporting from ${URL_BASE} → ${path.relative(root, dataDir)}`);
  const [chapters, topics, theory, questions, options, formulas, flashcards] = await Promise.all([
    selectAll('chapters'),
    selectAll('topics'),
    selectAll('theory_content', 'select=*', 'topic_id'),
    selectAll('questions'),
    selectAll('question_options', 'select=question_id,option_index,option_text', 'question_id,option_index'),
    selectAll('formulas'),
    selectAll('flashcards'),
  ]);

  const theoryByTopic = new Map(theory.map((t) => [t.topic_id, t]));
  const topicsWithFormulaRows = new Set(formulas.map((f) => f.topic_id));

  write('chapters.json', chapters.sort(byOrder).map((c) => compact({
    id: c.id, title: c.title, description: c.description, emoji: c.emoji, icon: c.icon, order: c.order,
  })));

  write('topics.json', topics.sort(byOrder).map((t) => {
    const th = theoryByTopic.get(t.id);
    return compact({
      id: t.id,
      chapterId: t.chapter_id,
      title: t.title,
      subtitle: t.description && t.description !== t.title ? t.description : '',
      order: t.order,
      parentTopicId: t.parent_topic_id,
      hasFormulas: Boolean((th && th.formulas && th.formulas.length) || topicsWithFormulaRows.has(t.id)),
      hasNotes: Boolean(th && th.notes && th.notes.length),
    });
  }));

  write('theory.json', theory.sort((a, b) => a.topic_id.localeCompare(b.topic_id)).map((t) => ({
    topicId: t.topic_id, concepts: t.concepts || [], formulas: t.formulas || [], notes: t.notes || [],
  })));

  const optionsByQuestion = new Map();
  for (const o of options) {
    if (!optionsByQuestion.has(o.question_id)) optionsByQuestion.set(o.question_id, []);
    optionsByQuestion.get(o.question_id).push(o);
  }
  const dropped = [];
  write('questions.json', questions.sort(byId).flatMap((q) => {
    const opts = (optionsByQuestion.get(q.id) || []).sort((a, b) => a.option_index - b.option_index).map((o) => o.option_text);
    if (opts.length < 2) { dropped.push(q.id); return []; }
    return [compact({
      id: q.id,
      chapterId: q.chapter_id,
      topicId: q.topic_id,
      questionText: q.question_text,
      options: opts,
      correctIndex: q.correct_index,
      explanation: q.explanation ?? '',
      difficulty: q.difficulty || 'medium',
      formula: q.formula,
      codeSnippet: q.code_snippet,
      codeLanguage: q.code_language,
    })];
  }));
  if (dropped.length) console.log(`  skipped ${dropped.length} question(s) without options: ${dropped.slice(0, 5).join(', ')}`);

  write('formulas.json', formulas.sort(byId).map((f) => compact({
    id: f.id, chapterId: f.chapter_id, topicId: f.topic_id, title: f.title,
    description: f.description ?? '', latex: f.latex, plainText: f.plain_text ?? '', isCode: Boolean(f.is_code),
  })));

  write('flashcards.json', flashcards.sort(byId).map((c) => ({
    id: c.id, chapterId: c.chapter_id, topicId: c.topic_id, front: c.front, back: c.back, difficulty: c.difficulty || 'medium',
  })));

  console.log('Done. Next: node tools/validate_assets.js && flutter test test/data/content_source_test.dart');
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
