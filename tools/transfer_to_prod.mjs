// tools/transfer_to_prod.mjs — copy all study content from dev_license_app to
// License Exam App (production), keeping production's users and everything
// that belongs to them.
//
//   node tools/transfer_to_prod.mjs                        dry run: does everything in one
//                                                          transaction, prints the report,
//                                                          then ROLLS BACK
//   node tools/transfer_to_prod.mjs --apply                same, then COMMITS
//   ... --allow-user-row-changes                           permit the run even if a user
//                                                          table ends with fewer rows
//
// What it does on production, all in ONE transaction:
//   1. Backs up every public table to schema "backup" (<table>_<timestamp>).
//   2. If production still has the old flat topics, runs the chapter migrations
//      (supabase/migrations/*_topic_hierarchy.sql, ch1 → ch10). They add the
//      topic → subtopic structure and move users' progress and attempts from old
//      topic ids to the new ones.
//   3. Copies chapters, topics, theory, questions (+ options), formulas and
//      flashcards from dev (upsert), and removes production content that dev no
//      longer has.
//   4. Adds the practice-progress table (migrations/20260927_question_progress.sql),
//      backfilled from users' finished Practice quizzes.
//   5. Verifies content now matches dev row for row, and compares every user
//      table's row count before/after. If any user table lost rows it aborts
//      (rollback) unless --allow-user-row-changes is given.
// Accounts (auth.users, profiles) are never touched.
//
// Dev's content is read over its public REST API (read-only). Production needs,
// in .env (git-ignored):
//   PROD_DB_URL=<License Exam App → Connect → Session pooler URI, with the password filled in>
// and node-postgres:  npm install --prefix tools/.deps pg
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DEV_REF = 'dgzvuidzpfbvvoaivquu';
const DEV_REST = `https://${DEV_REF}.supabase.co/rest/v1`;
// Dev's public (anon) key — the same one the app ships with.
const DEV_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRnenZ1aWR6cGZidnZvYWl2cXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMTk5MDAsImV4cCI6MjEwNTg5NTkwMH0.HmWl1EqCWmWVEto0rpHtmufrr1GL0LV5e17xiLb3g80';
const PROD_REF = 'jfazhjvregaluqnxobbd';

export const CONTENT_TABLES = ['chapters', 'topics', 'theory_content', 'questions', 'question_options', 'formulas', 'flashcards'];
const USER_TABLES = ['profiles', 'user_topic_progress', 'bookmarks', 'flashcard_reviews', 'quiz_results', 'question_attempts', 'study_activity', 'question_progress'];
const KEY = { chapters: ['id'], topics: ['id'], theory_content: ['topic_id'], questions: ['id'], formulas: ['id'], flashcards: ['id'] };

const q = (name) => `"${name.replace(/"/g, '""')}"`;

/** The chapter migrations in order: ch1 (20260923) first, then ch2 … ch10. */
export function migrationFiles() {
  const dir = path.join(root, 'supabase', 'migrations');
  return fs.readdirSync(dir)
    .filter((f) => /_ch\d+_topic_hierarchy\.sql$/.test(f))
    .sort((a, b) => Number(a.match(/_ch(\d+)_/)[1]) - Number(b.match(/_ch(\d+)_/)[1]))
    .map((f) => path.join(dir, f));
}

/** A migration file without its own begin/commit: everything runs in our transaction. */
function migrationSql(file) {
  return fs.readFileSync(file, 'utf8').replace(/^\s*(begin|commit)\s*;\s*$/gim, '');
}

/**
 * The transfer itself. [source] holds dev's content rows per table; [db] is the
 * production connection ({ query(sql, params) → rows, exec(sql) }), already
 * inside a transaction. Throws to abort; the caller rolls back.
 */
export async function transfer(db, source, { allowUserRowChanges = false, log = console.log } = {}) {
  const tableExists = async (t) =>
    (await db.query(`select 1 from information_schema.tables where table_schema = 'public' and table_name = $1`, [t])).length > 0;
  const count = async (t) => Number((await db.query(`select count(*)::int as n from public.${q(t)}`))[0].n);
  const columns = async (t) => {
    const rows = await db.query(
      `select column_name, data_type from information_schema.columns where table_schema = 'public' and table_name = $1`, [t]);
    return new Map(rows.map((r) => [r.column_name, r.data_type]));
  };

  // ---- 0. Before ------------------------------------------------------------
  const userBefore = {};
  for (const t of USER_TABLES) if (await tableExists(t)) userBefore[t] = await count(t);
  const accountsBefore = Number((await db.query('select count(*)::int as n from auth.users'))[0].n);
  log(`Production users: ${accountsBefore} accounts`);
  for (const [t, n] of Object.entries(userBefore)) log(`  ${t.padEnd(20)} ${n} rows`);

  // ---- 1. Backup --------------------------------------------------------------
  const stamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14);
  await db.exec('create schema if not exists backup');
  const tables = (await db.query(
    `select table_name from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE' order by 1`))
    .map((r) => r.table_name);
  for (const t of tables) await db.exec(`create table backup.${q(`${t}_${stamp}`)} as select * from public.${q(t)}`);
  log(`\n1. Backed up ${tables.length} tables to schema backup (suffix _${stamp}).`);

  // ---- 2. Structure: chapter migrations --------------------------------------
  const topicCols = await columns('topics');
  if (topicCols.has('parent_topic_id')) {
    log('2. Topic → subtopic structure already present; migrations skipped.');
  } else {
    log('2. Running the chapter migrations (topic → subtopic, users\' history remapped):');
    for (const file of migrationFiles()) {
      const started = Date.now();
      await db.exec(migrationSql(file));
      // Their temp tables are "on commit drop"; inside our one transaction they
      // would collide with the next migration's, so drop them here.
      const temps = await db.query(
        `select relname from pg_class where relnamespace = pg_my_temp_schema() and relkind = 'r'`);
      for (const t of temps) await db.exec(`drop table pg_temp.${q(t.relname)}`);
      log(`   ✓ ${path.basename(file)} (${((Date.now() - started) / 1000).toFixed(1)}s)`);
    }
  }

  // ---- 3. Content from dev ----------------------------------------------------
  log('3. Copying content from dev:');
  const targetCols = {};
  for (const t of CONTENT_TABLES) {
    targetCols[t] = await columns(t);
    const keys = new Set(source[t].flatMap((r) => Object.keys(r)));
    if (t === 'question_options') keys.delete('id'); // identity: production numbers its own rows
    const missing = [...keys].filter((k) => !targetCols[t].has(k));
    if (missing.length) throw new Error(`production ${t} lacks column(s) ${missing.join(', ')} that dev has`);
  }

  async function upsert(table, rows, conflict) {
    if (!rows.length) return;
    const cols = [...new Set(rows.flatMap((r) => Object.keys(r)))].filter((c) => !(table === 'question_options' && c === 'id'));
    const types = targetCols[table];
    const update = cols.filter((c) => !conflict.includes(c));
    const per = Math.max(1, Math.floor(30000 / cols.length));
    for (let i = 0; i < rows.length; i += per) {
      const chunk = rows.slice(i, i + per);
      const params = [];
      const values = chunk.map((row) => `(${cols.map((c) => {
        const type = types.get(c);
        let v = row[c] ?? null;
        if (v !== null && (type === 'jsonb' || type === 'json')) v = JSON.stringify(v);
        params.push(v);
        return `$${params.length}${type === 'jsonb' ? '::jsonb' : type === 'json' ? '::json' : ''}`;
      }).join(', ')})`);
      const onConflict = conflict.length
        ? ` on conflict (${conflict.map(q).join(', ')}) do ${update.length ? `update set ${update.map((c) => `${q(c)} = excluded.${q(c)}`).join(', ')}` : 'nothing'}`
        : '';
      await db.query(`insert into public.${q(table)} (${cols.map(q).join(', ')}) values ${values.join(', ')}${onConflict}`, params);
    }
  }

  await upsert('chapters', source.chapters, KEY.chapters);
  // Parents before subtopics (topics.parent_topic_id references topics).
  await upsert('topics', source.topics.filter((t) => !t.parent_topic_id), KEY.topics);
  await upsert('topics', source.topics.filter((t) => t.parent_topic_id), KEY.topics);
  await upsert('theory_content', source.theory_content, KEY.theory_content);
  await upsert('questions', source.questions, KEY.questions);
  const devQuestionIds = source.questions.map((r) => r.id);
  await db.query('delete from public.question_options where question_id = any($1::text[])', [devQuestionIds]);
  await upsert('question_options', source.question_options, []);
  await upsert('formulas', source.formulas, KEY.formulas);
  await upsert('flashcards', source.flashcards, KEY.flashcards);
  log(`   upserted ${CONTENT_TABLES.map((t) => `${source[t].length} ${t}`).join(', ')}`);

  // Remove production content dev no longer has. Users' rows that point at it:
  // flashcard_reviews go with their card (FK cascade); attempts/progress on a
  // removed question or topic must go first (FK) — the count check below
  // aborts unless --allow-user-row-changes.
  const leftovers = async (table, key, ids) =>
    (await db.query(`select ${q(key)} as id from public.${q(table)} where not (${q(key)} = any($1::text[]))`, [ids])).map((r) => r.id);
  const devIds = (t, k = 'id') => source[t].map((r) => r[k]);
  const oldCards = await leftovers('flashcards', 'id', devIds('flashcards'));
  const oldFormulas = await leftovers('formulas', 'id', devIds('formulas'));
  const oldTheory = await leftovers('theory_content', 'topic_id', devIds('theory_content', 'topic_id'));
  const oldQuestions = await leftovers('questions', 'id', devIds('questions'));
  const oldTopics = await leftovers('topics', 'id', devIds('topics'));
  const oldChapters = await leftovers('chapters', 'id', devIds('chapters'));

  await db.query('delete from public.flashcards where id = any($1::text[])', [oldCards]);
  await db.query('delete from public.formulas where id = any($1::text[])', [oldFormulas]);
  await db.query('delete from public.theory_content where topic_id = any($1::text[])', [oldTheory]);
  await db.query('delete from public.question_attempts where question_id = any($1::text[]) or topic_id = any($2::text[])', [oldQuestions, oldTopics]);
  await db.query('delete from public.questions where id = any($1::text[])', [oldQuestions]);
  await db.query('delete from public.user_topic_progress where topic_id = any($1::text[])', [oldTopics]);
  // Subtopics before their parents.
  await db.query('delete from public.topics where id = any($1::text[]) and parent_topic_id is not null', [oldTopics]);
  await db.query('delete from public.topics where id = any($1::text[])', [oldTopics]);
  await db.query('update public.quiz_results set chapter_id = null where chapter_id = any($1::text[])', [oldChapters]);
  await db.query('delete from public.chapters where id = any($1::text[])', [oldChapters]);
  log(`   removed ${oldCards.length} flashcards, ${oldFormulas.length} formulas, ${oldTheory.length} theory rows, ` +
      `${oldQuestions.length} questions, ${oldTopics.length} topics, ${oldChapters.length} chapters that dev no longer has`);

  // ---- 4. Practice progress table ----------------------------------------------
  await db.exec(fs.readFileSync(path.join(root, 'supabase', 'migrations', '20260927_question_progress.sql'), 'utf8'));
  log('4. question_progress table in place (backfilled from finished Practice quizzes).');

  // ---- 5. Verify ----------------------------------------------------------------
  log('\n5. Verification:');
  let contentOk = true;
  for (const t of CONTENT_TABLES) {
    const n = await count(t);
    const ok = n === source[t].length;
    contentOk &&= ok;
    log(`   ${ok ? '✓' : '✗'} ${t.padEnd(18)} production ${n} / dev ${source[t].length}`);
  }
  if (!contentOk) throw new Error('content does not match dev — rolled back');

  const accountsAfter = Number((await db.query('select count(*)::int as n from auth.users'))[0].n);
  if (accountsAfter !== accountsBefore) throw new Error('auth.users changed — rolled back');
  const lost = [];
  for (const t of USER_TABLES) {
    if (!(await tableExists(t))) continue;
    const after = await count(t);
    const before = userBefore[t];
    const note = before === undefined ? '(new table)' : after < before ? `⚠ ${before - after} fewer` : after > before ? `+${after - before}` : 'unchanged';
    if (before !== undefined && after < before) lost.push(`${t}: ${before} → ${after}`);
    log(`   ${t.padEnd(20)} ${String(before ?? '-').padStart(6)} → ${String(after).padStart(6)}  ${note}`);
  }
  log(`   accounts             ${accountsBefore} → ${accountsAfter}  unchanged`);
  if (lost.length && !allowUserRowChanges) {
    throw new Error(
      `user tables would end with fewer rows (${lost.join('; ')}).\n` +
      'These are rows merged by the migrations (duplicate topics) or tied to removed off-syllabus content.\n' +
      'Every row is kept in the backup schema. Re-run with --allow-user-row-changes to accept.');
  }
  return { lost };
}

// ---------------------------------------------------------------------------
// CLI: dev and production over node-postgres.
// ---------------------------------------------------------------------------
function loadPg() {
  const require = createRequire(import.meta.url);
  for (const from of [import.meta.url, path.join(root, 'tools', '.deps', 'x'), ...(process.env.NODE_PATH || '').split(path.delimiter).filter(Boolean).map((p) => path.join(p, 'x'))]) {
    try { return (from === import.meta.url ? require : createRequire(from))('pg'); } catch {}
  }
  console.error('node-postgres not found. Run:  npm install --prefix tools/.deps pg');
  process.exit(1);
}

function readProdConfig() {
  const env = fs.readFileSync(path.join(root, '.env'), 'utf8').replace(/\r/g, '');
  const prodLine = env.split('\n').map((l) => l.trim()).find((l) => l.startsWith('PROD_DB_URL='));
  if (!prodLine) throw new Error('.env: add PROD_DB_URL=<License Exam App Session pooler URI with password>');
  // Parsed by hand, not with URL(): a password pasted as-is may contain
  // @ # / ? that a URL parser would split on. The password runs up to the
  // last "@"; percent-encoded passwords are decoded.
  const value = prodLine.slice('PROD_DB_URL='.length).trim().replace(/^["']|["']$/g, '');
  const m = value.match(/^postgres(?:ql)?:\/\/([^:/@]+):(.*)@([^@/:]+)(?::(\d+))?\/([^/?#]*)$/);
  if (!m) throw new Error('PROD_DB_URL must look like postgresql://<user>:<password>@<host>:5432/postgres');
  const [, user, rawPassword, host, port, database] = m;
  if (!`${user}@${host}`.includes(PROD_REF)) throw new Error(`PROD_DB_URL must be License Exam App (${PROD_REF})`);
  let password = rawPassword;
  if (/%[0-9A-Fa-f]{2}/.test(password)) { try { password = decodeURIComponent(password); } catch {} }
  return { host, port: Number(port || 5432), database: database || 'postgres', user, password, ssl: { rejectUnauthorized: false } };
}

/** All rows of a dev content table over REST, in pages of 1,000. */
async function devRows(table) {
  const select = table === 'question_options' ? 'question_id,option_index,option_text' : '*';
  const order = { theory_content: 'topic_id', question_options: 'question_id,option_index' }[table] || 'id';
  const rows = [];
  for (let from = 0; ; from += 1000) {
    const res = await fetch(`${DEV_REST}/${table}?select=${select}&order=${order}`, {
      headers: { apikey: DEV_ANON, Authorization: `Bearer ${DEV_ANON}`, Range: `${from}-${from + 999}`, 'Range-Unit': 'items' },
    });
    if (!res.ok) throw new Error(`dev ${table}: ${res.status} ${await res.text()}`);
    const page = await res.json();
    rows.push(...page);
    if (page.length < 1000) return rows;
  }
}

async function main() {
  const apply = process.argv.includes('--apply');
  const allowUserRowChanges = process.argv.includes('--allow-user-row-changes');
  const { Client } = loadPg();
  const prodConfig = readProdConfig();

  const source = {};
  for (const t of CONTENT_TABLES) source[t] = await devRows(t);
  console.log(`Dev (${DEV_REF}): ${CONTENT_TABLES.map((t) => `${source[t].length} ${t}`).join(', ')}\n`);

  const prod = new Client({ ...prodConfig, connectionTimeoutMillis: 15000 });
  await prod.connect();
  const db = {
    query: async (sql, params) => (await prod.query(sql, params)).rows,
    exec: async (sql) => { await prod.query(sql); },
  };
  console.log(`Production (${PROD_REF}) — ${apply ? 'APPLY' : 'DRY RUN (rolled back at the end)'}\n`);
  await prod.query('begin');
  // Fail fast instead of hanging if a live app session holds a lock we need;
  // the error then names the waiting step. No limit on the statements' own time.
  await prod.query("set local lock_timeout = '20s'");
  await prod.query("set local statement_timeout = 0");
  try {
    await transfer(db, source, { allowUserRowChanges });
    if (apply) {
      await prod.query('commit');
      console.log('\nCommitted. Production now has dev\'s content; users and their data kept.');
    } else {
      await prod.query('rollback');
      console.log('\nDry run OK — rolled back, nothing changed. Run again with --apply to commit.');
    }
  } catch (e) {
    await prod.query('rollback');
    console.error(`\nAborted, rolled back — production unchanged.\n${e.message}`);
    process.exitCode = 1;
  } finally {
    await prod.end();
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
