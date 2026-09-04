-- Nexus V30: profile images, richer profiles, secure Plus verification, storage policies
-- Run after the previous Nexus migrations (V29 or latest).

alter table public.profiles add column if not exists status_text text default '';
alter table public.profiles add column if not exists pronouns text default '';
alter table public.profiles add column if not exists avatar_url text default '';
alter table public.profiles add column if not exists nexus_plus boolean not null default false;
alter table public.profiles add column if not exists is_owner boolean not null default false;
alter table public.profiles add column if not exists username text default '';
alter table public.profiles add column if not exists bio text default '';
alter table public.profiles add column if not exists preferences jsonb not null default '{}'::jsonb;

-- Profile rows are publicly readable for the fields Nexus displays to other users.
drop policy if exists "Nexus profiles public read" on public.profiles;
create policy "Nexus profiles public read" on public.profiles
for select using (true);

-- Users may edit normal profile fields, but cannot grant themselves Plus or owner status.
drop policy if exists "Nexus V30 update own profile" on public.profiles;
create policy "Nexus V30 update own profile" on public.profiles
for update using (auth.uid() = id)
with check (
  auth.uid() = id
  and nexus_plus = (select p.nexus_plus from public.profiles p where p.id = auth.uid())
  and is_owner = (select p.is_owner from public.profiles p where p.id = auth.uid())
);

-- Profile media bucket. Public read is intentional because profile pictures are visible to other Nexus users.
insert into storage.buckets (id,name,public)
values ('nexus-media','nexus-media',true)
on conflict (id) do update set public=true;

drop policy if exists "Nexus V30 profile images insert" on storage.objects;
create policy "Nexus V30 profile images insert" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'nexus-media'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "Nexus V30 profile images update" on storage.objects;
create policy "Nexus V30 profile images update" on storage.objects
for update to authenticated
using (
  bucket_id = 'nexus-media'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
  bucket_id = 'nexus-media'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "Nexus V30 profile images delete" on storage.objects;
create policy "Nexus V30 profile images delete" on storage.objects
for delete to authenticated
using (
  bucket_id = 'nexus-media'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "Nexus V30 profile images read" on storage.objects;
create policy "Nexus V30 profile images read" on storage.objects
for select using (bucket_id = 'nexus-media' and (storage.foldername(name))[1] = 'profiles');

-- Owner setup: replace the email only if the Nexus owner account is different.
-- This is intentionally separate from the normal profile update policy.
-- update public.profiles p set is_owner=true, nexus_plus=true from auth.users u where p.id=u.id and u.email='YOUR-OWNER-EMAIL';

-- Plus verification is derived from nexus_plus OR is_owner in the app; there is no client-side self-verification switch.
