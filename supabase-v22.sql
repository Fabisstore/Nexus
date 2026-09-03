-- Nexus V22: Profil-, Status- und Einstellungen dauerhaft speichern
-- Diese Datei im Supabase SQL Editor komplett ausführen.

alter table public.profiles
  add column if not exists username text,
  add column if not exists avatar_url text,
  add column if not exists bio text,
  add column if not exists status text default 'offline',
  add column if not exists preferences jsonb default '{}'::jsonb;

alter table public.profiles enable row level security;

drop policy if exists "Nexus users update own profile" on public.profiles;
create policy "Nexus users update own profile"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "Nexus users read profiles" on public.profiles;
create policy "Nexus users read profiles"
on public.profiles for select
to authenticated
using (true);

-- Bestehende Profile sinnvoll initialisieren.
update public.profiles
set status = coalesce(nullif(status,''),'offline'),
    preferences = coalesce(preferences,'{}'::jsonb)
where status is null or preferences is null;

-- Storage-Policies mit korrektem owner_id-Typ (text) ergänzen/ersetzen.
drop policy if exists "Nexus users upload media" on storage.objects;
create policy "Nexus users upload media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'nexus-media' and owner_id = auth.uid()::text);

drop policy if exists "Nexus users read media" on storage.objects;
create policy "Nexus users read media"
on storage.objects for select
to authenticated
using (bucket_id = 'nexus-media');

drop policy if exists "Nexus users delete own media" on storage.objects;
create policy "Nexus users delete own media"
on storage.objects for delete
to authenticated
using (bucket_id = 'nexus-media' and owner_id = auth.uid()::text);
