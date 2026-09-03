-- Nexus: sichere Erstellung eines 1:1-Chats
create or replace function public.create_direct_conversation(p_friend_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_conv uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_friend_id is null or p_friend_id = v_user then raise exception 'invalid_friend'; end if;

  if not exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((user_id=v_user and friend_id=p_friend_id) or (user_id=p_friend_id and friend_id=v_user))
  ) then
    raise exception 'not_friends';
  end if;

  select dm1.conversation_id into v_conv
  from public.direct_members dm1
  join public.direct_members dm2 on dm2.conversation_id=dm1.conversation_id
  where dm1.user_id=v_user and dm2.user_id=p_friend_id
  limit 1;

  if v_conv is not null then return v_conv; end if;

  insert into public.direct_conversations default values returning id into v_conv;
  insert into public.direct_members(conversation_id,user_id) values (v_conv,v_user),(v_conv,p_friend_id);
  return v_conv;
end;
$$;

revoke all on function public.create_direct_conversation(uuid) from public;
grant execute on function public.create_direct_conversation(uuid) to authenticated;
