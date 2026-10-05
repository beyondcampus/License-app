// tools/dev_db.mjs — set up and roll out on the DEV Supabase project (dev_license_app).
//
// Direct Postgres access, so it can run DDL. Reads the dev connection from .env
// (the "postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres" line;
// a URL-encoded password is decoded) and connects through the Session pooler,
// because the direct host is IPv6-only.
//
//   node tools/dev_db.mjs schema      apply supabase/schema/schema.sql (empty project only)
//   node tools/dev_db.mjs content     copy content tables from production (read-only there)
//   node tools/dev_db.mjs migrate [chN]  run supabase/migrations/*_<chN>_topic_hierarchy.sql (default ch1)
//   node tools/dev_db.mjs status      what the dev DB currently holds
//   node tools/dev_db.mjs reset       drop everything in public (dev only — asks for --yes)
//   node tools/dev_db.mjs all         schema → content → migrate
//
// After `migrate`, upload the Chapter 1 content over the dev REST API:
//   $env:SUPABASE_URL='https://<dev ref>.supabase.co'; $env:SUPABASE_SERVICE_ROLE_KEY='<dev service key>'
//   node tools/apply_ch1_content.js
//   node tools/export_supabase_assets.js   (with SUPABASE_URL and SUPABASE_KEY=<dev publishable key>)
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PROD_REST = 'https://jfazhjvregaluqnxobbd.supabase.co/rest/v1';
const PROD_PUBLISHABLE = 'sb_publishable_Kd7cwmV7dMhra8sJMhI5EA_Mw8rFCZq';
const POOLER_REGION = process.env.DEV_POOLER_REGION || 'ap-northeast-1';
const CONTENT_TABLES = ['chapters', 'topics', 'theory_content', 'questions', 'question_options', 'formulas', 'flashcards'];

// node-postgres lives in the scratchpad install, or anywhere on NODE_PATH.
const require = createRequire(import.meta.url);
let pg;
try { pg = require('pg'); } catch {
  const candidates = (process.env.NODE_PATH || '').split(path.delimiter).filter(Boolean);
  for (const c of candidates) { try { pg = createRequire(path.join(c, 'x'))('pg'); break; } catch {} }
  if (!pg) { console.error('node-postgres not found: npm install pg (or set NODE_PATH)'); process.exit(1); }
}

function devConfig() {
  const env = fs.readFileSync(path.join(root, '.env'), 'utf8').replace(/\r/g, '');
  const line = env.split('\n').find((l) => /^postgres(ql)?:\/\//.test(l.trim()));
  const m = line && line.trim().match(/^postgres(?:ql)?:\/\/postgres:(.*)@db\.([a-z0-9]+)\.supabase\.co:5432\/postgres$/);
  if (!m) { console.error('.env needs the direct dev connection string (postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres)'); process.exit(1); }
  let password = m[1];
  try { password = decodeURIComponent(password); } catch {}
  return {
    ref: m[2],
    client: { host: `aws-0-${POOLER_REGION}.pooler.supabase.com`, port: 5432, database: 'postgres', user: `postgres.${m[2]}`, password, ssl: { rejectUnauthorized: false }, connectionTimeoutMillis: 10000 },
  };
}

async function fetchProd(table) {
  const rows = [];
  for (let from = 0; ; from += 1000) {
    const res = await fetch(`${PROD_REST}/${table}?select=*&order=${table === 'theory_content' ? 'topic_id' : 'id'}`, { headers: { apikey: PROD_PUBLISHABLE, Range: `${from}-${from + 999}`, 'Range-Unit': 'items' } });
    if (!res.ok) throw new Error(`prod ${table}: ${res.status} ${await res.text()}`);
    const page = await res.json();
    rows.push(...page);
    if (page.length < 1000) return rows;
  }
}

async function tables(db) {
  return (await db.query(`select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE' order by 1`)).rows.map((r) => r.table_name);
}

const commands = {
  async status(db) {
    const t = await tables(db);
    if (!t.length) return console.log('dev DB: empty (no public tables)');
    for (const name of t) {
      const n = (await db.query(`select count(*)::int n from public.${JSON.stringify(name)}`)).rows[0].n;
      console.log(`  ${name.padEnd(22)} ${n}`);
    }
    if (t.includes('topics')) {
      const p = (await db.query(`select count(*)::int n from public.topics where id like 'ch1\\_p%'`)).rows[0].n;
      console.log(`Chapter 1 migration: ${p === 7 ? 'applied' : 'not applied'}`);
    }
  },

  async schema(db) {
    const file = path.join(root, 'supabase', 'schema', 'schema.sql');
    if (!fs.existsSync(file)) { console.error(`missing ${path.relative(root, file)} — the versioned schema file is missing`); process.exit(1); }
    if ((await tables(db)).length) { console.error('dev DB already has tables; run `reset --yes` first if you want a clean clone'); process.exit(1); }
    const ddl = fs.readFileSync(file, 'utf8');
    await db.query('begin');
    try { await db.query(ddl); await db.query('commit'); } catch (e) { await db.query('rollback'); throw e; }
    console.log(`schema applied: ${(await tables(db)).length} tables`);
  },

  async content(db) {
    const have = await tables(db);
    const missing = CONTENT_TABLES.filter((t) => !have.includes(t));
    if (missing.length) { console.error(`dev DB lacks tables: ${missing.join(', ')} — run schema first`); process.exit(1); }
    for (const t of CONTENT_TABLES) {
      const n = (await db.query(`select count(*)::int n from public.${t}`)).rows[0].n;
      if (n) { console.error(`dev ${t} already has ${n} rows — refusing to copy on top (reset first)`); process.exit(1); }
    }
    const data = {};
    for (const t of CONTENT_TABLES) { data[t] = await fetchProd(t); console.log(`  fetched prod ${t}: ${data[t].length}`); }
    const cols = {};
    for (const r of (await db.query(`select table_name, column_name from information_schema.columns where table_schema='public'`)).rows) (cols[r.table_name] ??= new Set()).add(r.column_name);
    await db.query('begin');
    try {
      for (const t of CONTENT_TABLES) {
        for (const row of data[t]) {
          const keys = Object.keys(row).filter((k) => cols[t].has(k) && !(t === 'question_options' && k === 'id'));
          const vals = keys.map((k) => (row[k] !== null && typeof row[k] === 'object' ? JSON.stringify(row[k]) : row[k]));
          await db.query(`insert into public.${t} (${keys.map((k) => `"${k}"`).join(',')}) values (${keys.map((_, i) => `$${i + 1}`).join(',')})`, vals);
        }
        console.log(`  inserted dev ${t}: ${data[t].length}`);
      }
      await db.query('commit');
    } catch (e) { await db.query('rollback'); throw e; }
  },

  async migrate(db) {
    // node tools/dev_db.mjs migrate [chN] — default ch1. Applies
    // supabase/migrations/*_<chN>_topic_hierarchy.sql unless <chN>_p1 already exists.
    const chapter = process.argv[3] || 'ch1';
    const file = fs.readdirSync(path.join(root, 'supabase', 'migrations')).filter((f) => f.endsWith(`_${chapter}_topic_hierarchy.sql`)).sort().pop();
    if (!file) { console.error(`no migration for ${chapter} in supabase/migrations`); process.exit(1); }
    const applied = (await db.query(`select count(*)::int n from public.topics where id = $1`, [`${chapter}_p1`])).rows[0].n === 1;
    if (applied) return console.log(`${chapter} migration already applied on dev`);
    const sql = fs.readFileSync(path.join(root, 'supabase', 'migrations', file), 'utf8');
    const res = await db.query(sql); // the file has its own begin/commit
    const last = Array.isArray(res) ? res[res.length - 1] : res;
    console.log(`${file} applied; verification rows:`);
    for (const r of last.rows) console.log(`  ${String(r.topic_no).padStart(2)} ${r.id.padEnd(8)} ${String(r.questions).padStart(3)}q ${String(r.flashcards).padStart(2)}fc ${String(r.formulas).padStart(2)}f ${String(r.concept_blocks ?? 0).padStart(3)}blk  ${r.subtopic}`);
  },

  async reset(db) {
    if (!process.argv.includes('--yes')) { console.error('reset drops every public table in the DEV project; re-run with --yes'); process.exit(1); }
    const cfg = devConfig();
    if (cfg.ref === 'jfazhjvregaluqnxobbd') { console.error('refusing: this is the PRODUCTION project'); process.exit(1); }
    await db.query('drop schema public cascade; create schema public; drop schema if exists backup cascade; grant usage on schema public to anon, authenticated, service_role; grant all on schema public to postgres;');
    console.log('dev public schema dropped and recreated');
  },

  async all(db) { await commands.schema(db); await commands.content(db); await commands.migrate(db); },
};

const cmd = process.argv[2];
if (!commands[cmd]) { console.error(`usage: node tools/dev_db.mjs <${Object.keys(commands).join('|')}>`); process.exit(1); }
const cfg = devConfig();
if (cfg.ref === 'jfazhjvregaluqnxobbd' && cmd !== 'status') { console.error('refusing to run against the PRODUCTION project'); process.exit(1); }
const db = new pg.Client(cfg.client);
await db.connect();
console.log(`dev project ${cfg.ref} via ${cfg.client.host}`);
try { await commands[cmd](db); } catch (e) { console.error(e.message); process.exitCode = 1; } finally { await db.end(); }
