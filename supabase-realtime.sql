-- Nexus: Echtzeit für Direktnachrichten aktivieren
-- Falls die Tabelle bereits in der Publication ist, ist der Hinweis dazu unkritisch.

do $$
begin
  alter publication supabase_realtime add table public.direct_messages;
exception
  when duplicate_object then null;
end $$;
