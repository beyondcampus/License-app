// tools/import_content.js
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://dgzvuidzpfbvvoaivquu.supabase.co';
// Never hard-code this: it bypasses row-level security. Set it in the shell:
//   PowerShell:  $env:SUPABASE_SERVICE_ROLE_KEY = '<service role key>'
//   bash:        export SUPABASE_SERVICE_ROLE_KEY='<service role key>'
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set.');
  process.exit(1);
}

// WARNING: this script upserts EVERYTHING in test/fixtures/content (the snapshot of
// the Supabase content) into Supabase. The snapshot is stale until
// tools/export_supabase_assets.js has been run after the last content change;
// importing a stale one would undo that change (e.g. re-create the ch1 topics the
// 20260923_ch1_topic_hierarchy migration deleted). Pass --force if you really mean it.
if (!process.argv.includes('--force')) {
  console.error('Refusing to run: test/fixtures/content may be older than Supabase. Run');
  console.error('  node tools/export_supabase_assets.js   (to refresh the snapshot from Supabase)');
  console.error('or pass --force if you intend to overwrite Supabase with the snapshot.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function readJson(filename) {
  const filepath = path.join(__dirname, '..', 'test', 'fixtures', 'content', filename);
  return JSON.parse(fs.readFileSync(filepath, 'utf8'));
}

async function importAll() {
  console.log('🚀 Starting idempotent import...');

  // 1. Chapters
  const chapters = readJson('chapters.json');
  const { error: errCh } = await supabase.from('chapters').upsert(chapters);
  if (errCh) throw new Error(`Chapters import failed: ${errCh.message}`);
  console.log(`✅ Chapters upserted (${chapters.length})`);

  // Add this right after inserting chapters in import_content.js
const topicsRaw = readJson('topics.json');

// 1. Upsert into topics table
const topics = topicsRaw.map(t => ({
  id: t.id || t.topic_id || t.topicId,
  chapter_id: t.chapter_id || t.chapterId,
  title: t.title,
  description: t.description || t.title,
  icon: t.icon || null,
  order: t.order || 1
}));

const { error: errTop } = await supabase.from('topics').upsert(topics);
if (errTop) throw new Error(`Topics import failed: ${errTop.message}`);
console.log(`✅ Topics upserted (${topics.length})`);




// Replace the Formulas section in tools/import_content.js with this safe version:

// Fetch all existing valid topic IDs from Supabase first
const { data: validTopics, error: topicFetchErr } = await supabase
  .from('topics')
  .select('id');

if (topicFetchErr) throw new Error(`Failed to fetch topics: ${topicFetchErr.message}`);

const validTopicIds = new Set(validTopics.map(t => t.id));

// Load and filter formulas
const formulasRaw = readJson('formulas.json');
const validFormulas = formulasRaw
  .map(f => ({
    id: f.id,
    chapter_id: f.chapter_id || f.chapterId,
    topic_id: f.topic_id || f.topicId,
    title: f.title,
    description: f.description || '',
    latex: f.latex || null,
    plain_text: f.plain_text || f.plainText || '',
    is_code: !!(f.is_code || f.isCode)
  }))
  .filter(f => validTopicIds.has(f.topic_id)); // Drops formulas with missing topic references

console.log(`Filtered ${formulasRaw.length - validFormulas.length} formulas with missing topic_ids.`);

const { error: errForm } = await supabase.from('formulas').upsert(validFormulas);
if (errForm) throw new Error(`Formulas import failed: ${errForm.message}`);
console.log(`✅ Formulas upserted (${validFormulas.length})`);
  // 3. Flashcards
  const flashcards = readJson('flashcards.json').map(fc => ({
    id: fc.id,
    chapter_id: fc.chapterId,
    topic_id: fc.topicId,
    front: fc.front,
    back: fc.back,
    difficulty: fc.difficulty
  }));
  const { error: errFc } = await supabase.from('flashcards').upsert(flashcards);
  if (errFc) throw new Error(`Flashcards import failed: ${errFc.message}`);
  console.log(`✅ Flashcards upserted (${flashcards.length})`);

  // 4. Theory Content
  const theory = readJson('theory.json').map(t => ({
    topic_id: t.topicId,
    concepts: t.concepts || [],
    formulas: t.formulas || [],
    notes: t.notes || []
  }));
  const { error: errTh } = await supabase.from('theory_content').upsert(theory);
  if (errTh) throw new Error(`Theory upserted failed: ${errTh.message}`);
  console.log(`✅ Theory Content upserted (${theory.length})`);

  // 5. Questions & Question Options
  const questionsRaw = readJson('questions.json');
  const questions = [];
  const options = [];

  for (const q of questionsRaw) {
    questions.push({
      id: q.id,
      chapter_id: q.chapterId,
      topic_id: q.topicId,
      question_text: q.questionText,
      correct_index: q.correctIndex,
      explanation: q.explanation,
      difficulty: q.difficulty,
      formula: q.formula || null,
      code_snippet: q.codeSnippet || null,
      code_language: q.codeLanguage || null
    });

    if (q.options && Array.isArray(q.options)) {
      q.options.forEach((optText, index) => {
        options.push({
          question_id: q.id,
          option_index: index,
          option_text: optText
        });
      });
    }
  }

  const { error: errQ } = await supabase.from('questions').upsert(questions);
  if (errQ) throw new Error(`Questions import failed: ${errQ.message}`);
  console.log(`✅ Questions upserted (${questions.length})`);

  // Clear options for re-run safety before re-inserting
  const qIds = questions.map(q => q.id);
  await supabase.from('question_options').delete().in('question_id', qIds);
  const { error: errOpt } = await supabase.from('question_options').insert(options);
  if (errOpt) throw new Error(`Options import failed: ${errOpt.message}`);
  console.log(`✅ Question Options imported (${options.length})`);

  console.log('🎉 Import completed successfully!');
}

importAll().catch(err => {
  console.error('❌ Import failed:', err);
  process.exit(1);
});