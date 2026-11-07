-- push_tokens: ар бир колдонуучуга платформа боюнча бир токен (upsert onConflict: user_id,platform)
create table if not exists public.push_tokens (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null,
  updated_at timestamptz default now()
);
create unique index if not exists push_tokens_user_platform_uidx
  on public.push_tokens (user_id, platform);
alter table public.push_tokens enable row level security;
drop policy if exists "own tokens" on public.push_tokens;
create policy "own tokens" on public.push_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
