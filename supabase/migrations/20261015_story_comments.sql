-- ══════════════════════════════════════════════════════════════
-- DD Online: story комментарийлери
-- Supabase → SQL Editor'го коюп, бир жолу Run басыңыз (кайра иштетсе болот).
-- ══════════════════════════════════════════════════════════════
create table if not exists public.story_comments (
  id          uuid primary key default gen_random_uuid(),
  story_id    uuid not null references public.stories(id) on delete cascade,
  user_id     uuid not null,
  user_name   text,
  avatar_url  text,
  text        text not null check (char_length(text) between 1 and 500),
  created_at  timestamptz not null default now()
);

create index if not exists story_comments_story_idx
  on public.story_comments (story_id, created_at desc);

alter table public.story_comments enable row level security;

drop policy if exists "story_comments_select" on public.story_comments;
create policy "story_comments_select" on public.story_comments
  for select to anon, authenticated using (true);

drop policy if exists "story_comments_insert" on public.story_comments;
create policy "story_comments_insert" on public.story_comments
  for insert to authenticated with check (auth.uid() = user_id);

-- өзүнүн комментин өчүрүү (админ панелден anon менен да өчүрүү үчүн ачык)
drop policy if exists "story_comments_delete" on public.story_comments;
create policy "story_comments_delete" on public.story_comments
  for delete to anon, authenticated using (true);
