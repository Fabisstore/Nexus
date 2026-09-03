-- Nexus V18: Medien, Kanalverwaltung und sichere Community-Verwaltung
-- Einmal im Supabase SQL Editor ausführen.

-- Medien-Bucket
insert into storage.buckets (id, name, public)
values ('nexus-media', 'nexus-media', false)
on conflict (id) do nothing;

-- Nutzer dürfen eigene Medien hochladen
create policy "Nexus users upload media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'nexus-media' and owner_id = auth.uid());

create policy "Nexus users read media"
on storage.objects for select
to authenticated
using (bucket_id = 'nexus-media');

create policy "Nexus users delete own media"
on storage.objects for delete
to authenticated
using (bucket_id = 'nexus-media' and owner_id = auth.uid());

-- Community- und Kanalverwaltung
create or replace function public.is_community_manager(p_community_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.community_members
    where community_id = p_community_id
      and user_id = p_user_id
      and role in ('owner','admin','moderator')
  );
$$;

create or replace function public.update_community(
  p_community_id uuid,
  p_name text,
  p_description text,
  p_icon_url text default null,
  p_banner_url text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_community_manager(p_community_id) then raise exception 'not_allowed'; end if;
  update public.communities
  set name=trim(p_name), description=coalesce(p_description,''),
      icon_url=nullif(trim(coalesce(p_icon_url,'')),''),
      banner_url=nullif(trim(coalesce(p_banner_url,'')),''),
      updated_at=now()
  where id=p_community_id;
  return true;
end;
$$;

grant execute on function public.update_community(uuid,text,text,text,text) to authenticated;

grant execute on function public.is_community_manager(uuid,uuid) to authenticated;

-- Kanäle anlegen
create or replace function public.create_community_channel(
  p_community_id uuid,
  p_name text,
  p_type text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if not public.is_community_manager(p_community_id) then raise exception 'not_allowed'; end if;
  if p_type not in ('text','voice','announcement','forum') then raise exception 'invalid_type'; end if;
  insert into public.channels(community_id,name,type,position,created_by)
  values (p_community_id,trim(p_name),p_type,
          coalesce((select max(position)+1 from public.channels where community_id=p_community_id),0),auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

grant execute on function public.create_community_channel(uuid,text,text) to authenticated;

create or replace function public.update_community_channel(
  p_channel_id uuid,
  p_name text,
  p_type text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare v_community uuid;
begin
  select community_id into v_community from public.channels where id=p_channel_id;
  if v_community is null or not public.is_community_manager(v_community) then raise exception 'not_allowed'; end if;
  if p_type not in ('text','voice','announcement','forum') then raise exception 'invalid_type'; end if;
  update public.channels set name=trim(p_name),type=p_type where id=p_channel_id;
  return true;
end;
$$;

grant execute on function public.update_community_channel(uuid,text,text) to authenticated;

create or replace function public.delete_community_channel(p_channel_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare v_community uuid;
begin
  select community_id into v_community from public.channels where id=p_channel_id;
  if v_community is null or not public.is_community_manager(v_community) then raise exception 'not_allowed'; end if;
  delete from public.channels where id=p_channel_id;
  return true;
end;
$$;

grant execute on function public.delete_community_channel(uuid) to authenticated;

-- Rollen ändern (Owner/Admin)
create or replace function public.set_community_member_role(
  p_community_id uuid,
  p_user_id uuid,
  p_role text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare v_role text;
begin
  select role into v_role from public.community_members where community_id=p_community_id and user_id=auth.uid();
  if v_role not in ('owner','admin') then raise exception 'not_allowed'; end if;
  if p_role not in ('admin','moderator','member') then raise exception 'invalid_role'; end if;
  update public.community_members set role=p_role where community_id=p_community_id and user_id=p_user_id;
  return true;
end;
$$;

grant execute on function public.set_community_member_role(uuid,uuid,text) to authenticated;

-- Community-Farbdesign
alter table public.communities add column if not exists accent_color text default '#20ddff';

create or replace function public.update_community(
  p_community_id uuid,
  p_name text,
  p_description text,
  p_icon_url text default null,
  p_banner_url text default null,
  p_accent_color text default '#20ddff'
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_community_manager(p_community_id) then raise exception 'not_allowed'; end if;
  update public.communities
  set name=trim(p_name), description=coalesce(p_description,''),
      icon_url=nullif(trim(coalesce(p_icon_url,'')),''),
      banner_url=nullif(trim(coalesce(p_banner_url,'')),''),
      accent_color=coalesce(nullif(trim(p_accent_color),''),'#20ddff'),
      updated_at=now()
  where id=p_community_id;
  return true;
end;
$$;

grant execute on function public.update_community(uuid,text,text,text,text,text) to authenticated;
