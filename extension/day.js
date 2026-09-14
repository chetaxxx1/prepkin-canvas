// Reading the day: the date helpers the panel and the popup both use. No
// chrome.*, no DOM, so `node --test` reads it and both surfaces share one
// answer to "is this today?".

const DAY_MS = 86_400_000;

function startOfDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function sameLocalDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth()
      && a.getDate() === b.getDate();
}

/// How long work stays in "Overdue" before it moves to "Missing". Same seven
/// days as DAYS_OVERDUE in canvas.js, which is what stops the two lists from
/// showing the same row twice.
const MISSED_AFTER_DAYS = 7;

/// Splits the synced tasks the way the panel talks about them. "Overdue" is by
/// the clock, not the calendar: work due at 9 AM is overdue at 2 PM.
///
/// `missed` is work the school marked missing more than a week ago. It is kept
/// out of `overdue` on purpose: the buddy's line counts what slipped this week,
/// and a term's worth of old zeros in that number reads as a scolding.
/// `plannedOn(task)` gives the day the student said they would do it, or null.
/// It only ever moves work between "today" and "this week": planning something
/// for tomorrow does not stop it being overdue, and nothing a student plans
/// changes what the school is owed.
/// Finished, either way: Canvas saw a submission (`submittedAt`, verified), or
/// the student ticked it here (`doneAt`, their word). Every list reads this;
/// `submittedAt` alone keeps meaning "Canvas verified" (the recap, the cheer).
function isDone(t) { return !!(t.submittedAt || t.doneAt); }
/// When it was finished: Canvas's time when it has one, else the tick's.
function doneTime(t) { return t.submittedAt || t.doneAt || null; }
/// The synced tasks with the student's own ticks laid over them. `done` is the
/// map the worker keeps ({ taskId: isoAt }); a task Canvas already verified
/// never takes a tick, so the two never disagree.
function withDone(tasks, done = {}) {
  if (!done || typeof done !== 'object') return tasks;
  return tasks.map((t) => (!t.submittedAt && done[t.id] ? { ...t, doneAt: done[t.id] } : t));
}

/// The map after a sync: a tick for work Canvas has since received, or dropped
/// from every list, goes; the map never grows past the term.
function pruneDone(done, tasks) {
  const keep = new Set(tasks.filter((t) => !t.submittedAt).map((t) => t.id));
  const next = {};
  for (const [id, at] of Object.entries(done ?? {})) if (keep.has(id)) next[id] = at;
  return Object.keys(next).length === Object.keys(done ?? {}).length ? done : next;
}

function buckets(tasks, now = new Date(), plannedOn = () => null) {
  const pending = tasks.filter((t) => !isDone(t));
  const doneToday = tasks.filter((t) => {
    const at = doneTime(t) && new Date(doneTime(t));
    return at && !isNaN(at) && sameLocalDay(at, now);
  });
  const overdue = [], today = [], week = [], missed = [];
  for (const t of pending) {
    const due = t.dueAt ? new Date(t.dueAt) : null;
    if (!due || isNaN(due)) week.push(t);
    else if (due < now) {
      const days = (startOfDay(now) - startOfDay(due)) / DAY_MS;
      (t.missing && days > MISSED_AFTER_DAYS ? missed : overdue).push(t);
    }
    else if (sameLocalDay(due, now)) today.push(t);
    else week.push(t);
  }
  // A plan re-sorts only what is still ahead. Work due today that you moved to
  // Thursday leaves Today; work due Friday that you moved to today joins it.
  const planned = [], rest = [];
  for (const t of [...today, ...week]) {
    const day = plannedOn(t);
    if (!day) { (today.includes(t) ? planned : rest).push(t); continue; }
    (sameLocalDay(day, now) ? planned : rest).push(t);
  }
  return { overdue, today: planned, week: rest, doneToday, missed };
}

function dueLabel(t, now = new Date()) {
  const due = t.dueAt ? new Date(t.dueAt) : null;
  if (!due || isNaN(due)) return 'No due date';
  const time = due.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  if (due < now) {
    // Calendar days, not elapsed hours: across a clock change a day is not
    // 24 hours, and "yesterday" is a date, not a duration.
    const days = Math.round((startOfDay(now) - startOfDay(due)) / DAY_MS);
    const when = days === 0 ? `${time} today`
      : days === 1 ? 'yesterday'
      // Past a week a weekday name is a guess — "Tue" could be any Tuesday —
      // so work this old says its date instead.
      : days <= 6 ? due.toLocaleDateString([], { weekday: 'short' })
      : due.toLocaleDateString([], { month: 'short', day: 'numeric' });
    return `Was due ${when} · still counts`;
  }
  if (sameLocalDay(due, now)) return `Due ${time}`;
  return `${due.toLocaleDateString([], { weekday: 'short' })} · ${time}`;
}

function submittedLabel(t) {
  const at = new Date(t.submittedAt);
  if (isNaN(at)) return 'Submitted · verified';
  return `Submitted ${at.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })} · verified`;
}


/// What the buddy says. Calm on purpose: no alarms, no shame. Overdue work is
/// "still counts", never a red wall.
/// `short` is the subline for a place one line wide, like the rail.
function voice({ overdue, today, doneToday }) {
  const o = overdue.length, t = today.length, d = doneToday.length;
  const count = (n) => ['Zero', 'One', 'Two', 'Three', 'Four', 'Five'][n] ?? String(n);
  if (o) {
    return {
      face: 'faceDeadpan', worried: true,
      headline: 'Late work still counts',
      subline: 'Pick one to start. Ten minutes is enough.',
      short: 'Pick one to start.',
    };
  }
  if (!t) {
    return d
      ? { face: 'faceDelight', headline: 'All done for today', subline: 'Rest counts too.', short: 'Rest counts too.' }
      : { face: 'faceDelight', headline: 'Nothing due today', subline: 'Enjoy the space.', short: 'Enjoy the space.' };
  }
  return {
    face: 'faceIdle',
    headline: d ? 'Good pace today' : 'Ready when you are',
    subline: d ? `${d} done, ${t} to go. No rush.` : `${t === 1 ? 'One thing' : count(t) + ' things'} due today. Start small.`,
    short: d ? `${d} done, ${t} to go.` : `${t === 1 ? 'One thing' : count(t) + ' things'} today.`,
  };
}

/// The planner's list, grouped by day the way Todoist's Upcoming reads: what
/// slipped, then today and the next six days, then what sits further out
/// (folded), then work with no date, then old zeros the school marked missing
/// (folded, so a term of them never scolds). `dayOf(task)` is the day the
/// student planned it or the day it is due, or null. A finished thing stays in
/// its day for the day it was finished, struck; other days list pending work.
function dayGroups(tasks, now = new Date(), dayOf = () => null) {
  const today = startOfDay(now);
  const horizon = new Date(today.getTime() + 7 * DAY_MS);
  const byTime = (a, b) => Date.parse(a.dueAt ?? 0) - Date.parse(b.dueAt ?? 0);
  const past = [], later = [], undated = [], missed = [];
  const days = Array.from({ length: 7 }, (_, i) => ({ date: new Date(today.getTime() + i * DAY_MS), items: [] }));
  for (const t of tasks) {
    const day = dayOf(t);
    if (isDone(t)) {
      // Finished work shows only in the day it was finished, and only today.
      const at = doneTime(t) ? new Date(doneTime(t)) : null;
      if (at && !isNaN(at) && sameLocalDay(at, now)) days[0].items.push(t);
      continue;
    }
    if (!day) { undated.push(t); continue; }
    if (day < today) {
      const daysAgo = (today - startOfDay(day)) / DAY_MS;
      (t.missing && daysAgo > MISSED_AFTER_DAYS ? missed : past).push(t);
    } else if (day >= horizon) later.push(t);
    else days[Math.round((startOfDay(day) - today) / DAY_MS)].items.push(t);
  }
  past.sort(byTime); later.sort(byTime); missed.sort(byTime);
  for (const d of days) d.items.sort((a, b) => (isDone(a) - isDone(b)) || byTime(a, b));
  return { past, days, later, undated, missed };
}

/// The week's numbers for the rail: Monday to Sunday around `now`, how many
/// tasks fall in it and how many are handed in, split by course.
function weekStats(tasks, now = new Date()) {
  const today = startOfDay(now);
  const start = new Date(today.getTime() - ((today.getDay() + 6) % 7) * DAY_MS);
  const end = new Date(start.getTime() + 7 * DAY_MS);
  const inWeek = tasks.filter((t) => { const d = t.dueAt ? new Date(t.dueAt) : null; return d && !isNaN(d) && d >= start && d < end; });
  const byCourse = new Map();
  for (const t of inWeek) {
    const k = String(t.courseId);
    if (!byCourse.has(k)) byCourse.set(k, { courseId: k, name: t.courseName ?? '', colorHex: t.colorHex ?? null, total: 0, done: 0 });
    const c = byCourse.get(k); c.total++; if (isDone(t)) c.done++;
  }
  return {
    start, end, total: inWeek.length, done: inWeek.filter(isDone).length,
    byCourse: [...byCourse.values()].sort((a, b) => b.total - a.total),
  };
}

if (typeof module !== 'undefined') {
  module.exports = { DAY_MS, MISSED_AFTER_DAYS, startOfDay, sameLocalDay, buckets, dueLabel, submittedLabel, voice, weekStats, isDone, doneTime, withDone, pruneDone, dayGroups };
}
