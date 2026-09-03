-- Nexus: echte Communities
create or replace function public.create_community(
  p_name text,
  p_slug text,
  p_description text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if trim(coalesce(p_name,'')) = '' then raise exception 'invalid_name'; end if;
  insert into public.communities(owner_id,name,slug,description)
  values(v_user,trim(p_name),trim(p_slug),coalesce(p_description,''))
  returning id into v_id;
  insert into public.community_members(community_id,user_id,role)
  values(v_id,v_user,'owner');
  insert into public.channels(community_id,name,type,position,created_by)
  values
    (v_id,'Allgemein','text',0,v_user),
    (v_id,'Lounge','text',1,v_user),
    (v_id,'Sprachkanal','voice',2,v_user);
  return v_id;
end;
$$;
revoke all on function public.create_community(text,text,text) from public;
grant execute on function public.create_community(text,text,text) to authenticated;

create or replace function public.join_public_community(p_community_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_user uuid := auth.uid(); v_visibility text;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select visibility into v_visibility from public.communities where id=p_community_id;
  if v_visibility is null then raise exception 'not_found'; end if;
  if v_visibility <> 'public' then raise exception 'not_public'; end if;
  insert into public.community_members(community_id,user_id,role)
  values(p_community_id,v_user,'member')
  on conflict (community_id,user_id) do nothing;
end;
$$;
revoke all on function public.join_public_community(uuid) from public;
grant execute on function public.join_public_community(uuid) to authenticated;

-- RLS-sicheres Lesen eigener Community-Mitgliedschaften
create or replace function public.is_community_member(p_community_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists(select 1 from public.community_members where community_id=p_community_id and user_id=p_user_id);
$$;

drop policy if exists "Members can view community members" on public.community_members;
create policy "Members can view community members"
on public.community_members for select to authenticated
using (public.is_community_member(community_id,auth.uid()));
