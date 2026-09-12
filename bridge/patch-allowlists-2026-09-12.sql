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
