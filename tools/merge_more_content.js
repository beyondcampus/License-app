// tools/merge_more_content.js
//
// Merges expansion files supabase/content/<chN>/more/<subtopicId>.json into the
// chapter's topic<N>.json files, so validate_content.js and apply_content.js
// handle them unchanged.
//
//   node tools/merge_more_content.js <chN> [--dry-run]
//
// Each more file: {"topicId", "theoryAdd": [blocks], "questions": [mcqs]}.
// - theoryAdd is appended to the subtopic's theory.concepts. Re-running
//   replaces the previously merged blocks (they start at the first heading
//   beginning with "Going Deeper").
// - questions are appended after the subtopic's own questions; ids already
//   present are replaced, so re-running is idempotent.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const chapter = (process.argv[2] || '').match(/^ch\d+$/) ? process.argv[2] : null;
if (!chapter) { console.error('usage: node tools/merge_more_content.js <chN> [--dry-run]'); process.exit(1); }
const dryRun = process.argv.includes('--dry-run');
const dir = path.join(root, 'supabase', 'content', chapter);
const moreDir = path.join(dir, 'more');
if (!fs.existsSync(moreDir)) { console.error(`no ${path.relative(root, moreDir)} folder`); process.exit(1); }

const more = new Map();
for (const f of fs.readdirSync(moreDir).filter((f) => f.endsWith('.json')).sort()) {
  const doc = JSON.parse(fs.readFileSync(path.join(moreDir, f), 'utf8'));
  if (!doc.topicId || !Array.isArray(doc.theoryAdd) || !Array.isArray(doc.questions)) {
    console.error(`${f}: needs topicId, theoryAdd[] and questions[]`); process.exit(1);
  }
  more.set(doc.topicId, doc);
}

const seen = new Set();
for (const f of fs.readdirSync(dir).filter((f) => /^topic\d+\.json$/.test(f)).sort()) {
  const file = path.join(dir, f);
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
  let changed = false;
  for (const sub of doc.subtopics) {
    const add = more.get(sub.id);
    if (!add) continue;
    seen.add(sub.id);
    const concepts = sub.theory.concepts;
    const cut = concepts.findIndex((b) => b.type === 'heading' && /^Going Deeper/i.test(b.text || ''));
    sub.theory.concepts = [...(cut >= 0 ? concepts.slice(0, cut) : concepts), ...add.theoryAdd];
    const newIds = new Set(add.questions.map((q) => q.id));
    const own = sub.questions.filter((q) => !newIds.has(q.id) && !/_m\d+$/.test(q.id));
    sub.questions = [...own, ...add.questions];
    console.log(`${sub.id.padEnd(10)} +${String(add.theoryAdd.length).padStart(2)} blocks  ${String(own.length).padStart(3)} own + ${String(add.questions.length).padStart(3)} new = ${sub.questions.length} questions`);
    changed = true;
  }
  if (changed && !dryRun) fs.writeFileSync(file, JSON.stringify(doc, null, 2) + '\n');
}
const unknown = [...more.keys()].filter((id) => !seen.has(id));
if (unknown.length) { console.error(`not in any topic file: ${unknown.join(', ')}`); process.exit(1); }
console.log(dryRun ? 'dry run: nothing written' : `merged ${seen.size} subtopic file(s)`);
