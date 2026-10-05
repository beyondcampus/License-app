-- 20260927_question_progress.sql
--
-- Practice progress: each user's latest Practice-mode answer to every question
-- they have answered. Topic practice (1.1.1) and topic-group practice (1.1)
-- skip the questions whose latest answer is correct, so a user continues with
-- what is wrong or not yet tried.
--
-- The app upserts one row per answer as it is locked in, so leaving a quiz
-- midway loses nothing. Only Practice answers are recorded here.
--
-- Run once in the Supabase SQL Editor. Safe to re-run.

create table if not exists public.question_progress (
  user_id     uuid not null references auth.users(id) on delete cascade,
  -- No foreign key to questions: content scripts may rewrite questions, and a
  -- row for a question that no longer exists is simply ignored by the app.
  question_id text not null,
  is_correct  boolean not null,
  answered_at timestamptz not null default now(),
  primary key (user_id, question_id)
);

alter table public.question_progress enable row level security;

drop policy if exists "own rows" on public.question_progress;
create policy "own rows" on public.question_progress
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update, delete on public.question_progress to authenticated;
grant all on public.question_progress to service_role;

-- Backfill from finished Practice quizzes: the latest answered attempt of each
-- question per user. Rows the app has already written are kept.
insert into public.question_progress (user_id, question_id, is_correct, answered_at)
select distinct on (a.user_id, a.question_id)
       a.user_id, a.question_id, a.is_correct, r.taken_at
from public.question_attempts a
join public.quiz_results r on r.id = a.result_id
where r.mode = 'practice' and a.selected_index >= 0
order by a.user_id, a.question_id, r.taken_at desc
on conflict (user_id, question_id) do nothing;

-- Check: rows per user.
select user_id, count(*) filter (where is_correct) as correct, count(*) as answered
from public.question_progress
group by user_id;
