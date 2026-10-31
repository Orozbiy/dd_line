-- ══════════════════════════════════════════════════════════════
-- DD Online: арыздар + сунуштар + скриншот (Supabase Storage)
-- Supabase → SQL Editor'го коюп, бир жолу Run басыңыз.
-- Кайра иштетсеңиз да болот (idempotent).
-- ══════════════════════════════════════════════════════════════

-- 1) Арыздар: кайсы сатуучуга айтылганы + скриншот URL
alter table public.complaints
  add column if not exists store_id         text,
  add column if not exists seller_id        text,
  add column if not exists shop_name        text,
  add column if not exists seller_name      text,
  add column if not exists container_number text,
  add column if not exists screenshot_url   text;

-- 2) Сунуштар: "окулду" белгиси
alter table public.buyer_suggestions
  add column if not exists is_read boolean not null default false;

-- 3) Скриншоттор үчүн Storage bucket (public — сүрөт URL менен ачылат)
insert into storage.buckets (id, name, public, file_size_limit)
values ('complaint-screenshots', 'complaint-screenshots', true, 10485760)
on conflict (id) do update
  set public = true, file_size_limit = 10485760;

drop policy if exists "complaint_shots_select" on storage.objects;
create policy "complaint_shots_select" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'complaint-screenshots');

drop policy if exists "complaint_shots_insert" on storage.objects;
create policy "complaint_shots_insert" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'complaint-screenshots');

drop policy if exists "complaint_shots_delete" on storage.objects;
create policy "complaint_shots_delete" on storage.objects
  for delete to anon, authenticated
  using (bucket_id = 'complaint-screenshots');

-- 4) Админ панелден белгилөө (update) жана өчүрүү (delete)
--    (Админ панель паролго негизделген, Supabase'де өзүнчө админ аккаунт жок,
--     ошондуктан клиенттен иштеши үчүн anon/authenticated'ке берилет.)
drop policy if exists "complaints_admin_update" on public.complaints;
create policy "complaints_admin_update" on public.complaints
  for update to anon, authenticated using (true) with check (true);

drop policy if exists "complaints_admin_delete" on public.complaints;
create policy "complaints_admin_delete" on public.complaints
  for delete to anon, authenticated using (true);

drop policy if exists "buyer_suggestions_admin_update" on public.buyer_suggestions;
create policy "buyer_suggestions_admin_update" on public.buyer_suggestions
  for update to anon, authenticated using (true) with check (true);

drop policy if exists "buyer_suggestions_admin_delete" on public.buyer_suggestions;
create policy "buyer_suggestions_admin_delete" on public.buyer_suggestions
  for delete to anon, authenticated using (true);
