-- Nexus V23: Nexus Plus + Office + stabile Profil-/Community-Grundlagen
-- Im Supabase SQL Editor komplett ausführen.

alter table public.profiles
  add column if not exists nexus_plus boolean not null default false,
  add column if not exists is_owner boolean not null default false,
  add column if not exists username text,
  add column if not exists avatar_url text,
  add column if not exists bio text,
  add column if not exists status text default 'offline',
  add column if not exists preferences jsonb default '{}'::jsonb;

alter table public.profiles enable row level security;

drop policy if exists "Nexus users update own profile" on public.profiles;
create policy "Nexus users update own profile"
on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid()
  and nexus_plus = (select p.nexus_plus from public.profiles p where p.id = auth.uid())
  and is_owner = (select p.is_owner from public.profiles p where p.id = auth.uid())
);

drop policy if exists "Nexus users read profiles" on public.profiles;
create policy "Nexus users read profiles"
on public.profiles for select to authenticated using (true);

update public.profiles
set status = coalesce(nullif(status,''),'offline'),
    preferences = coalesce(preferences,'{}'::jsonb),
    nexus_plus = coalesce(nexus_plus,false),
    is_owner = coalesce(is_owner,false)
where status is null or preferences is null or nexus_plus is null;

-- Öffentliche Communities können gefunden werden.
drop policy if exists "Nexus public communities readable" on public.communities;
create policy "Nexus public communities readable"
on public.communities for select to authenticated
using (visibility = 'public' or owner_id = auth.uid() or exists (
  select 1 from public.community_members cm
  where cm.community_id = communities.id and cm.user_id = auth.uid()
));

-- Nexus Plus Dokumente.
create table if not exists public.plus_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Neues Dokument',
  content_html text not null default '<p></p>',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists plus_documents_user_updated_idx
  on public.plus_documents(user_id, updated_at desc);

alter table public.plus_documents enable row level security;

drop policy if exists "Plus users read own documents" on public.plus_documents;
create policy "Plus users read own documents"
on public.plus_documents for select to authenticated
using (user_id = auth.uid() and exists (
  select 1 from public.profiles p where p.id = auth.uid() and (p.nexus_plus = true or p.is_owner = true)
));

drop policy if exists "Plus users insert own documents" on public.plus_documents;
create policy "Plus users insert own documents"
on public.plus_documents for insert to authenticated
with check (user_id = auth.uid() and exists (
  select 1 from public.profiles p where p.id = auth.uid() and (p.nexus_plus = true or p.is_owner = true)
));

drop policy if exists "Plus users update own documents" on public.plus_documents;
create policy "Plus users update own documents"
on public.plus_documents for update to authenticated
using (user_id = auth.uid() and exists (
  select 1 from public.profiles p where p.id = auth.uid() and (p.nexus_plus = true or p.is_owner = true)
))
with check (user_id = auth.uid() and exists (
  select 1 from public.profiles p where p.id = auth.uid() and (p.nexus_plus = true or p.is_owner = true)
));

drop policy if exists "Plus users delete own documents" on public.plus_documents;
create policy "Plus users delete own documents"
on public.plus_documents for delete to authenticated
using (user_id = auth.uid() and exists (
  select 1 from public.profiles p where p.id = auth.uid() and (p.nexus_plus = true or p.is_owner = true)
));

-- Storage: korrekter owner_id-Typ.
drop policy if exists "Nexus users upload media" on storage.objects;
create policy "Nexus users upload media"
on storage.objects for insert to authenticated
with check (bucket_id = 'nexus-media' and owner_id = auth.uid()::text);

drop policy if exists "Nexus users read media" on storage.objects;
create policy "Nexus users read media"
on storage.objects for select to authenticated
using (bucket_id = 'nexus-media');

drop policy if exists "Nexus users delete own media" on storage.objects;
create policy "Nexus users delete own media"
on storage.objects for delete to authenticated
using (bucket_id = 'nexus-media' and owner_id = auth.uid()::text);

-- Stripe-Webhooks setzen nexus_plus serverseitig.
create or replace function public.grant_nexus_plus(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set nexus_plus = true where id = p_user_id;
end;
$$;
revoke all on function public.grant_nexus_plus(uuid) from public, anon, authenticated;

-- Gruppen-Chats.
alter table public.direct_conversations
  add column if not exists is_group boolean not null default false,
  add column if not exists name text;

create or replace function public.create_group_conversation(p_name text, p_member_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_conv uuid;
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if coalesce(trim(p_name),'') = '' then raise exception 'invalid_name'; end if;
  if coalesce(array_length(p_member_ids,1),0) < 1 then raise exception 'members_required'; end if;
  insert into public.direct_conversations(is_group,name) values(true,trim(p_name)) returning id into v_conv;
  insert into public.direct_members(conversation_id,user_id) values(v_conv,v_user) on conflict do nothing;
  foreach v_id in array p_member_ids loop
    if v_id is not null and v_id <> v_user then
      insert into public.direct_members(conversation_id,user_id) values(v_conv,v_id) on conflict do nothing;
    end if;
  end loop;
  return v_conv;
end;
$$;
revoke all on function public.create_group_conversation(text,uuid[]) from public;
grant execute on function public.create_group_conversation(text,uuid[]) to authenticated;


-- Nexus V25 Ergänzungen: Plus bleibt serverseitig geschützt; Gruppenmitglieder dürfen nur ihre eigenen Gruppen sehen.
create index if not exists direct_members_user_conversation_idx on public.direct_members(user_id, conversation_id);
create index if not exists direct_messages_conversation_created_idx on public.direct_messages(conversation_id, created_at);

-- Nur authentifizierte Nutzer dürfen den eigenen Plus-Status lesen (die bestehende Profil-RLS bleibt maßgeblich).
-- Die Freischaltung erfolgt ausschließlich über die SECURITY DEFINER-Funktion aus dem Stripe-Webhook.


-- RLS für 1:1- und Gruppen-Chats. Diese Policies sind additive und idempotent.
create or replace function public.is_direct_member(p_conversation_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.direct_members
    where conversation_id = p_conversation_id and user_id = p_user_id
  );
$$;

alter table public.direct_members enable row level security;
alter table public.direct_conversations enable row level security;
alter table public.direct_messages enable row level security;

drop policy if exists "Nexus users read own direct memberships" on public.direct_members;
create policy "Nexus users read own direct memberships"
on public.direct_members for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Nexus users read own conversations" on public.direct_conversations;
create policy "Nexus users read own conversations"
on public.direct_conversations for select to authenticated
using (public.is_direct_member(id, auth.uid()));

drop policy if exists "Nexus members read direct messages" on public.direct_messages;
create policy "Nexus members read direct messages"
on public.direct_messages for select to authenticated
using (public.is_direct_member(conversation_id, auth.uid()));

drop policy if exists "Nexus members send direct messages" on public.direct_messages;
create policy "Nexus members send direct messages"
on public.direct_messages for insert to authenticated
with check (author_id = auth.uid() and public.is_direct_member(conversation_id, auth.uid()));


-- V26 OWNER-ZUGANG
-- Fabisstore wird NICHT ueber Stripe freigeschaltet und muss niemals selbst zahlen.
-- Nach dem Einsetzen dieses SQL einmalig die eigene Auth-User-ID einsetzen:
-- update public.profiles set is_owner = true where id = 'DEINE-USER-ID'::uuid;
-- Diese Spalte darf danach nicht von normalen Profil-Updates geaendert werden.
