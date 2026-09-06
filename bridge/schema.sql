-- Prepkin Canvas — bridge schema (run once in the Supabase SQL editor).
--
-- What this is for: the Chrome extension reads Canvas on your laptop, the iPhone
-- app needs those tasks. This is the one row in the middle that they share.
--
-- No accounts, no email, no name. A pairing code is the only thing a person ever
-- sees or types, and it expires.
--
-- ---------------------------------------------------------------------------
-- Why the code alone is not the key
--
-- The publishable key ships inside every extension install and every app build,
-- so anyone can call these functions. An earlier version gated writes on nothing
-- but the code's shape, which meant a guessed code let a stranger read a
-- student's coursework and overwrite their task list. Eight characters is about
-- a trillion combinations, which sounds like plenty until you notice there is no
-- rate limit anywhere and an attacker is hunting for *any* student, not a chosen
-- one.
--
-- So the code is now only good for the few minutes it takes to pair. Each side
-- trades it once for a long random token and uses that token from then on:
--
--   app        claim_code(code)              -> owner token   (creates the row)
--   extension  bind_writer(code)             -> writer token  (once, while open)
--   extension  push_todo(code, writer, todo)
--   extension  fetch_state(code, writer)
--   app        fetch_todo(code, owner)
--   app        push_state(code, owner, state)
--   app        delete_pairing(code, owner)
--
-- Only the SHA-256 of each token is stored, so the table is worthless on its own.
-- After pairing, guessing a code buys nothing at all: reads need a token too.

create extension if not exists pgcrypto with schema extensions;

create table if not exists pairings (
  code            text primary key,
  -- sha256 of the token each side holds. Never the token itself.
  owner_hash      bytea,
  writer_hash     bytea,
  -- The window in which a laptop may still claim this code. Once a writer binds,
  -- or this passes, the code is spent.
  claimable_until timestamptz not null default (now() + interval '15 minutes'),
  todo            jsonb       not null default '[]'::jsonb,
  state           jsonb       not null default '{}'::jsonb,
  updated_at      timestamptz not null default now(),
  expires_at      timestamptz not null default (now() + interval '30 days')
);

-- Existing installs: add what the old shape is missing.
alter table pairings add column if not exists owner_hash      bytea;
alter table pairings add column if not exists writer_hash     bytea;
alter table pairings add column if not exists claimable_until timestamptz not null default (now() + interval '15 minutes');
alter table pairings add column if not exists state           jsonb not null default '{}'::jsonb;

-- Lock the table itself. With no policies the public key cannot read, write, or
-- list anything here directly. The only way in is the functions below, and every
-- one of them demands a token nobody can guess.
alter table pairings enable row level security;

-- A code has to look like a code before it touches the table. This keeps random
-- junk from filling the table with rows.
create or replace function is_code(p_code text)
returns boolean language sql immutable as $$
  select p_code ~ '^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$';
$$;

create or replace function token_hash(p_token text)
returns bytea language sql immutable
set search_path = public, extensions as $$
  select digest(coalesce(p_token, ''), 'sha256');
$$;

-- ---------------------------------------------------------------------------
-- Pairing

-- The app calls this when it first shows a code. It is the only way a row is
-- ever created, and it carries no payload, so it cannot be used to fill the
-- database. Returns the owner token exactly once — the app keeps it in the
-- Keychain and never shows it to anyone.
create or replace function claim_code(p_code text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token text;
begin
  if not is_code(p_code) then
    raise exception 'bad code';
  end if;
  if exists (select 1 from pairings where code = p_code and expires_at > now()) then
    -- Somebody already holds this code. The app rolls a new one rather than
    -- joining a stranger's row.
    return null;
  end if;
  v_token := encode(gen_random_bytes(32), 'hex');
  insert into pairings (code, owner_hash, writer_hash, claimable_until, todo, state, updated_at, expires_at)
  values (p_code, token_hash(v_token), null, now() + interval '15 minutes',
          '[]'::jsonb, '{}'::jsonb, now(), now() + interval '30 days')
  on conflict (code) do update
    set owner_hash      = excluded.owner_hash,
        writer_hash     = null,
        claimable_until = excluded.claimable_until,
        todo            = '[]'::jsonb,
        state           = '{}'::jsonb,
        updated_at      = now(),
        expires_at      = excluded.expires_at;
  return v_token;
end;
$$;

-- The extension calls this once, with the code the student typed. It answers
-- only while the code is still claimable and no laptop has bound yet — so the
-- first laptop in wins, and a stranger who guesses the code later gets nothing.
create or replace function bind_writer(p_code text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token text;
begin
  if not is_code(p_code) then
    raise exception 'bad code';
  end if;
  v_token := encode(gen_random_bytes(32), 'hex');
  update pairings
     set writer_hash = token_hash(v_token),
         updated_at  = now()
   where code = p_code
     and writer_hash is null
     and claimable_until > now()
     and expires_at > now();
  if not found then
    return null;
  end if;
  return v_token;
end;
$$;

-- ---------------------------------------------------------------------------
-- The laptop's half

-- The extension hands over the latest Canvas list. Nothing but the bound laptop
-- can call this, so a guessed code can no longer overwrite a student's work.
--
-- A real semester is a few KB; anything past 256 KB is abuse, and it raises
-- rather than returning quietly — a push that vanished while the popup said
-- "sent" is worse than an error.
create or replace function push_todo(p_code text, p_token text, p_todo jsonb)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if pg_column_size(p_todo) > 262144 then
    raise exception 'payload too large';
  end if;
  update pairings
     set todo       = p_todo,
         updated_at = now(),
         expires_at = now() + interval '30 days'
   where code = p_code
     and writer_hash = token_hash(p_token)
     and expires_at > now();
  if not found then
    raise exception 'not paired';
  end if;
end;
$$;

-- The extension reads the coin balance and owned looks back.
create or replace function fetch_state(p_code text, p_token text)
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select state from pairings
   where code = p_code and writer_hash = token_hash(p_token) and expires_at > now();
$$;

-- ---------------------------------------------------------------------------
-- The phone's half

-- The app picks the list up. Returns nothing for a wrong token, which is also
-- what a guess gets.
create or replace function fetch_todo(p_code text, p_token text)
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select todo from pairings
   where code = p_code and owner_hash = token_hash(p_token) and expires_at > now();
$$;

-- The app publishes the coin balance and which looks are owned, so the
-- extension's shop shows a real number instead of a guess.
create or replace function push_state(p_code text, p_token text, p_state jsonb)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if pg_column_size(p_state) > 32768 then
    raise exception 'state too large';
  end if;
  update pairings
     set state      = p_state,
         updated_at = now(),
         expires_at = now() + interval '30 days'
   where code = p_code
     and owner_hash = token_hash(p_token)
     and expires_at > now();
  if not found then
    raise exception 'not paired';
  end if;
end;
$$;

-- Unpairing on the phone takes the row with it. Leaving it to expire meant a
-- student who disconnected because something felt wrong left their coursework
-- readable for another month.
create or replace function delete_pairing(p_code text, p_token text)
returns void
language sql
security definer
set search_path = public, extensions
as $$
  delete from pairings
   where code = p_code and owner_hash = token_hash(p_token);
$$;

-- ---------------------------------------------------------------------------
-- Housekeeping

-- Rows nobody has touched in 30 days are dead weight, and a student's
-- coursework should not outlive its stated life because a cron job was never
-- set up. This one is scheduled below rather than left as a note.
create or replace function purge_expired_pairings()
returns void
language sql
security definer
set search_path = public
as $$
  delete from pairings where expires_at < now();
$$;

-- pg_cron has to be enabled for the project first (Dashboard -> Database ->
-- Extensions). If it is not, this block says so instead of failing the run.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule('prepkin-purge')
      from cron.job where jobname = 'prepkin-purge';
    perform cron.schedule('prepkin-purge', '17 * * * *', 'select purge_expired_pairings()');
  else
    raise warning 'pg_cron is not enabled: expired pairings will NOT be purged. Enable it in Database -> Extensions, then re-run this file.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Nothing else is reachable with the publishable key.
--
-- The old code-only functions must be dropped, not just revoked: leaving them
-- in place would leave the unauthenticated door standing open next to the new
-- locked one.

drop function if exists push_todo(text, jsonb);
drop function if exists fetch_todo(text);
drop function if exists push_state(text, jsonb);
drop function if exists fetch_state(text);

grant execute on function claim_code(text)                  to anon;
grant execute on function bind_writer(text)                 to anon;
grant execute on function push_todo(text, text, jsonb)      to anon;
grant execute on function fetch_todo(text, text)            to anon;
grant execute on function push_state(text, text, jsonb)     to anon;
grant execute on function fetch_state(text, text)           to anon;
grant execute on function delete_pairing(text, text)        to anon;
revoke all on function purge_expired_pairings()             from anon;

-- ===========================================================================
-- Pods — the weekly league, once there are strangers in it
-- ===========================================================================
--
-- Everything above this line is one student's laptop talking to one student's
-- phone. Nothing above this line has ever shown one person anything about
-- another person. This half does, so it is written with more care, not less.
--
-- What it is for: the league is six depths of water a student climbs a week at
-- a time, and it now seats up to twenty of them in a pod together so the climb
-- has company. The people in a pod are strangers. Nobody types a code at
-- anybody, nobody adds anybody, nobody picks who they sit next to. A pod is a
-- table of numbers going up beside yours.
--
--   app   create_player()                                   -> id + token + name
--   app   join_pod(player, token, species, look, level)      -> pod, week, tier
--   app   push_points(player, token, points, species, …)     -> the board
--   app   fetch_pod(player, token)                           -> the board
--   app   leave_pod(player, token)
--   app   forget_player(player, token)
--
-- The rules that shaped every line below:
--
--   * No accounts. Same as the pairing half: no email, no password, no name a
--     person types. A player here is a random uuid and a random token, both
--     minted by the server, and the token is stored only as its sha256.
--   * No free text, anywhere, ever. This app is used by teenagers, so a
--     display name a person could choose is a display name a person will
--     abuse. The name is two numbers into word lists the app ships, and the
--     server picks the numbers. The kin is two ids that must already exist in
--     a list seeded in this file. The score is a number. There is no
--     sentence-shaped hole in this schema to put anything in.
--   * Nobody is ever pushed down. There is no demotion here. Settling a
--     finished week promotes the students who cleared their tier's bar and
--     leaves everyone else exactly where they were. If a line below looks like
--     it lowers a tier, it is a bug, not a feature.
--   * Nobody is ever invented. No seed players, no bots, no filler, no sample
--     pod. If a student is the only person at their tier this week, the board
--     comes back with exactly one member on it — theirs — and the app has to
--     say so in words. Four hard-coded fake friends were cut from this app for
--     exactly this reason and they are not coming back through the database.
--
-- ---------------------------------------------------------------------------
-- The thing this backend cannot do, said plainly before anything else
--
-- The server cannot verify a score. Coins are paid on the phone for finishing
-- things — a task checked off, a lesson read, twenty-five minutes of focus —
-- and the phone is the only witness to any of it. There is no receipt to
-- check, because there is nothing to check it against: no grade, no proctor,
-- no second device that saw the same event. push_points is a phone saying "I
-- earned 640 this week" and the server having no way on earth to know.
--
-- So the server does not ask "is this true". It asks the only question it can:
-- "is this a number a person could have earned by now?" — and when the answer
-- is no it writes down the largest number that would have been, instead of
-- refusing. That makes lying capped and slow. It does not make it hard, and
-- nothing in this file will pretend otherwise.
--
-- What makes that survivable is the ladder itself. A week promotes you at most
-- one tier, whatever your number was, and nobody is ever pushed down. A
-- perfect liar therefore climbs at exactly the speed of a perfect student, and
-- arrives at Deep holding a pennant that cost nothing to earn and buys nothing
-- to hold. There is no prize here to steal, and no person to steal it from.

-- ---------------------------------------------------------------------------
-- Shared bits

-- The week a pod belongs to, spelled the way the phone spells it: "2026-W37".
-- ISO 8601 — Monday first, week 1 holds the first Thursday — so a plain string
-- compare orders weeks correctly and `p.week < iso_week()` reads as "a week
-- that is over".
--
-- This is UTC, and the phone's `WeekKey` is the student's own time zone. They
-- disagree at the edges: in Los Angeles the pod's week turns at 4pm on Sunday,
-- so coins earned that Sunday evening land in the pod's *next* week while the
-- phone still counts them in this one. In Auckland it goes the other way.
--
-- UTC wins anyway, because the alternative is letting the phone name its own
-- week, and a client that names its own week can name an old one and sit in a
-- pod that has already been settled. The seam costs a few hours of accounting
-- at the boundary and costs nobody a pennant: pennants are settled on the
-- phone against the phone's own week, and the pod is only ever company.
create or replace function iso_week(p_at timestamptz default now())
returns text language sql stable
set search_path = public as $$
  select to_char(p_at at time zone 'utc', 'IYYY"-W"IW');
$$;

-- The bar for leaving each tier, in points earned that week. Tidepool is 0 and
-- Deep is 5; Deep answers null because it is the top and there is nothing above
-- it to charge for.
--
-- KEEP IN STEP WITH `LeagueRules.bars` IN ios/Sources/Core/LeagueState.swift.
-- These are the same five numbers written down twice, which is a thing worth
-- disliking. They are duplicated rather than sent up by the phone because a
-- server that lets the client name the bar is a server with no bar.
create or replace function league_bar(p_tier integer)
returns integer language sql immutable as $$
  select case p_tier
           when 0 then 150   -- Tidepool: about two light days
           when 1 then 300   -- Shallows
           when 2 then 500   -- Reef
           when 3 then 750   -- Kelp
           when 4 then 1100  -- Open water
           else null         -- Deep: no bar past it
         end;
$$;

-- ---------------------------------------------------------------------------
-- The two lists a kin may be drawn from
--
-- The board has to tell one student which fish another student is wearing, and
-- the app draws that from a `ChibiSpecies.id` and an `OwnedChibi.skinID`. Those
-- are strings, and a string that crosses from one student to another is exactly
-- the thing this schema is built to not have.
--
-- So the columns that hold them are foreign keys into these two tables. A kin
-- id is not text a student sent; it is a row somebody put here on purpose. A
-- modified client can send whatever it likes and the answer is the same: an id
-- that is not in this list is not stored, so it can never be handed to anybody.
-- That is what "no free text" has to mean when the value happens to look like
-- a word.
--
-- **Adding a kin or a look to the app means adding a row here first.** If the
-- app ships a new species before this file is re-run, the board keeps drawing
-- that student's previous kin — nothing breaks, nothing leaks, the picture is
-- just behind. Removing a row is refused by the foreign key while anybody is
-- wearing it, which is the right answer: you cannot delete a look off somebody
-- else's fish.
create table if not exists kin_species (id text primary key);
create table if not exists kin_looks   (id text primary key);

-- ios/Sources/Models.swift, ChibiSpecies.catalog
insert into kin_species (id) values
  ('slime'), ('ember'), ('droplet'), ('sprout'), ('wisp'), ('comet'),
  ('orca'), ('axolotl'), ('axolotl-coral')
on conflict (id) do nothing;

-- extension/looks.js, LOOKS
insert into kin_looks (id) values
  ('classic'), ('woodland'), ('beanie'), ('tidepool'), ('butterscotch'), ('nightshift')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Who a player is
--
-- A uuid the server minted, a token the server minted, two numbers for a name,
-- two ids for a fish, and two tier numbers. Nothing here came from a keyboard.
--
-- **This table has no expires_at, and nothing in the pairing half above may
-- ever delete from it.** That is not an oversight, it is the point. A student
-- who disconnects Canvas, or whose pairing row ages out after thirty days, has
-- not resigned from the league — they have unplugged a laptop. If the league
-- identity evaporated with the pairing, a pennant would evaporate with it, and
-- a keepsake that quietly disappears is worse than one that was never offered.
-- `delete_pairing()` above touches `pairings` and nothing else, and there is no
-- column anywhere joining the two tables, so unpairing cannot reach this row
-- even by accident. The only ways a player row ends are the student asking
-- (forget_player) and never having taken a seat (purge_league).
--
-- The token is stored as its sha256, exactly like the pairing tokens. If this
-- table leaked whole it would hand somebody a list of anonymous fish and no way
-- to write as any of them.
create table if not exists players (
  id          uuid primary key default gen_random_uuid(),
  -- sha256 of the 32-byte token the phone keeps. Never the token itself.
  token_hash  bytea    not null,
  -- The display name: an index into the adjective list and one into the noun
  -- list, both shipped in ios/Resources/Content/podnames.json. Two smallints,
  -- and no third column where a string could sneak in.
  name_adj    smallint not null,
  name_noun   smallint not null,
  -- The kin, as the board draws it. Cosmetic only — none of this decides
  -- anything, it is a picture beside a number.
  species     text     not null default 'slime'   references kin_species(id),
  look        text     not null default 'classic' references kin_looks(id),
  level       smallint not null default 1,
  -- Which water they are in now, and the deepest they have ever been.
  --
  -- Today these two are always equal, because nothing can lower `tier`. That is
  -- exactly why both exist: `best_tier` is the column that stays true if that
  -- ever stops being so, and a pennant is drawn from the deepest water reached,
  -- never from wherever somebody happens to be standing.
  tier        smallint not null default 0,
  best_tier   smallint not null default 0,
  created_at  timestamptz not null default now(),
  constraint players_level_range     check (level     between 1 and 3),
  constraint players_tier_range      check (tier      between 0 and 5),
  constraint players_best_tier_range check (best_tier between 0 and 5),
  -- A promise kept in the schema instead of only in the code: your best is
  -- never behind where you are.
  constraint players_best_is_best    check (best_tier >= tier)
);

-- ---------------------------------------------------------------------------
-- Pods and seats

-- One pod is one tier's worth of water for one week, holding up to twenty
-- people. Many pods exist per (week, tier): the twenty-first student to arrive
-- opens the next one.
--
-- `seats` is the member count kept alongside, so choosing a pod is an index
-- lookup instead of a count over every seat in the world. The trigger below
-- maintains it rather than the functions, because two functions that both have
-- to remember to decrement it are one forgotten line away from a pod that says
-- it is full and is not.
--
-- `settled_at` is how a finished week knows it has been paid out. There is no
-- scheduler in this design: the first student to touch a stale pod settles it
-- for everybody in it, once, ever.
create table if not exists pods (
  id          uuid primary key default gen_random_uuid(),
  week        text     not null,          -- "2026-W37", UTC. See iso_week().
  tier        smallint not null,
  seats       smallint not null default 0,
  created_at  timestamptz not null default now(),
  settled_at  timestamptz,
  constraint pods_tier_range  check (tier  between 0 and 5),
  constraint pods_seats_range check (seats between 0 and 20)
);

-- One seat. `week` is copied down from the pod on purpose: it is the only way
-- to write "one seat per player per week" as a unique index, and a rule the
-- database enforces beats a rule a function remembers.
--
-- `points` is what the board draws — coins earned *this week*, never the
-- student's balance. How much somebody has saved up is nobody else's business
-- and never leaves their phone.
--
-- `points_peak` and `peak_at` are the anti-cheat pair. push_points explains
-- them at length.
create table if not exists pod_members (
  pod_id      uuid     not null references pods(id)    on delete cascade,
  player_id   uuid     not null references players(id) on delete cascade,
  week        text     not null,
  points      integer  not null default 0,
  points_peak integer  not null default 0,
  -- The clock the growth allowance is measured from. Set to the start of the
  -- week at insert, not to now(): a student who joins on Wednesday has three
  -- honest days of coins behind them already and must not be clamped for it.
  peak_at     timestamptz not null,
  primary key (pod_id, player_id),
  constraint pod_members_points_positive check (points      >= 0),
  constraint pod_members_peak_positive   check (points_peak >= 0)
);

-- One seat per player per week, whatever order the taps arrive in.
create unique index if not exists pod_members_one_seat on pod_members (player_id, week);
-- The board, in board order.
create index if not exists pod_members_board on pod_members (pod_id, points desc);
-- Finding the oldest pod still open at a tier this week.
create index if not exists pods_open on pods (week, tier, created_at);

-- Keeps `pods.seats` honest no matter who removes a seat — a student leaving, a
-- student asking to be forgotten, or a cascade from either. Without it, a
-- forgotten player leaves a ghost holding a chair nobody can sit in.
create or replace function pod_seat_count()
returns trigger
language plpgsql
security definer
set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update pods set seats = seats + 1 where id = new.pod_id;
    return new;
  else
    update pods set seats = greatest(seats - 1, 0) where id = old.pod_id;
    return old;
  end if;
end;
$$;

drop trigger if exists pod_seats on pod_members;
create trigger pod_seats
after insert or delete on pod_members
for each row execute function pod_seat_count();

-- Lock every table. Same reasoning as `pairings`, and it matters more here:
-- the publishable key ships in every app build, so an unlocked `players` would
-- be a public list of every token hash and every student in the league,
-- readable with one HTTP request. With no policies at all, the only way in is
-- the functions below, and each of them wants a token.
alter table players     enable row level security;
alter table pods        enable row level security;
alter table pod_members enable row level security;
alter table kin_species enable row level security;
alter table kin_looks   enable row level security;

-- ---------------------------------------------------------------------------
-- Being a player

-- The door check, in one place so it cannot be half-remembered in one function
-- out of six. It raises rather than returning false, because a caller that
-- forgets to check a boolean is a caller that hands out somebody's pod.
create or replace function require_player(p_player uuid, p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if p_player is null or not exists (
    select 1 from players pl
     where pl.id = p_player and pl.token_hash = token_hash(p_token)
  ) then
    raise exception 'not a player';
  end if;
end;
$$;

-- Mints an identity. Called once, ever, the first time a student says yes to
-- the league, and it is the only way a players row is created. It takes no
-- arguments at all, which is worth saying out loud: there is nothing about a
-- student for it to accept.
--
-- **The server picks the name, not the phone.** Two numbers come back and the
-- app looks them up in the 64 adjectives and 64 nouns it ships, so a student
-- ends up as "Quiet Otter" without ever having been offered a text field. The
-- app cannot ask for a name, cannot suggest one, and cannot re-roll one — the
-- only way to abuse a display name here would be for somebody to have written
-- something abusive into podnames.json, and that is a file with an owner and a
-- test.
--
-- 4,096 names against 20 seats means roughly a 1-in-22 chance that two people
-- in one pod draw the same one. That is a curiosity, not a problem: your own
-- row is marked as yours, and nothing in the app is addressed to a name.
--
-- The indices come from the same random source as the token rather than from
-- random(), because 256 divides evenly by 64 and it costs nothing to have one
-- answer to "where did that number come from".
--
-- Everyone starts at Tidepool. The phone is not allowed to claim a tier, here
-- or anywhere else in this file, so a student who is already at Kelp on their
-- own ladder starts the pod ladder at the bottom and climbs it a week at a
-- time. That costs a returning student a few weeks of pod placement and it buys
-- the one thing that matters: a tier on this server is only ever something the
-- server watched somebody earn.
--
-- Returns {"id": …, "token": …, "adj": …, "noun": …}. The token is shown once;
-- the phone keeps it and the server keeps only its hash, so it cannot be handed
-- back to anybody, including us.
create or replace function create_player()
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token text;
  v_id    uuid;
  v_adj   smallint;
  v_noun  smallint;
begin
  v_token := encode(gen_random_bytes(32), 'hex');
  v_adj   := (get_byte(gen_random_bytes(1), 0) % 64)::smallint;
  v_noun  := (get_byte(gen_random_bytes(1), 0) % 64)::smallint;

  insert into players (token_hash, name_adj, name_noun)
  values (token_hash(v_token), v_adj, v_noun)
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'token', v_token, 'adj', v_adj, 'noun', v_noun);
end;
$$;

-- The kin, refreshed on every call that carries one, so a fish bought on
-- Tuesday shows up on the board on Tuesday instead of next Monday.
--
-- An id that is not in the shipped list leaves the old one in place. It is not
-- an error, because the honest cause is an app release that got ahead of this
-- file, and a student should not lose their league over a new hat.
create or replace function set_kin(p_player uuid, p_species text, p_look text, p_level integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update players pl
     set species = coalesce((select s.id from kin_species s where s.id = p_species), pl.species),
         look    = coalesce((select l.id from kin_looks   l where l.id = p_look),    pl.look),
         level   = least(greatest(coalesce(p_level, 1), 1), 3)
   where pl.id = p_player;
end;
$$;

-- ---------------------------------------------------------------------------
-- Closing a finished week
--
-- There is no scheduler behind the league. Weeks roll over lazily: whenever a
-- student touches it at all, any pod of theirs whose week is over is settled
-- first, under that pod's own row lock, with `settled_at` making sure that
-- happens exactly once however many phones arrive in the same second.
--
-- Settling one pod settles it for everybody sitting in it, not only for the
-- student who happened to open their phone. That is what makes a lazy rollover
-- honest: the week ends for the whole table at once, and somebody who comes
-- back in March is not judged against a bar their pod passed months ago.
--
-- **Settling only ever moves a player up.** It promotes everyone whose peak
-- cleared their tier's bar and touches nobody else. There is no branch here
-- that writes a smaller tier, and the `pl.tier <= v_tier` guard means even a
-- student who has already climbed past this pod's water cannot be dragged back
-- down to it by a stale pod settling late.
--
-- It judges on `points_peak` rather than the live number. A student who
-- un-checks something on Sunday night — fixed a mistake, tapped the wrong row —
-- should not lose a promotion they had already earned on Wednesday. It is also
-- no weaker against a liar, who could just as easily have held the number.
create or replace function settle_weeks(p_player uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_now_week text := iso_week();
  v_pod      uuid;
  v_tier     smallint;
  v_bar      integer;
begin
  -- Oldest week first, which is both the order these weeks actually happened in
  -- and a total order — one player holds at most one seat a week, so there are
  -- no ties. Two phones settling the same two pods therefore take the locks in
  -- the same order and cannot deadlock each other.
  for v_pod in
    select p.id
      from pods p
      join pod_members m on m.pod_id = p.id
     where m.player_id = p_player
       and p.settled_at is null
       and p.week < v_now_week
     order by p.week
  loop
    -- Take the pod's own lock, then ask again whether it is still unsettled:
    -- another phone may have paid this pod out while we were waiting for it.
    select p.tier into v_tier
      from pods p
     where p.id = v_pod and p.settled_at is null
     for update;
    if not found then
      continue;
    end if;

    v_bar := league_bar(v_tier);
    -- null at Deep, which has no bar and nothing above it. Skipping the update
    -- is also what keeps `tier` inside 0…5 without a second check.
    if v_bar is not null then
      update players pl
         set tier      = v_tier + 1,
             best_tier = greatest(pl.best_tier, (v_tier + 1)::smallint)
        from pod_members m
       where m.pod_id      = v_pod
         and m.player_id   = pl.id
         and m.points_peak >= v_bar
         and pl.tier       <= v_tier;   -- never down, never sideways
    end if;

    update pods set settled_at = now() where id = v_pod;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- The board itself
--
-- **This is the first thing in this file that hands one student anything about
-- another student, so it gets the longest note in the file.**
--
-- Everything above gives a student their own row back. A pod cannot work that
-- way — a board with nobody else on it is not a board — so the question was
-- never whether to show strangers to each other, only how little to show. Four
-- rules, and the shape of this query is just those rules:
--
-- 1. You must hold a seat, and you only ever see the pod you are sitting in.
--    There is no lookup by name, no lookup by id, no listing of pods, no way to
--    ask about a person and no way to ask about a pod you are not in. The only
--    thing that selects rows is your own token, checked by the callers below.
--
-- 2. Nothing that comes back was typed by a human being. The name is two
--    numbers into a word list the app ships, picked by the server. The kin is
--    two ids that had to already exist in the lists seeded above. The score is
--    a number. There is no field here that can carry a sentence, which means
--    there is no way to say anything at all to a stranger through this
--    function: no message, no nickname, no profile, no link. That is the single
--    most important property of this schema, and every column above was chosen
--    to keep it true.
--
-- 3. No identifiers for people. `you` is a boolean worked out here, so the
--    caller learns which row is theirs and nothing else. There is no id to
--    save, follow, look up later, or hand to somebody else. `pod` is returned,
--    because the phone needs to know which pod it is in — it names a table, not
--    a person, everybody in that pod already has the same value, and no
--    function anywhere accepts it as an argument.
--
--    Being honest about the limit of rule 3: a stranger who shares your pod two
--    weeks running looks the same both weeks, because their name and their kin
--    are stable. You can notice a person. You cannot identify one, contact one,
--    or find one anywhere else — and being stable is the price of a name
--    meaning anything at all, which is a trade worth making.
--
-- 4. No timestamps. When somebody joined, when they last pushed, when they were
--    last awake — a board needs none of it, and "who is online right now" is
--    exactly the thing that turns a scoreboard into surveillance.
--
-- So what a student can learn about a stranger is: two words, a fish, and a
-- number that goes up. Not their school, not their courses, not their grades,
-- not their name, not where they are, not whether they are awake.
--
-- Order is the board's order — points down, then the two name numbers, which
-- are already in the row and give nothing else away. Ties deliberately do not
-- fall back on who joined first, because that would leak an ordering the rows
-- themselves refuse to show. The phone numbers the ranks off this order and
-- never re-sorts, so two phones cannot disagree about who is second.
--
-- A pod with one member returns one member. Nothing here pads a list, and
-- nothing here ever will.
create or replace function pod_board(p_pod uuid, p_player uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
           'pod',  p.id,
           'week', p.week,
           'tier', p.tier,
           'members', coalesce((
             select jsonb_agg(jsonb_build_object(
                        'you',     m.player_id = p_player,
                        'adj',     pl.name_adj,
                        'noun',    pl.name_noun,
                        'species', pl.species,
                        'look',    pl.look,
                        'level',   pl.level,
                        'points',  m.points)
                      order by m.points desc, pl.name_adj, pl.name_noun)
               from pod_members m
               join players pl on pl.id = m.player_id
              where m.pod_id = p.id), '[]'::jsonb))
    from pods p
   where p.id = p_pod;
$$;

-- ---------------------------------------------------------------------------
-- Taking a seat

-- Called every time the league screen opens, not only the first time. It is
-- idempotent: a student who already has a seat this week keeps it, and the call
-- is really "hello, here is my kin as it looks today".
--
-- Pod choice is the oldest pod still open at this tier this week, taken with
-- `for update skip locked` so one stuck transaction parks a single joiner
-- instead of every joiner. The advisory lock around the search is what prevents
-- the ugly case: twenty students arriving in the same second when no pod is
-- open, each politely creating their own pod of one. Serialising joiners at a
-- single (week, tier) costs a few milliseconds once a week per student, and it
-- is the difference between one board with company on it and twenty lonely
-- ones.
--
-- Twenty seats is the cap. Leaving and joining again may seat you somewhere
-- else, and there is deliberately no cooldown on that: no pod is better than
-- another, nothing is won, and nobody is pushed down, so there is nothing to
-- shop for.
--
-- Returns {"pod": …, "week": …, "tier": …}. The week is in there so the phone
-- can tell honestly when its own week and the pod's week have drifted apart at
-- the boundary, instead of quietly showing the wrong one.
create or replace function join_pod(p_player uuid, p_token text,
                                    p_species text, p_look text, p_level integer)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  c_seats constant integer := 20;
  v_week  text := iso_week();
  v_start timestamptz := date_trunc('week', now() at time zone 'utc') at time zone 'utc';
  v_tier  smallint;
  v_pod   uuid;
begin
  perform require_player(p_player, p_token);
  -- Any finished week of theirs is paid out before they are seated, so somebody
  -- promoted last week joins the water they earned.
  perform settle_weeks(p_player);
  perform set_kin(p_player, p_species, p_look, p_level);

  select pl.tier into v_tier from players pl where pl.id = p_player;

  select m.pod_id into v_pod
    from pod_members m
   where m.player_id = p_player and m.week = v_week;

  if v_pod is null then
    perform pg_advisory_xact_lock(hashtext(v_week || ':' || v_tier));

    select p.id into v_pod
      from pods p
     where p.week = v_week and p.tier = v_tier and p.seats < c_seats
     order by p.created_at
     limit 1
     for update skip locked;

    if v_pod is null then
      insert into pods (week, tier) values (v_week, v_tier) returning id into v_pod;
    end if;

    insert into pod_members (pod_id, player_id, week, peak_at)
    values (v_pod, p_player, v_week, v_start)
    on conflict (player_id, week) do nothing;

    -- If that conflicted, this phone tapped twice and already has a seat
    -- somewhere. Keep the seat that exists rather than the one we just picked.
    select m.pod_id into v_pod
      from pod_members m
     where m.player_id = p_player and m.week = v_week;
  end if;

  return jsonb_build_object('pod', v_pod, 'week', v_week, 'tier', v_tier);
end;
$$;

-- ---------------------------------------------------------------------------
-- Putting a number on the board

-- The phone says what it earned this week and gets the board back. The server
-- writes down the largest number a person could plausibly have earned by now,
-- which is almost always exactly what was sent.
--
-- It clamps instead of refusing, on purpose. An error here reaches a student as
-- a broken league in a week they worked hard, and the likeliest honest cause of
-- a too-large number is a mistake in our own pay table, not a teenager with a
-- proxy. A clamp shows a slightly small number and keeps working. A refusal
-- shows nothing and blames the student.
--
-- Two bounds, and neither one is a lock.
--
-- 1. A hard ceiling of 5,000, derived from the real pay table. A heroic honest
--    week is roughly: three study tasks a day (420) and a couple of life tasks
--    (140), the Daily Word (210), Number Line (175), two hours of focus a day
--    at a coin a minute (840), a lesson a day (140), and a brutal hand-in week
--    of twenty Canvas assignments at 30 each (600). That is about 2,500.
--    Doubling it covers a student with a long custom task list and a heavier
--    week than any of us has pictured. 5,000 is also four and a half times Open
--    Water's bar, the highest bar there is, so no honest student comes near it.
--    It exists to stop a board displaying 9,999,999, not to catch anybody.
--
-- 2. A growth bound: your peak, plus 600, plus 250 an hour since that peak was
--    set. The 600 is room for an honest burst — checking off fifteen Canvas
--    assignments in one sitting adds 450 in a minute, and clamping that would
--    be punishing somebody for a good afternoon. The 250 an hour is roughly ten
--    times the fastest anyone can earn for any length of time (focus pays one
--    coin a minute), so it never touches a real student, and it means a fresh
--    liar needs the better part of a day of wall-clock time to reach the
--    ceiling instead of one request.
--
-- Why the bound is measured from `points_peak` and not from the number on the
-- board. A student who un-checks something honestly sends a smaller number, and
-- the board should show it. If the allowance were measured from that smaller
-- number, the same student would be clamped on the way back up and left stuck
-- below their real score for hours — punished for fixing a mistake. And if the
-- allowance were a step permitted per push rather than per hour, a patient
-- cheater would simply push more often, or thrash down and up, spending a fresh
-- step on ground they had already covered. A peak never falls, so time is the
-- only thing that ever buys room, and un-checking and re-checking a task buys
-- precisely none.
--
-- What it all adds up to: cheating here is capped and slow. It is not hard. A
-- patient liar can sit at the ceiling every week, climb one tier a week — which
-- is also the fastest an honest student can climb — and hold a pennant nobody
-- can see them holding. That is the deal, and it is the deal because there are
-- no accounts here and nothing to check a score against.
--
-- Answers null when there is no seat this week, rather than raising. The phone
-- treats that as "join first, then try again", which is a state it recovers
-- from on its own and the student never needs to see. A wrong token still
-- raises: that is not a state, that is a stranger.
create or replace function push_points(p_player uuid, p_token text, p_points integer,
                                       p_species text, p_look text, p_level integer)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  c_ceiling constant integer := 5000;   -- see note 1 above
  c_burst   constant integer := 600;    -- see note 2 above
  c_rate    constant integer := 250;    -- points an hour
  v_week    text := iso_week();
  v_start   timestamptz := date_trunc('week', now() at time zone 'utc') at time zone 'utc';
  v_pod     uuid;
  v_peak    integer;
  v_peak_at timestamptz;
  v_allow   integer;
  v_points  integer;
begin
  perform require_player(p_player, p_token);
  perform settle_weeks(p_player);
  perform set_kin(p_player, p_species, p_look, p_level);

  select m.pod_id, m.points_peak, m.peak_at into v_pod, v_peak, v_peak_at
    from pod_members m
   where m.player_id = p_player and m.week = v_week
   for update of m;
  if not found then
    return null;
  end if;

  v_allow := least(
    c_ceiling,
    v_peak + c_burst
      + floor(c_rate * extract(epoch from (now() - greatest(v_peak_at, v_start))) / 3600.0)::integer
  );
  v_points := least(greatest(coalesce(p_points, 0), 0), v_allow);

  update pod_members m
     set points      = v_points,
         points_peak = greatest(m.points_peak, v_points),
         -- The clock only restarts when the peak actually rises.
         peak_at     = case when v_points > m.points_peak then now() else m.peak_at end
   where m.player_id = p_player and m.week = v_week;

  return pod_board(v_pod, p_player);
end;
$$;

-- Reading the board without changing anything. Null means "no seat this week",
-- which is a different thing from a pod holding only you, and the app says two
-- different things about them.
create or replace function fetch_pod(p_player uuid, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_pod uuid;
begin
  perform require_player(p_player, p_token);
  perform settle_weeks(p_player);

  select m.pod_id into v_pod
    from pod_members m
   where m.player_id = p_player and m.week = iso_week();
  if v_pod is null then
    return null;
  end if;

  return pod_board(v_pod, p_player);
end;
$$;

-- ---------------------------------------------------------------------------
-- Leaving

-- Gives up this week's seat. The player row, the tier and everything behind it
-- are untouched — this is "not this week", not "never again". The trigger frees
-- the chair so somebody else can have it.
create or replace function leave_pod(p_player uuid, p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  delete from pod_members m
   where m.player_id = p_player and m.week = iso_week();
end;
$$;

-- The real delete. The player row goes and every seat they have ever held goes
-- with it by cascade: no tombstone, no soft delete, nothing kept back "for
-- analytics". The privacy policy promises this is immediate, so it is
-- immediate.
--
-- It takes their tier and their standing with it, which is the honest cost and
-- the app has to say so on the button. Nothing is recoverable afterwards: the
-- token was only ever stored as a hash, so there is no way to prove a new
-- player is the same person, and there is deliberately no account to log back
-- into.
create or replace function forget_player(p_player uuid, p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  delete from players pl where pl.id = p_player;
end;
$$;

-- ---------------------------------------------------------------------------
-- Housekeeping

-- Two sweeps, for two kinds of leftover.
--
-- An identity that never took a seat belongs to somebody who opened the league
-- screen once and closed it again. A week is long enough that a student who
-- said yes on a Sunday and joined the following Monday keeps their name, and
-- short enough that abandoned rows do not pile up forever. Anybody who has ever
-- sat in a pod is untouched by this, however long they have been away — see the
-- note on `players` about why that table has no expiry.
--
-- Old pods are somebody's score sitting in a database long after anyone could
-- want to look at it, which is a thing a privacy policy should not have to
-- promise around. Settled pods go after four weeks; the board only ever draws
-- the current week, so there is nothing to lose. A pod that never settled is
-- kept far longer, because deleting it would quietly throw away a promotion its
-- members earned and never collected — but not forever, because half a year
-- with not one member coming back means the week is over in every sense.
create or replace function purge_league()
returns void
language sql
security definer
set search_path = public
as $$
  delete from players
   where created_at < now() - interval '7 days'
     and not exists (select 1 from pod_members m where m.player_id = players.id);

  delete from pods
   where (settled_at is not null and settled_at < now() - interval '28 days')
      or created_at < now() - interval '26 weeks';
$$;

-- Same shape and the same graceful fallback as the pairing purge above: if
-- pg_cron is not enabled the run still succeeds and says what did not get set
-- up, instead of failing the whole file over a scheduler.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule('prepkin-purge-league')
      from cron.job where jobname = 'prepkin-purge-league';
    perform cron.schedule('prepkin-purge-league', '41 * * * *', 'select purge_league()');
  else
    raise warning 'pg_cron is not enabled: unused league identities and old pods will NOT be purged. Enable it in Database -> Extensions, then re-run this file.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- What the publishable key can reach
--
-- Six functions. Five of them want a token nobody can guess, and the sixth
-- creates a stranger with no name on them. The tables are locked and the
-- helpers are not callable from outside.

grant execute on function create_player()                                          to anon;
grant execute on function join_pod(uuid, text, text, text, integer)                to anon;
grant execute on function push_points(uuid, text, integer, text, text, integer)    to anon;
grant execute on function fetch_pod(uuid, text)                                    to anon;
grant execute on function leave_pod(uuid, text)                                    to anon;
grant execute on function forget_player(uuid, text)                                to anon;

-- Postgres grants EXECUTE on every new function to PUBLIC, and `anon` is a
-- member of PUBLIC. So revoking from `anon` alone — which is what the pairing
-- purge above does — leaves the door open through the role it inherits from.
-- To actually be unreachable these have to be revoked from PUBLIC, and that
-- includes fixing the older one.
revoke all on function purge_expired_pairings()          from public;
revoke all on function purge_league()                    from public;
revoke all on function require_player(uuid, text)        from public;
revoke all on function settle_weeks(uuid)                from public;
revoke all on function set_kin(uuid, text, text, integer) from public;
revoke all on function pod_board(uuid, uuid)             from public;
revoke all on function pod_seat_count()                  from public;

-- ---------------------------------------------------------------------------
-- What none of this can stop, written down so nobody is surprised later
--
-- create_player takes no code and no proof, because there is nothing it could
-- ask for that a student without an account could give. So somebody holding the
-- publishable key — which ships in every install — can mint identities in bulk
-- and take seats with them, and a pod can be stuffed with silent strangers
-- whose score never moves. Nothing in this schema can tell twenty bots from
-- twenty quiet students, because there is no account to look at.
--
-- What it costs them: one row per seat per week, and the prize is a boring
-- board. What it costs a student: a pod that looks quiet, which is also exactly
-- what an honest quiet week looks like. Nobody's tier moves, nobody's pennant
-- is touched, and nothing anybody typed is exposed, because nobody typed
-- anything.
--
-- If it ever actually happens, the fix is a rate limit at the edge — Supabase's
-- API gateway, keyed on IP — and not another rule in this file. A rule here has
-- nothing to weigh: every caller looks exactly the same, which is the whole
-- point of having built it this way.
