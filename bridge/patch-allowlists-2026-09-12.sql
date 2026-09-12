-- Paste into the Supabase SQL editor. Safe to run twice.
insert into kin_species (id) values
  ('slime'), ('ember'), ('droplet'), ('sprout'), ('wisp'), ('comet'),
  ('orca'), ('axolotl'), ('axolotl-coral'),
  ('mint'), ('coral'), ('butter'), ('lilac')
on conflict (id) do nothing;
insert into kin_looks (id) values
  ('classic'), ('woodland'), ('beanie'), ('tidepool'), ('butterscotch'), ('nightshift'),
  ('hoodie'), ('flannel'), ('barista'), ('scholar'), ('varsity'), ('pajamas'),
  ('keynote'), ('happi'), ('idol'), ('racer'), ('ballet'), ('hanbok'),
  ('biker'), ('astronaut'), ('monster'), ('ninja'), ('sorcerer'), ('grad'),
  ('hex'), ('champ'), ('headliner'), ('netrunner'), ('count'), ('abyss')
on conflict (id) do nothing;
insert into kin_costumes (id) values
  ('none'), ('scholar'), ('ninja'), ('hoodie'), ('baker'),
  ('astronaut'), ('racer'), ('biker'), ('pajamas'),
  ('flannel'), ('barista'), ('varsity'), ('keynote'), ('happi'), ('idol'),
  ('ballet'), ('hanbok'), ('monster'), ('sorcerer'), ('grad'), ('hex'),
  ('champ'), ('headliner'), ('netrunner'), ('count'), ('abyss')
on conflict do nothing;

-- fetch_todo: null until a laptop binds, so a fresh phone does not say Connected.
create or replace function fetch_todo(p_code text, p_token text)
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select case when writer_hash is null then null else todo end from pairings
   where code = p_code and owner_hash = token_hash(p_token) and expires_at > now();
$$;
