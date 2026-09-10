-- Prepkin — the social layer: friends, the daily board, tank visits.
--
-- Paste this into the Supabase SQL editor AFTER schema.sql. It is additive: it
-- adds columns to `players` and four tables of its own, and it never drops or
-- rewrites anything schema.sql created. Running it twice is safe.
--
-- Everything here follows the rules schema.sql already set, and they are worth
-- repeating because they are what makes this feature small enough to trust:
--
--   * There are no accounts. A player is the uuid and token schema.sql minted.
--   * There is no free text anywhere. A name is two integers into a word list
--     the app ships; a vibe is one integer into a list the app ships. There is
--     no column in this file a student could write a sentence into, so there is
--     nothing here to moderate, report or block — which is the only reason a
--     two-person team can ship a social feature at all.
--   * Nothing crosses between phones except numbers and ids from an allowlist.
--     No coins move. Coins are an honour-system check-off (see push_points in
--     schema.sql); letting them travel between players would let two friends
--     mint them for each other forever.
--
-- Design and the apps each part copies: design/SOCIAL-PLAN.md.

-- ---------------------------------------------------------------------------
-- The tank, as a friend sees it

-- Costumes and room scenes, allowlisted the same way species and looks are, so
-- "no free text" holds even for a cosmetic id. Keep in step with the app's
-- catalogue; an id the app does not know draws nothing, which is why the
-- foreign keys below matter.
create table if not exists kin_costumes (id text primary key);
create table if not exists kin_scenes   (id text primary key);

insert into kin_costumes (id) values
  ('none'), ('scholar'), ('ninja'), ('hoodie'), ('baker'),
  ('astronaut'), ('racer'), ('biker'), ('pajamas')
on conflict do nothing;

-- **Keep these in step with `Scene0.all` in ios/Sources/Theme.swift.** An id the
-- app sends that is not in here is not an error: `set_tank` coalesces it away and
-- silently keeps the old value, so a student at Deep would show to their friends
-- as whatever they were before. The first three ids below are the land scenes the
-- app retired; they stay so a row already carrying one still validates.
insert into kin_scenes (id) values
  ('lagoon'), ('reef'), ('kelp'), ('dusk'), ('deep'),
  ('classic'), ('harbor'), ('night')
on conflict do nothing;

alter table players add column if not exists costume text not null default 'none';
alter table players add column if not exists scene   text not null default 'lagoon';

do $$ begin
  alter table players add constraint players_costume_fk
    foreign key (costume) references kin_costumes(id);
exception when duplicate_object then null; end $$;

do $$ begin
  alter table players add constraint players_scene_fk
    foreign key (scene) references kin_scenes(id);
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- The friend code

-- Eight characters, in the XXXX-XXXX shape the app already draws. Minted the
-- first time a student opens the Add a friend sheet, not at sign-up, because
-- most students never open it.
--
-- It is deliberately NOT the player uuid: a code is something you read out loud
-- in a dorm and paste into Messages, so it has to be short, and something short
-- enough to say is short enough to guess. Guessing one wins you the right to
-- appear on somebody's friend list and see their fish. That is the whole prize,
-- which is why a code is allowed to be guessable and a token is not.
--
-- Rotatable: `rotate_code` below hands out a new one and the old one stops
-- working, which is how a student un-shares a link they have already sent.
alter table players add column if not exists friend_code text unique;

create or replace function make_friend_code()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  -- No 0/O/1/I/L. A code gets read aloud and typed by a stranger.
  v_alpha constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  v_code  text;
  v_bytes bytea;
  i       int;
begin
  for _try in 1..20 loop
    v_bytes := gen_random_bytes(8);
    v_code := '';
    for i in 0..7 loop
      v_code := v_code || substr(v_alpha, (get_byte(v_bytes, i) % length(v_alpha)) + 1, 1);
    end loop;
    if not exists (select 1 from players where friend_code = v_code) then
      return v_code;
    end if;
  end loop;
  raise exception 'could not mint a friend code';
end;
$$;

-- Returns this player's code, minting one on first ask. Idempotent.
create or replace function my_code(p_player uuid, p_token text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_code text;
begin
  perform require_player(p_player, p_token);
  select friend_code into v_code from players where id = p_player;
  if v_code is null then
    v_code := make_friend_code();
    update players set friend_code = v_code where id = p_player;
  end if;
  return v_code;
end;
$$;

create or replace function rotate_code(p_player uuid, p_token text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_code text;
begin
  perform require_player(p_player, p_token);
  v_code := make_friend_code();
  update players set friend_code = v_code where id = p_player;
  return v_code;
end;
$$;

-- ---------------------------------------------------------------------------
-- Friendships

-- One row per pair, stored with the smaller uuid first so a pair can only ever
-- exist once and neither side owns it. There is no pending state and no accept
-- step: handing somebody your code IS the consent, the same trade Duolingo and
-- Finch friend codes make. What a friend gets is the right to see a fish and a
-- solve time. Taking it back is one row deleted, from either side.
create table if not exists friendships (
  low        uuid not null references players(id) on delete cascade,
  high       uuid not null references players(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (low, high),
  constraint friendships_ordered check (low < high)
);

create index if not exists friendships_high_idx on friendships (high);

-- Everything one player is allowed to see about another. Used by every function
-- below, so there is exactly one answer to "what is public about a person".
create or replace function public_player(p_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'id',      pl.id,
    'adj',     pl.name_adj,
    'noun',    pl.name_noun,
    'species', pl.species,
    'look',    pl.look,
    'level',   pl.level,
    'costume', pl.costume,
    'scene',   pl.scene,
    'tier',    pl.best_tier)
    from players pl where pl.id = p_id;
$$;

-- Adds a friend by their code. Returns their public row, or null if the code
-- opens nothing — a wrong code and a code that used to exist are the same
-- answer, so a stranger cannot use this to find out whether a code is live.
create or replace function add_friend(p_player uuid, p_token text, p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_other uuid;
begin
  perform require_player(p_player, p_token);
  select id into v_other from players
   where friend_code = upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  -- Your own code is not an error and not a friendship. It is a student testing
  -- the thing, and it should do nothing quietly.
  if v_other is null or v_other = p_player then return null; end if;
  insert into friendships (low, high)
    values (least(p_player, v_other), greatest(p_player, v_other))
    on conflict do nothing;
  return public_player(v_other);
end;
$$;

create or replace function remove_friend(p_player uuid, p_token text, p_friend uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  delete from friendships
   where low = least(p_player, p_friend) and high = greatest(p_player, p_friend);
end;
$$;

-- ---------------------------------------------------------------------------
-- The daily board

-- One row per player per game per puzzle number.
--
-- **Keyed on the puzzle number, never on a date.** `PlayDeal.number(for:)` in
-- the app counts days from 2026-01-01 in the DEVICE's calendar, so two friends
-- in different time zones reach puzzle 251 hours apart. Keying on the date
-- would put them on different rows for the same board and the board would be a
-- lie. This is the single most load-bearing line in the file.
--
-- Time is here and it is not in the rating, on purpose. A phone's clock is a
-- phone's clock: a determined student can produce any `seconds` they like. That
-- is tolerable for a friend board, where the stake is bragging between people
-- who know each other, and it is not tolerable for a rating, which is why the
-- rating is computed on-device from solved-or-not and never from a clock
-- (ios/Sources/Core/Rating.swift).
create table if not exists play_results (
  player    uuid     not null references players(id) on delete cascade,
  puzzle_no integer  not null,
  game      text     not null,
  solved    boolean  not null,
  -- Null for a game that keeps no clock, and for a board that was not solved.
  seconds   integer,
  at        timestamptz not null default now(),
  primary key (player, puzzle_no, game),
  -- **Keep in step with `CoinReason`'s play kinds in ios/Sources/Core/Ledger.swift.**
  -- Unlike every other allowlist in these files, this one throws rather than
  -- coalescing, so a game id the app ships and this list does not is a hard error
  -- on push. Ladder and Thread were retired 2026-09-10 and replaced by Sort and
  -- Weave; the two old ids stay so an already-written row still validates.
  constraint play_results_game check (game in ('word','balance','pearls','trace','sort','weave',
                                               'ladder','thread')),
  constraint play_results_number  check (puzzle_no between 1 and 100000),
  constraint play_results_seconds check (seconds is null or seconds between 0 and 86400)
);

create index if not exists play_results_puzzle_idx on play_results (puzzle_no);

-- Records one result. **First write wins**: `on conflict do nothing`, so a
-- board cannot be re-submitted with a better time after the fact. A student who
-- solves it in four minutes has solved it in four minutes.
create or replace function push_result(p_player uuid, p_token text,
                                       p_puzzle integer, p_game text,
                                       p_solved boolean, p_seconds integer default null)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  insert into play_results (player, puzzle_no, game, solved, seconds)
    values (p_player, p_puzzle, p_game, coalesce(p_solved, false),
            case when p_solved then p_seconds end)
    on conflict do nothing;
end;
$$;

-- You and your friends on one puzzle number.
--
-- Returns a list, you first, then friends. Each entry carries the public player
-- row and a `games` object of {game: {solved, seconds}} holding only the games
-- that person has actually finished or failed. A game missing from that object
-- means "not played yet", which the board draws as a blank — never as a zero
-- and never as a loss.
create or replace function friend_board(p_player uuid, p_token text, p_puzzle integer)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(entry order by is_you desc, done desc, total asc), '[]'::jsonb)
    into v_rows
    from (
      select
        (p.id = p_player) as is_you,
        count(r.game) filter (where r.solved) as done,
        coalesce(sum(r.seconds), 0) as total,
        public_player(p.id)
          || jsonb_build_object('you', p.id = p_player)
          || jsonb_build_object('games', coalesce(
               jsonb_object_agg(r.game, jsonb_build_object('solved', r.solved, 'secs', r.seconds))
                 filter (where r.game is not null), '{}'::jsonb)) as entry
        from players p
        left join play_results r on r.player = p.id and r.puzzle_no = p_puzzle
       where p.id = p_player
          or p.id in (select high from friendships where low  = p_player
                      union all
                      select low  from friendships where high = p_player)
       group by p.id
    ) ranked;
  return v_rows;
end;
$$;

-- ---------------------------------------------------------------------------
-- Visits

-- One vibe per pair per day, copied from Finch, whose Good Vibes are free,
-- preset, and limited to one visit each. `kind` is an index into the app's own
-- list of drawn cards; the check keeps it inside a range this build knows, so a
-- future card cannot arrive at a phone that has no picture for it.
--
-- `day` is the SENDER's local day, passed in, because that is the day the
-- sender's one-per-day allowance belongs to. It is a date and not a timestamp
-- for the same reason: nothing here needs to know what hour anybody plays at.
create table if not exists vibes (
  sender   uuid    not null references players(id) on delete cascade,
  receiver uuid    not null references players(id) on delete cascade,
  day      date    not null,
  kind     smallint not null,
  at       timestamptz not null default now(),
  primary key (sender, receiver, day),
  constraint vibes_kind check (kind between 0 and 15),
  constraint vibes_not_self check (sender <> receiver)
);

create index if not exists vibes_receiver_idx on vibes (receiver, day);

-- Sends one. Returns true if it landed, false if today's was already sent or
-- the two are not friends. False is not an error and the app says nothing
-- dramatic about it — the button simply shows its settled state.
create or replace function send_vibe(p_player uuid, p_token text,
                                     p_friend uuid, p_kind smallint, p_day date)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_ok boolean;
begin
  perform require_player(p_player, p_token);
  if not exists (select 1 from friendships
                  where low = least(p_player, p_friend) and high = greatest(p_player, p_friend))
  then
    return false;
  end if;
  insert into vibes (sender, receiver, day, kind)
    values (p_player, p_friend, p_day, p_kind)
    on conflict do nothing;
  get diagnostics v_ok = row_count;
  return v_ok;
end;
$$;

-- Who visited you on `p_day`, so their kin can swim in your tank for the day.
-- Sender's public row plus the card they sent. Nothing else travels.
create or replace function fetch_visits(p_player uuid, p_token text, p_day date)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(public_player(v.sender) || jsonb_build_object('kind', v.kind)
                            order by v.at), '[]'::jsonb)
    into v_rows
    from vibes v
   -- Yesterday too, on purpose. `day` is the SENDER's local day, and this is
   -- called with the RECEIVER's: a sender twelve hours ahead writes day D while
   -- the receiver is still on D-1, and an exact match loses the visit for a day
   -- and then shows it late. The app keeps the newest row per sender, so the
   -- extra day cannot draw anybody twice. See SOCIAL-PLAN.md F2.
   where v.receiver = p_player and v.day between p_day - 1 and p_day;
  return v_rows;
end;
$$;

-- Which friends you have already visited today, so the app can draw the sent
-- state without asking friend by friend.
create or replace function fetch_sent(p_player uuid, p_token text, p_day date)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(v.receiver), '[]'::jsonb) into v_rows
    from vibes v where v.sender = p_player and v.day = p_day;
  return v_rows;
end;
$$;

-- ---------------------------------------------------------------------------
-- The tank, written

-- Extends set_kin with the two cosmetic ids a visitor's screen needs. Separate
-- from set_kin so schema.sql stays untouched; both are cosmetic and neither
-- decides anything.
create or replace function set_tank(p_player uuid, p_token text,
                                    p_costume text, p_scene text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  update players
     set costume = coalesce((select id from kin_costumes where id = p_costume), costume),
         scene   = coalesce((select id from kin_scenes   where id = p_scene),   scene)
   where id = p_player;
end;
$$;

-- ---------------------------------------------------------------------------
-- Study Together

-- One live row per player: they are working, and this is when they stop.
--
-- **The server sets ends_at, from a capped number of minutes.** A phone allowed to
-- name its own end time could sit in everybody's Friends tab all day looking busy,
-- and the one thing this feature sells is that the person really is at a desk.
--
-- There is no cleanup job. A session is over when `ends_at` passes, and the only
-- reader below filters on that, so an abandoned row is already invisible. The row
-- is overwritten by the next session and deleted when a student stops early.
--
-- What is NOT here: what they are working on. `FRIENDS-PLAN.md` wants the Canvas
-- course crossover and it may be worth building, but it is real personal data on a
-- remote server and it gets its own decision. This table carries a clock.
create table if not exists focus_sessions (
  player     uuid primary key references players(id) on delete cascade,
  started_at timestamptz not null default now(),
  ends_at    timestamptz not null
);

create index if not exists focus_sessions_ends_idx on focus_sessions (ends_at);

-- Starts a session and returns the end time it decided. 120 minutes is the ceiling
-- and 1 the floor; the app offers 15, 25 and 45, and the range is wider than the
-- app only so a future length does not need a migration.
create or replace function start_focus(p_player uuid, p_token text, p_minutes integer)
returns timestamptz
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_ends timestamptz;
begin
  perform require_player(p_player, p_token);
  v_ends := now() + make_interval(mins => least(greatest(coalesce(p_minutes, 25), 1), 120));
  insert into focus_sessions (player, started_at, ends_at)
    values (p_player, now(), v_ends)
    on conflict (player) do update set started_at = now(), ends_at = v_ends;
  return v_ends;
end;
$$;

-- Stops early, or tidies up after finishing. Never an error: a student who taps
-- this twice, or whose phone retries it, has still stopped.
create or replace function end_focus(p_player uuid, p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  delete from focus_sessions where player = p_player;
end;
$$;

-- Friends who are working right now. Friends only — a stranger in your pod is not
-- somebody you sit down next to.
create or replace function friends_focusing(p_player uuid, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'id',      pl.id,
             'adj',     pl.name_adj,
             'noun',    pl.name_noun,
             'species', pl.species,
             'look',    pl.look,
             'level',   pl.level,
             'ends',    to_char(f.ends_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
           order by f.ends_at), '[]'::jsonb)
    into v_rows
    from focus_sessions f
    join players pl on pl.id = f.player
   where f.ends_at > now()
     and f.player in (select high from friendships where low  = p_player
                      union all
                      select low  from friendships where high = p_player);
  return v_rows;
end;
$$;

-- ---------------------------------------------------------------------------
-- Housekeeping

-- Results and vibes are the only rows here that grow without bound. A board
-- older than a fortnight is not on any screen, so it is not kept. Called the
-- same way purge_league is: by hand, or by a cron if one is ever added.
create or replace function purge_social(p_keep_days integer default 14)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  delete from vibes where day < current_date - p_keep_days;
  delete from play_results where at < now() - make_interval(days => p_keep_days);
  -- Not needed for correctness — friends_focusing already ignores these — but a
  -- table of finished clocks has no reason to grow forever.
  delete from focus_sessions where ends_at < now() - interval '1 day';
end;
$$;

-- Anonymous clients may call these and nothing else. Same posture as
-- schema.sql: the publishable key ships in every build, and the token is what
-- makes that safe.
grant execute on function my_code(uuid, text)                          to anon;
grant execute on function rotate_code(uuid, text)                      to anon;
grant execute on function add_friend(uuid, text, text)                 to anon;
grant execute on function remove_friend(uuid, text, uuid)              to anon;
grant execute on function push_result(uuid, text, integer, text, boolean, integer) to anon;
grant execute on function friend_board(uuid, text, integer)            to anon;
grant execute on function send_vibe(uuid, text, uuid, smallint, date)  to anon;
grant execute on function fetch_visits(uuid, text, date)               to anon;
grant execute on function fetch_sent(uuid, text, date)                 to anon;
grant execute on function set_tank(uuid, text, text, text)             to anon;
grant execute on function start_focus(uuid, text, integer)             to anon;
grant execute on function end_focus(uuid, text)                        to anon;
grant execute on function friends_focusing(uuid, text)                 to anon;

-- Helpers nobody outside this file may call, revoked from PUBLIC the way
-- schema.sql revokes its own. `security definer` means a grant left in place
-- here would hand an anonymous caller the definer's rights.
revoke all on function make_friend_code()            from public;
revoke all on function public_player(uuid)           from public;
revoke all on function purge_social(integer)         from public;

alter table focus_sessions enable row level security;
alter table friendships  enable row level security;
alter table play_results enable row level security;
alter table vibes        enable row level security;
alter table kin_costumes enable row level security;
alter table kin_scenes   enable row level security;
