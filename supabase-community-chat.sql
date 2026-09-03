-- Nexus: sichere Community-Mitgliedschafts- und Kanal-/Nachrichtenrechte
create or replace function public.is_community_member(
  p_community_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.community_members
    where community_id = p_community_id and user_id = p_user_id
  );
$$;

drop policy if exists "Members can view community members" on public.community_members;
create policy "Members can view community members"
on public.community_members for select to authenticated
using (public.is_community_member(community_id, auth.uid()));

drop policy if exists "Members can view channels" on public.channels;
create policy "Members can view channels"
on public.channels for select to authenticated
using (public.is_community_member(community_id, auth.uid()));

drop policy if exists "Members can view messages" on public.messages;
create policy "Members can view messages"
on public.messages for select to authenticated
using (
  exists (
    select 1 from public.channels c
    where c.id = messages.channel_id
      and public.is_community_member(c.community_id, auth.uid())
  )
);

drop policy if exists "Members can send messages" on public.messages;
create policy "Members can send messages"
on public.messages for insert to authenticated
with check (
  author_id = auth.uid()
  and exists (
    select 1 from public.channels c
    where c.id = messages.channel_id
      and public.is_community_member(c.community_id, auth.uid())
  )
);

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
end $$;
