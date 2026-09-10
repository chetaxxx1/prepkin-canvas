-- Prepkin — the syllabus scanner's monthly tally.
--
-- Paste this into the Supabase SQL editor AFTER schema.sql. Additive, safe to
-- run twice. One table and one function; only the parse_schedule edge function
-- (running as service_role) may call it.
--
-- There is no student data here. A subscriber is the App Store's
-- originalTransactionId with an "apple:" prefix, which is a number Apple
-- minted and nothing else. The count is how many photos that subscription
-- has scanned this month. design/CALENDAR-PLAN.md, "Plus only, 50 photos a month".

create table if not exists scan_counts (
  subscriber  text        not null,
  month       text        not null,   -- "2026-09", in the student's own time zone
  count       integer     not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (subscriber, month)
);

alter table scan_counts enable row level security;
-- No policies on purpose: anon and authenticated cannot read or write rows.
-- The function below is security definer and is the only door.

-- Adds one to this month's count if it is under the limit. Returns the new
-- count, or -1 when the limit is already reached (and nothing was added).
create or replace function bump_scan(p_subscriber text, p_month text, p_limit integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if p_subscriber is null or length(p_subscriber) = 0 or p_month !~ '^\d{4}-\d{2}$' then
    raise exception 'bad key';
  end if;
  insert into scan_counts (subscriber, month, count)
       values (p_subscriber, p_month, 1)
  on conflict (subscriber, month) do update
       set count      = scan_counts.count + 1,
           updated_at = now()
     where scan_counts.count < p_limit
  returning count into v_count;
  if v_count is null then
    return -1;
  end if;
  return v_count;
end;
$$;

revoke all on function bump_scan(text, text, integer) from public, anon, authenticated;
grant execute on function bump_scan(text, text, integer) to service_role;

-- Old months are worthless after 60 days. Run by hand or on a schedule.
create or replace function purge_old_scan_counts()
returns void
language sql
security definer
set search_path = public
as $$
  delete from scan_counts where updated_at < now() - interval '60 days';
$$;
revoke all on function purge_old_scan_counts() from public, anon, authenticated;
