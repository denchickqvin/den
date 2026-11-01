-- =====================================================================
-- Настройка базы данных для приложения объявлений (Supabase / Postgres)
-- Выполнить один раз: Supabase -> SQL Editor -> New query -> Run
-- Скрипт можно запускать повторно без вреда.
-- =====================================================================

-- ---------- 1. Таблица объявлений ----------
create table if not exists public.ads (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title       text not null check (char_length(title) between 1 and 80),
  description text not null check (char_length(description) between 1 and 1500),
  deal        text not null check (deal in ('sale', 'rent')),
  price       numeric not null check (price >= 0),
  address     text not null check (char_length(address) between 1 and 100),
  phone       text not null check (char_length(phone) between 6 and 25),
  photo_url   text not null,
  photo_path  text not null,
  created_at  timestamptz not null default now()
);

create index if not exists ads_created_at_idx on public.ads (created_at desc);

-- ---------- 2. Права доступа к таблице ----------
grant select on public.ads to anon, authenticated;
grant insert, delete on public.ads to authenticated;

-- ---------- 3. Row Level Security (правила: кто что может) ----------
alter table public.ads enable row level security;

drop policy if exists "ads_select_all" on public.ads;
create policy "ads_select_all"
  on public.ads for select
  to anon, authenticated
  using (true);                                   -- читать могут все

drop policy if exists "ads_insert_own" on public.ads;
create policy "ads_insert_own"
  on public.ads for insert
  to authenticated
  with check (author_id = (select auth.uid()));   -- создавать можно только от своего имени

drop policy if exists "ads_delete_own" on public.ads;
create policy "ads_delete_own"
  on public.ads for delete
  to authenticated
  using (author_id = (select auth.uid()));        -- удалять можно только свои

-- ---------- 4. Защита от спама: не более 20 объявлений на пользователя ----------
create or replace function public.limit_ads_per_user()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.ads where author_id = new.author_id) >= 20 then
    raise exception 'Лимит: не более 20 объявлений на пользователя';
  end if;
  return new;
end;
$$;

drop trigger if exists ads_limit_trigger on public.ads;
create trigger ads_limit_trigger
  before insert on public.ads
  for each row execute function public.limit_ads_per_user();

-- ---------- 5. Хранилище для фото ----------
-- Публичный bucket: фото открываются по ссылке. Только JPEG, до 1 МБ.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ad-photos', 'ad-photos', true, 1048576, array['image/jpeg'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Загружать можно только в свою папку: ad-photos/<id пользователя>/...
drop policy if exists "ad_photos_insert_own" on storage.objects;
create policy "ad_photos_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'ad-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Удалять можно только свои файлы
drop policy if exists "ad_photos_delete_own" on storage.objects;
create policy "ad_photos_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'ad-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
