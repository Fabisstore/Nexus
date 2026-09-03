-- Nexus: Freigabe für direkte Chats
-- Ermöglicht dem Ersteller einer Unterhaltung, den zweiten Teilnehmer hinzuzufügen.

create or replace function public.is_direct_member(p_conversation_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.direct_members
    where conversation_id = p_conversation_id
      and user_id = p_user_id
  );
$$;

drop policy if exists "Users can add themselves to direct conversations" on public.direct_members;

create policy "Users can add direct conversation members"
on public.direct_members
for insert
to authenticated
with check (
  user_id = auth.uid()
  or public.is_direct_member(conversation_id, auth.uid())
);
