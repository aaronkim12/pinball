-- 台灣彈珠台 leaderboard schema
-- Run this once in the Supabase SQL Editor.

create table if not exists public.scores (
  name text primary key,
  score bigint not null check (score >= 0 and score < 1000000000),
  updated_at timestamptz not null default now(),
  constraint name_len check (char_length(name) between 1 and 12)
);

alter table public.scores enable row level security;

create policy "public read"   on public.scores for select using (true);
create policy "public insert" on public.scores for insert with check (true);
create policy "public update" on public.scores for update using (true) with check (true);

-- A score can only ever go UP. Lower/equal submissions are silently ignored,
-- so nobody can wipe someone's record by submitting a smaller number.
create or replace function public.scores_keep_highest() returns trigger
language plpgsql as $$
begin
  if new.score <= old.score then
    return null;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_scores_keep_highest on public.scores;
create trigger trg_scores_keep_highest
  before update on public.scores
  for each row execute function public.scores_keep_highest();

-- realtime push for live leaderboard updates
alter publication supabase_realtime add table public.scores;
