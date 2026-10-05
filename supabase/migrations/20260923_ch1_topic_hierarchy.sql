-- =====================================================================
-- Chapter 1 restructure: Chapter -> Topic (parent) -> Subtopic
--
-- * Adds topics.parent_topic_id (NULL = top-level topic).
-- * Creates 7 parent topics ch1_p1..ch1_p7 and the new subtopic IDs.
-- * Moves questions, flashcards, formulas, theory_content,
--   user_topic_progress and question_attempts from old IDs to new IDs.
--   Old and new IDs overlap with different meanings (e.g. old ch1_i13 =
--   "Voltage..." but new ch1_i13 = "Series & Parallel"), so everything
--   is routed through temporary 'tmp_' IDs first.
-- * Drops t7 Transformers, t8 Measurements, t12 Rectifiers (not in the NEC
--   syllabus). t11 Op-Amps IS in the syllabus (1.6) and is kept as ch1_i65.
-- * Merges duplicates: t4+i20(+i28) -> i25, t9+i22 -> i42, t10+i23 -> i43.
--
-- Runs as a single transaction. Backups are written to schema "backup"
-- (not exposed through the API). Run in the Supabase SQL Editor.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 0. Backups
-- ---------------------------------------------------------------------
create schema if not exists backup;
create table backup.ch1_topics_20260923          as select * from public.topics              where chapter_id = 'ch1';
create table backup.ch1_theory_content_20260923  as select * from public.theory_content      where topic_id like 'ch1\_%';
create table backup.ch1_questions_20260923       as select * from public.questions           where chapter_id = 'ch1';
create table backup.ch1_question_options_20260923 as select o.* from public.question_options o join public.questions q on q.id = o.question_id where q.chapter_id = 'ch1';
create table backup.ch1_flashcards_20260923      as select * from public.flashcards          where chapter_id = 'ch1';
create table backup.ch1_flashcard_reviews_20260923 as select r.* from public.flashcard_reviews r join public.flashcards f on f.id = r.card_id where f.chapter_id = 'ch1';
create table backup.ch1_formulas_20260923        as select * from public.formulas            where chapter_id = 'ch1';
create table backup.ch1_progress_20260923        as select * from public.user_topic_progress where topic_id like 'ch1\_%';
create table backup.ch1_attempts_20260923        as select * from public.question_attempts   where chapter_id = 'ch1';

-- ---------------------------------------------------------------------
-- 1. Schema: parent_topic_id
-- ---------------------------------------------------------------------
alter table public.topics
  add column if not exists parent_topic_id text references public.topics(id);
create index if not exists topics_parent_topic_id_idx on public.topics(parent_topic_id);

-- ---------------------------------------------------------------------
-- 2. Drop off-syllabus topics (and exact duplicates of i28's children)
-- ---------------------------------------------------------------------
create temp table drop_topics(id text primary key) on commit drop;
insert into drop_topics values ('ch1_t7'), ('ch1_t8'), ('ch1_t12');

delete from public.question_attempts where topic_id in (select id from drop_topics)
   or question_id in (select id from public.questions where topic_id in (select id from drop_topics));
delete from public.question_options  where question_id in (select id from public.questions where topic_id in (select id from drop_topics));
delete from public.questions         where topic_id in (select id from drop_topics);
delete from public.flashcard_reviews where card_id in (select id from public.flashcards where topic_id in (select id from drop_topics) or topic_id = 'ch1_i28');
delete from public.flashcards        where topic_id in (select id from drop_topics) or topic_id = 'ch1_i28';
delete from public.formulas          where topic_id in (select id from drop_topics) or topic_id = 'ch1_i28';
delete from public.theory_content    where topic_id in (select id from drop_topics);
delete from public.user_topic_progress where topic_id in (select id from drop_topics);

-- ---------------------------------------------------------------------
-- 3. Final topic tree (id, parent, title, order within its level)
-- ---------------------------------------------------------------------
create temp table new_topics(id text primary key, parent text, title text, ord int) on commit drop;
insert into new_topics values
  ('ch1_p1', null,     'Basic Concepts', 1),
    ('ch1_t1',  'ch1_p1', 'Ohm''s Law & Basic Concepts', 1),
    ('ch1_i11', 'ch1_p1', 'Electric Voltage, Current, Power & Energy', 2),
    ('ch1_i12', 'ch1_p1', 'Conducting & Insulating Materials', 3),
    ('ch1_i13', 'ch1_p1', 'Series & Parallel Circuits', 4),
    ('ch1_i14', 'ch1_p1', 'Star-Delta & Delta-Star Conversion', 5),
    ('ch1_i15', 'ch1_p1', 'Types of Circuits', 6),
  ('ch1_p2', null,     'Network Theorems', 2),
    ('ch1_t2',  'ch1_p2', 'Kirchhoff''s Laws & Network Theorems', 1),
    ('ch1_i21', 'ch1_p2', 'Superposition Theorem', 2),
    ('ch1_i22', 'ch1_p2', 'Thevenin''s Theorem', 3),
    ('ch1_i23', 'ch1_p2', 'Norton''s Theorem', 4),
    ('ch1_i24', 'ch1_p2', 'Maximum Power Transfer Theorem', 5),
    ('ch1_i25', 'ch1_p2', 'R-L, R-C, R-L-C Circuits', 6),
    ('ch1_i26', 'ch1_p2', 'Resonance in AC Circuits', 7),
    ('ch1_i27', 'ch1_p2', 'Active and Reactive Power', 8),
  ('ch1_p3', null,     'Alternating Current Fundamentals', 3),
    ('ch1_t3',  'ch1_p3', 'Alternating Current Fundamentals', 1),
    ('ch1_i31', 'ch1_p3', 'Generation of AC Voltage & Current', 2),
    ('ch1_i32', 'ch1_p3', 'Peak, Average, and RMS Values', 3),
    ('ch1_i33', 'ch1_p3', 'Three Phase System', 4),
  ('ch1_p4', null,     'Semiconductor Devices', 4),
    ('ch1_t4',  'ch1_p4', 'Semiconductor Devices', 1),
    ('ch1_i41', 'ch1_p4', 'Semiconductor Basics', 2),
    ('ch1_i42', 'ch1_p4', 'Semiconductor Diode', 3),
    ('ch1_i43', 'ch1_p4', 'Bipolar Junction Transistor (BJT)', 4),
    ('ch1_i44', 'ch1_p4', 'MOSFET (Metal-Oxide-Semiconductor FET)', 5),
    ('ch1_i45', 'ch1_p4', 'CMOS (Complementary MOS)', 6),
    ('ch1_i46', 'ch1_p4', 'BJT Small- and Large-Signal Models', 7),
  ('ch1_p5', null,     'Signal Generators', 5),
    ('ch1_t5',  'ch1_p5', 'Signal Generators', 1),
    ('ch1_i51', 'ch1_p5', 'Oscillator Basics', 2),
    ('ch1_i52', 'ch1_p5', 'RC Oscillators', 3),
    ('ch1_i53', 'ch1_p5', 'LC Oscillators', 4),
    ('ch1_i54', 'ch1_p5', 'Crystal Oscillator', 5),
    ('ch1_i55', 'ch1_p5', 'Waveform Generators', 6),
  ('ch1_p6', null,     'Amplifiers', 6),
    ('ch1_t6',  'ch1_p6', 'Amplifiers', 1),
    ('ch1_i61', 'ch1_p6', 'Amplifier Basics', 2),
    ('ch1_i62', 'ch1_p6', 'Classification of Output Stages', 3),
    ('ch1_i63', 'ch1_p6', 'Comparison of Amplifier Classes', 4),
    ('ch1_i64', 'ch1_p6', 'Biasing Class AB Output Stage', 5),
    ('ch1_i65', 'ch1_p6', 'Operational Amplifiers', 6),
    ('ch1_i66', 'ch1_p6', 'Power BJTs & Transformer-Coupled Push-Pull Stages', 7),
    ('ch1_i67', 'ch1_p6', 'Tuned Amplifiers', 8),
  ('ch1_p7', null,     'Quick Revision - Entire Chapter', 7),
    ('ch1_i71', 'ch1_p7', 'Important Formulas', 1);

-- Old ID -> new ID. "seq" orders theory blocks when several old topics merge.
create temp table id_map(old_id text primary key, new_id text, seq int) on commit drop;
insert into id_map values
  ('ch1_t1',  'ch1_t1',  1),
  ('ch1_i13', 'ch1_i11', 1),
  ('ch1_i14', 'ch1_i12', 1),
  ('ch1_i15', 'ch1_i13', 1),
  ('ch1_i16', 'ch1_i14', 1),
  ('ch1_i17', 'ch1_i15', 1),
  ('ch1_t2',  'ch1_t2',  1),
  ('ch1_i18', 'ch1_i22', 1),
  ('ch1_i19', 'ch1_i24', 1),
  ('ch1_t4',  'ch1_i25', 1),
  ('ch1_i20', 'ch1_i25', 2),
  ('ch1_i28', 'ch1_i25', 3),   -- exact duplicate of i20; its theory is skipped below
  ('ch1_t5',  'ch1_i26', 1),
  ('ch1_t6',  'ch1_i27', 1),
  ('ch1_t3',  'ch1_t3',  1),
  ('ch1_i21', 'ch1_i31', 1),
  ('ch1_t9',  'ch1_i42', 1),
  ('ch1_i22', 'ch1_i42', 2),
  ('ch1_t10', 'ch1_i43', 1),
  ('ch1_i23', 'ch1_i43', 2),
  ('ch1_i24', 'ch1_i44', 1),
  ('ch1_i25', 'ch1_i51', 1),
  ('ch1_i26', 'ch1_i52', 1),
  ('ch1_i27', 'ch1_i63', 1),
  ('ch1_t11', 'ch1_i65', 1);   -- op-amps: syllabus 1.6, keep the hand-written content

-- Safety: every remaining ch1 topic must be mapped.
do $$
declare missing text;
begin
  select string_agg(id, ', ') into missing
  from public.topics
  where chapter_id = 'ch1'
    and id not in (select old_id from id_map)
    and id not in (select id from drop_topics);
  if missing is not null then
    raise exception 'Unmapped ch1 topics: %', missing;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 4. Stage: temporary topics, repoint children to tmp_ IDs
-- ---------------------------------------------------------------------
insert into public.topics (id, chapter_id, title, description, icon, "order")
select distinct 'tmp_' || new_id, 'ch1', 'tmp', 'tmp', null, 0 from id_map;

update public.questions           q set topic_id = 'tmp_' || m.new_id from id_map m where q.topic_id = m.old_id;
update public.question_attempts   a set topic_id = 'tmp_' || m.new_id from id_map m where a.topic_id = m.old_id;
update public.flashcards          f set topic_id = 'tmp_' || m.new_id from id_map m where f.topic_id = m.old_id;
update public.formulas            f set topic_id = 'tmp_' || m.new_id from id_map m where f.topic_id = m.old_id;

-- Progress: merge per user (several old topics may collapse into one).
create temp table progress_stage on commit drop as
select p.user_id,
       'tmp_' || m.new_id           as topic_id,
       bool_or(p.completed)         as completed,
       max(p.completion_pct)        as completion_pct,
       max(p.last_studied_at)       as last_studied_at
from public.user_topic_progress p
join id_map m on m.old_id = p.topic_id
group by p.user_id, m.new_id;
delete from public.user_topic_progress where topic_id in (select old_id from id_map);
insert into public.user_topic_progress (user_id, topic_id, completed, completion_pct, last_studied_at)
select user_id, topic_id, completed, completion_pct, last_studied_at from progress_stage;

-- Theory: concatenate block arrays in seq order (i28 skipped: duplicate).
create temp table theory_stage on commit drop as
select 'tmp_' || m.new_id as topic_id,
       coalesce(jsonb_agg(e.b order by m.seq, e.n) filter (where e.kind = 'concepts'), '[]'::jsonb) as concepts,
       coalesce(jsonb_agg(e.b order by m.seq, e.n) filter (where e.kind = 'formulas'), '[]'::jsonb) as formulas,
       coalesce(jsonb_agg(e.b order by m.seq, e.n) filter (where e.kind = 'notes'),    '[]'::jsonb) as notes
from public.theory_content t
join id_map m on m.old_id = t.topic_id and m.old_id <> 'ch1_i28'
cross join lateral (
  select 'concepts' as kind, x.b, x.n from jsonb_array_elements(coalesce(t.concepts, '[]')) with ordinality x(b, n)
  union all
  select 'formulas', x.b, x.n from jsonb_array_elements(coalesce(t.formulas, '[]')) with ordinality x(b, n)
  union all
  select 'notes',    x.b, x.n from jsonb_array_elements(coalesce(t.notes, '[]'))    with ordinality x(b, n)
) e
group by m.new_id;
delete from public.theory_content where topic_id in (select old_id from id_map);
insert into public.theory_content (topic_id, concepts, formulas, notes)
select topic_id, concepts, formulas, notes from theory_stage;

-- ---------------------------------------------------------------------
-- 5. Replace old ch1 topics with the final tree
-- ---------------------------------------------------------------------
delete from public.topics
where chapter_id = 'ch1' and id not like 'tmp\_%';

-- Parents first (FK on parent_topic_id), then subtopics.
insert into public.topics (id, chapter_id, title, description, icon, "order", parent_topic_id)
select id, 'ch1', title, title, null, ord, parent from new_topics where parent is null;
insert into public.topics (id, chapter_id, title, description, icon, "order", parent_topic_id)
select id, 'ch1', title, title, null, ord, parent from new_topics where parent is not null;

-- ---------------------------------------------------------------------
-- 6. Repoint children tmp_ -> final, drop temporary topics
-- ---------------------------------------------------------------------
update public.questions           set topic_id = substr(topic_id, 5) where topic_id like 'tmp\_ch1\_%';
update public.question_attempts   set topic_id = substr(topic_id, 5) where topic_id like 'tmp\_ch1\_%';
update public.flashcards          set topic_id = substr(topic_id, 5) where topic_id like 'tmp\_ch1\_%';
update public.formulas            set topic_id = substr(topic_id, 5) where topic_id like 'tmp\_ch1\_%';
update public.user_topic_progress set topic_id = substr(topic_id, 5) where topic_id like 'tmp\_ch1\_%';
update public.theory_content      set topic_id = substr(topic_id, 5) where topic_id like 'tmp\_ch1\_%';

delete from public.topics where id like 'tmp\_ch1\_%';

commit;

-- ---------------------------------------------------------------------
-- 7. Verification (runs after commit; shown as the editor's result)
-- ---------------------------------------------------------------------
select coalesce(p."order", t."order") as topic_no,
       coalesce(p.title, t.title)     as topic,
       t.id, t.title as subtopic,
       (select count(*) from public.questions  q where q.topic_id = t.id) as questions,
       (select count(*) from public.flashcards f where f.topic_id = t.id) as flashcards,
       (select count(*) from public.formulas   f where f.topic_id = t.id) as formulas,
       (select coalesce(jsonb_array_length(c.concepts), 0) from public.theory_content c where c.topic_id = t.id) as concept_blocks
from public.topics t
left join public.topics p on p.id = t.parent_topic_id
where t.chapter_id = 'ch1'
order by coalesce(p."order", t."order"), t.parent_topic_id nulls first, t."order";
