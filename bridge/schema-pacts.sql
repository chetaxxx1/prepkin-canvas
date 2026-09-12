-- Prepkin — races: one friend, one week, a pennant for whoever finishes ahead.
--
-- Paste this into the Supabase SQL editor AFTER schema.sql, schema-social.sql and
-- schema-friends.sql. Additive: one table, three functions, one purge. Running it
-- twice is safe.
--
-- Copied from Apple Watch's Activity competition (design/WEEKLY-BOARD.md, "Next
-- slice"): you invite one friend, they accept, and the two of you are compared for
-- a fixed window. Apple's window is seven days from tomorrow; ours is the ISO week
-- the invite was sent in, because that is the window both phones already score
-- for the board, and it needs no clock of its own. The bridge holds only the
-- handshake. **No score lives here** — each phone works the race out from the
-- `daily_stats` rows it already fetches, so nothing on this table can be forged
-- into a win, and a phone that never accepted has nothing to fetch.
--
-- Same three rules as every other social table: no accounts, no free text, no
-- coins. A pact is two ids, a week, a kind and three timestamps.

-- ---------------------------------------------------------------------------
-- The table

create table if not exists pacts (
  id          uuid primary key default gen_random_uuid(),
  low         uuid not null references players(id) on delete cascade,
  high        uuid not null references players(id) on delete cascade,
  proposer    uuid not null references players(id) on delete cascade,
  -- 1 = a race. Room for other pacts later without a migration.
  kind        smallint not null default 1,
  -- The ISO week the pact is for, as the phone writes it: '2026-W37'.
  week        text not null,
  created_at  timestamptz not null default now(),
  accepted_at timestamptz,
  declined_at timestamptz,
  constraint pacts_ordered   check (low < high),
  constraint pacts_proposer  check (proposer = low or proposer = high),
  constraint pacts_kind      check (kind between 1 and 15),
  constraint pacts_week      check (week ~ '^[0-9]{4}-W[0-9]{2}$'),
  -- One pact of a kind per pair per week. Inviting twice is the same invite.
  constraint pacts_one_per_week unique (low, high, kind, week)
);

create index if not exists pacts_high_idx on pacts (high, week);
create index if not exists pacts_low_idx  on pacts (low, week);

-- ---------------------------------------------------------------------------
-- Inviting

-- Invites `p_other` to a race in `p_week`. Only a friend can be invited, and a
-- pair can hold one race a week: a second invite returns the row that already
-- exists rather than a second row. Returns the pact.
create or replace function propose_pact(p_player uuid, p_token text,
                                        p_other uuid, p_week text,
                                        p_kind smallint default 1)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_low  uuid := least(p_player, p_other);
  v_high uuid := greatest(p_player, p_other);
  v_row  pacts%rowtype;
begin
  perform require_player(p_player, p_token);
  if p_other is null or p_other = p_player then
    raise exception 'not a friend' using errcode = 'P0001';
  end if;
  if not exists (select 1 from friendships where low = v_low and high = v_high) then
    raise exception 'not a friend' using errcode = 'P0001';
  end if;
  insert into pacts (low, high, proposer, kind, week)
    values (v_low, v_high, p_player, p_kind, p_week)
    on conflict (low, high, kind, week) do nothing;
  select * into v_row from pacts
   where low = v_low and high = v_high and kind = p_kind and week = p_week;
  return pact_row(v_row, p_player);
end;
$$;

-- Accepts or declines an invite addressed to `p_player`. Only the invited side
-- can answer, only once, and only while the week is still on. Returns the pact.
create or replace function answer_pact(p_player uuid, p_token text,
                                       p_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_row pacts%rowtype;
begin
  perform require_player(p_player, p_token);
  select * into v_row from pacts where id = p_id;
  if v_row.id is null or (v_row.low <> p_player and v_row.high <> p_player)
     or v_row.proposer = p_player then
    raise exception 'not yours to answer' using errcode = 'P0001';
  end if;
  if v_row.accepted_at is null and v_row.declined_at is null then
    update pacts
       set accepted_at = case when p_accept then now() else null end,
           declined_at = case when p_accept then null else now() end
     where id = p_id
     returning * into v_row;
  end if;
  return pact_row(v_row, p_player);
end;
$$;

-- Every pact `p_player` is in, for `p_from` week onward (the phone asks for last
-- week and this one). Declined ones are left out: a declined invite is not news.
create or replace function fetch_pacts(p_player uuid, p_token text, p_from text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_rows jsonb;
begin
  perform require_player(p_player, p_token);
  select coalesce(jsonb_agg(pact_row(p, p_player) order by p.created_at), '[]'::jsonb)
    into v_rows
    from pacts p
   where (p.low = p_player or p.high = p_player)
     and p.week >= p_from
     and p.declined_at is null;
  return v_rows;
end;
$$;

-- One pact as the phone reads it: the other person's public row, who proposed,
-- the week, and whether it is on. `other` is `public_player`, so the phone draws
-- the same fish it draws everywhere else.
create or replace function pact_row(p pacts, p_me uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'id',       p.id,
    'kind',     p.kind,
    'week',     p.week,
    'mine',     p.proposer = p_me,
    'accepted', p.accepted_at is not null,
    'declined', p.declined_at is not null,
    'other',    public_player(case when p.low = p_me then p.high else p.low end));
$$;

-- ---------------------------------------------------------------------------
-- Housekeeping

-- A pact is one week long. Rows older than the fortnight the phone ever asks for
-- go with the daily stats.
create or replace function purge_pacts(p_keep_days integer default 21)
returns void
language sql
security definer
set search_path = public, extensions
as $$
  delete from pacts where created_at < now() - make_interval(days => p_keep_days);
$$;

-- ---------------------------------------------------------------------------
-- Grants

grant execute on function propose_pact(uuid, text, uuid, text, smallint) to anon;
grant execute on function answer_pact(uuid, text, uuid, boolean)         to anon;
grant execute on function fetch_pacts(uuid, text, text)                  to anon;

revoke all on function pact_row(pacts, uuid)  from public;
revoke all on function purge_pacts(integer)   from public;

alter table pacts enable row level security;
