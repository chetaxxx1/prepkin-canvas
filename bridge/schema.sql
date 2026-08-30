-- Prepkin Canvas — bridge schema (run once in the Supabase SQL editor).
--
-- What this is for: the Chrome extension reads Canvas on your laptop, the iPhone
-- app needs those tasks. This is the one row in the middle that they share.
--
-- No accounts, no email, no name. A pairing code is the only thing that ties a
-- laptop to a phone, and it expires.

create table if not exists pairings (
  code        text primary key,
  todo        jsonb       not null default '[]'::jsonb,
  updated_at  timestamptz not null default now(),
  expires_at  timestamptz not null default (now() + interval '30 days')
);

-- Lock the table itself. With no policies, the public key cannot read, write,
-- or list anything here directly. The only way in is the two functions below,
-- and both of them demand the exact code. That means nobody can dump the table
-- to see other people's assignments.
alter table pairings enable row level security;

-- The extension calls this to hand over the latest Canvas list.
--
-- Two cheap guards, because the public key ships in every extension install:
-- a push must look like a real pairing code (so random writes cannot fill the
-- table with junk rows), and a payload is capped at 256 KB (a real semester is
-- a few KB; multi-megabyte bodies are only ever abuse).
create or replace function push_todo(p_code text, p_todo jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_code !~ '^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$' then
    return;
  end if;
  if pg_column_size(p_todo) > 262144 then
    return;
  end if;
  insert into pairings (code, todo, updated_at, expires_at)
  values (p_code, p_todo, now(), now() + interval '30 days')
  on conflict (code) do update
    set todo = excluded.todo,
        updated_at = now(),
        expires_at = now() + interval '30 days';
end;
$$;

-- The app calls this to pick the list up. Returns nothing for a wrong or
-- expired code, which is also what a guess gets.
create or replace function fetch_todo(p_code text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select todo from pairings where code = p_code and expires_at > now();
$$;

grant execute on function push_todo(text, jsonb) to anon;
grant execute on function fetch_todo(text)        to anon;

-- Housekeeping: rows nobody has touched in 30 days are dead weight.
-- Run by hand, or from a scheduled job later.
create or replace function purge_expired_pairings()
returns void
language sql
security definer
set search_path = public
as $$
  delete from pairings where expires_at < now();
$$;
