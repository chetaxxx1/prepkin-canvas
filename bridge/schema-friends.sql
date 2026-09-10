-- Prepkin — friends, the missing pieces: the list, blocks, reports, today stats,
-- privacy flags, device tokens.
--
-- Paste this into the Supabase SQL editor AFTER schema.sql and schema-social.sql.
-- Additive, like schema-social.sql: it adds columns to `players`, four tables of
-- its own, and one replacement of `add_friend` that adds the block check. Running
-- it twice is safe.
--
-- Same three rules, because they are what keeps this small:
--   * No accounts. A player is the uuid and token schema.sql minted.
--   * No free text. Every column here is an id, an integer, a flag or a time.
--     A nickname for a friend lives on the phone that typed it and never here.
--   * No coins cross. Today's stats are four small counts for drawing a line like
--     "Focused 45 min"; nothing reads them to pay anybody.
--
-- Plan: design/FRIENDS-BUILD-PLAN.md.

-- ---------------------------------------------------------------------------
-- Privacy flags

-- What a friend is allowed to see, beyond the fish.
--
-- **`share_today` is off until a student turns it on.** V3-A screen 5 asks for
-- sensitive rows to default off, and this is the sensitive one: there is no accept
-- step (D1), so anybody who is handed a code becomes a friend on the spot, and the
-- launch plan has students swapping codes in public threads. On by default would
-- mean a stranger reads a fortnight of somebody's study log before they have seen
-- a single screen about it. The board is the fish and a solve time, which is the
-- thing a code was handed over for, so that one stays on.
alter table players add column if not exists share_today boolean not null default false;
alter table players add column if not exists share_board boolean not null default true;

create or replace function set_sharing(p_player uuid, p_token text,
                                       p_today boolean, p_board boolean)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  update players
     set share_today = coalesce(p_today, share_today),
         share_board = coalesce(p_board, share_board)
   where id = p_player;
end;
$$;

-- ---------------------------------------------------------------------------
-- Blocks

-- One row per (blocker, blocked). Blocking removes the friendship and makes
-- add_friend answer null in both directions, the same null a wrong code gets, so
-- the blocked person cannot tell they were blocked from being wrong.
create table if not exists blocks (
  blocker    uuid not null references players(id) on delete cascade,
  blocked    uuid not null references players(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked),
  constraint blocks_not_self check (blocker <> blocked)
);

create index if not exists blocks_blocked_idx on blocks (blocked);

create or replace function is_blocked(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (select 1 from blocks
                  where (blocker = p_a and blocked = p_b)
                     or (blocker = p_b and blocked = p_a));
$$;

create or replace function block_player(p_player uuid, p_token text, p_other uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  if p_other is null or p_other = p_player then return; end if;
  delete from friendships
   where low = least(p_player, p_other) and high = greatest(p_player, p_other);
  insert into blocks (blocker, blocked) values (p_player, p_other)
    on conflict do nothing;
end;
$$;

-- Replaces schema-social.sql's add_friend with the same body plus the block check.
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
  if v_other is null or v_other = p_player then return null; end if;
  if is_blocked(p_player, v_other) then return null; end if;
  insert into friendships (low, high)
    values (least(p_player, v_other), greatest(p_player, v_other))
    on conflict do nothing;
  return public_player(v_other);
end;
$$;

-- ---------------------------------------------------------------------------
-- Reports

-- A pair of ids and a time. There is no text a student could have sent, so there
-- is nothing to attach; a report says "look at this player" and is read by hand
-- in the table view. Apple asks for a way to report and a way to block, and this
-- is the smallest pair that is real.
create table if not exists reports (
  reporter   uuid not null references players(id) on delete cascade,
  reported   uuid not null references players(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (reporter, reported)
);

create or replace function report_player(p_player uuid, p_token text, p_other uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  if p_other is null or p_other = p_player then return; end if;
  insert into reports (reporter, reported) values (p_player, p_other)
    on conflict do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- The list

-- Every friend, with when the pair was made and whether they are on shift right
-- now. One call draws the tab. The app diffs this against the list it cached to
-- find "Maya added you" — no inbox table, no unread flag on the server.
create or replace function fetch_friends(p_player uuid, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(
           public_player(f.other)
           || jsonb_build_object(
                'since', to_char(f.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                'shift', case when s.ends_at > now()
                              then to_char(s.ends_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
                              end)
           order by f.created_at), '[]'::jsonb)
    into v_rows
    from (
      select high as other, created_at from friendships where low  = p_player
      union all
      select low  as other, created_at from friendships where high = p_player
    ) f
    left join focus_sessions s on s.player = f.other;
  return v_rows;
end;
$$;

-- ---------------------------------------------------------------------------
-- Today

-- Four counts per player per local day. Enough to write "Focused 45 min" and
-- "You and 4 friends: 41 tasks, 6h focus", and nothing else. Capped so a forged
-- row can brag but cannot break a layout. Nobody is paid from these.
create table if not exists daily_stats (
  player    uuid     not null references players(id) on delete cascade,
  day       date     not null,
  tasks     smallint not null default 0,
  focus_min smallint not null default 0,
  lessons   smallint not null default 0,
  games     smallint not null default 0,
  at        timestamptz not null default now(),
  primary key (player, day),
  constraint daily_stats_tasks   check (tasks     between 0 and 200),
  constraint daily_stats_focus   check (focus_min between 0 and 1440),
  constraint daily_stats_lessons check (lessons   between 0 and 100),
  constraint daily_stats_games   check (games     between 0 and 6)
);

create index if not exists daily_stats_day_idx on daily_stats (day);

-- Upsert. The phone sends its whole-day totals, so the row is replaced, never
-- summed — a retry cannot double anything.
create or replace function push_today(p_player uuid, p_token text, p_day date,
                                      p_tasks integer, p_focus integer,
                                      p_lessons integer, p_games integer)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  insert into daily_stats (player, day, tasks, focus_min, lessons, games, at)
    values (p_player, p_day,
            least(greatest(coalesce(p_tasks, 0), 0), 200),
            least(greatest(coalesce(p_focus, 0), 0), 1440),
            least(greatest(coalesce(p_lessons, 0), 0), 100),
            least(greatest(coalesce(p_games, 0), 0), 6),
            now())
    on conflict (player, day) do update
      set tasks = excluded.tasks, focus_min = excluded.focus_min,
          lessons = excluded.lessons, games = excluded.games, at = now();
end;
$$;

-- Friends' rows between two days inclusive, only for friends who share. A friend
-- with no row for a day simply has no line; the app never draws a zero.
create or replace function fetch_today(p_player uuid, p_token text,
                                       p_from date, p_to date)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', d.player, 'day', d.day, 'tasks', d.tasks,
           'focus', d.focus_min, 'lessons', d.lessons, 'games', d.games)
           order by d.day, d.player), '[]'::jsonb)
    into v_rows
    from daily_stats d
    join players pl on pl.id = d.player
   where d.day between p_from and least(p_to, p_from + 14)
     and (d.player = p_player
          or (pl.share_today
              and d.player in (select high from friendships where low  = p_player
                               union all
                               select low  from friendships where high = p_player)));
  return v_rows;
end;
$$;

-- ---------------------------------------------------------------------------
-- Device tokens (phase 3, push)

-- One APNs token per player per install. Written by the app after iOS hands one
-- out; read only by the `notify` edge function, never by another player.
create table if not exists device_tokens (
  player   uuid not null references players(id) on delete cascade,
  token    text not null,
  platform text not null default 'ios',
  at       timestamptz not null default now(),
  primary key (player, token),
  constraint device_tokens_platform check (platform in ('ios')),
  constraint device_tokens_token_len check (length(token) between 32 and 256)
);

create or replace function set_device_token(p_player uuid, p_token text, p_device text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform require_player(p_player, p_token);
  insert into device_tokens (player, token) values (p_player, p_device)
    on conflict (player, token) do update set at = now();
end;
$$;

-- ---------------------------------------------------------------------------
-- Housekeeping

create or replace function purge_friends(p_keep_days integer default 14)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  delete from daily_stats where day < current_date - p_keep_days;
  delete from device_tokens where at < now() - interval '90 days';
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants. Anonymous clients may call these and nothing else.

grant execute on function set_sharing(uuid, text, boolean, boolean)                     to anon;
grant execute on function block_player(uuid, text, uuid)                               to anon;
grant execute on function add_friend(uuid, text, text)                                 to anon;
grant execute on function report_player(uuid, text, uuid)                              to anon;
grant execute on function fetch_friends(uuid, text)                                    to anon;
grant execute on function push_today(uuid, text, date, integer, integer, integer, integer) to anon;
grant execute on function fetch_today(uuid, text, date, date)                          to anon;
grant execute on function set_device_token(uuid, text, text)                           to anon;

revoke all on function is_blocked(uuid, uuid)     from public;
revoke all on function purge_friends(integer)     from public;

alter table blocks        enable row level security;
alter table reports       enable row level security;
alter table daily_stats   enable row level security;
alter table device_tokens enable row level security;
