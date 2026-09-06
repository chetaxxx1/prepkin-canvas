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

/// Splits the synced tasks the way the panel talks about them. "Overdue" is by
/// the clock, not the calendar: work due at 9 AM is overdue at 2 PM.
function buckets(tasks, now = new Date()) {
  const pending = tasks.filter((t) => !t.submittedAt);
  const doneToday = tasks.filter((t) => {
    const at = t.submittedAt && new Date(t.submittedAt);
    return at && !isNaN(at) && sameLocalDay(at, now);
  });
  const overdue = [], today = [], week = [];
  for (const t of pending) {
    const due = t.dueAt ? new Date(t.dueAt) : null;
    if (!due || isNaN(due)) week.push(t);
    else if (due < now) overdue.push(t);
    else if (sameLocalDay(due, now)) today.push(t);
    else week.push(t);
  }
  return { overdue, today, week, doneToday };
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
      : due.toLocaleDateString([], { weekday: 'short' });
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


/// What the slime says. Calm on purpose: no alarms, no shame. Overdue work is
/// "still counts", never a red wall.
function voice({ overdue, today, doneToday }) {
  const o = overdue.length, t = today.length, d = doneToday.length;
  const count = (n) => ['Zero', 'One', 'Two', 'Three', 'Four', 'Five'][n] ?? String(n);
  if (o) {
    return {
      face: 'faceDeadpan', worried: true,
      headline: o === 1 ? 'One slipped past due' : `${count(o)} slipped past due`,
      subline: 'Pick one to start. Ten minutes counts.',
    };
  }
  if (!t) {
    return d
      ? { face: 'faceDelight', headline: 'All done for today', subline: 'Rest counts too.' }
      : { face: 'faceDelight', headline: 'Nothing due today', subline: 'Enjoy the space.' };
  }
  return {
    face: 'faceIdle',
    headline: d ? 'Nice pace today' : 'Ready when you are',
    subline: d ? `${d} down, ${t} to go. No rush.` : `${t === 1 ? 'One thing' : count(t) + ' things'} today. Start small.`,
  };
}

/// The week's numbers for the rail: Monday to Sunday around `now`, how many
/// tasks fall in it and how many are handed in, split by course, and how many
/// days in a row something was handed in (today, or ending yesterday).
function weekStats(tasks, now = new Date()) {
  const today = startOfDay(now);
  const start = new Date(today.getTime() - ((today.getDay() + 6) % 7) * DAY_MS);
  const end = new Date(start.getTime() + 7 * DAY_MS);
  const inWeek = tasks.filter((t) => { const d = t.dueAt ? new Date(t.dueAt) : null; return d && !isNaN(d) && d >= start && d < end; });
  const byCourse = new Map();
  for (const t of inWeek) {
    const k = String(t.courseId);
    if (!byCourse.has(k)) byCourse.set(k, { courseId: k, name: t.courseName ?? '', colorHex: t.colorHex ?? null, total: 0, done: 0 });
    const c = byCourse.get(k); c.total++; if (t.submittedAt) c.done++;
  }
  const days = new Set(tasks.filter((t) => t.submittedAt).map((t) => startOfDay(new Date(t.submittedAt)).getTime()));
  let streak = 0;
  let cursor = days.has(today.getTime()) ? today.getTime() : today.getTime() - DAY_MS;
  while (days.has(cursor)) { streak++; cursor -= DAY_MS; }
  return {
    start, end, total: inWeek.length, done: inWeek.filter((t) => t.submittedAt).length,
    byCourse: [...byCourse.values()].sort((a, b) => b.total - a.total), streak,
  };
}

if (typeof module !== 'undefined') {
  module.exports = { DAY_MS, startOfDay, sameLocalDay, buckets, dueLabel, submittedLabel, voice, weekStats };
}
