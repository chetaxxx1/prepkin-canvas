// The term, in numbers.
//
// The one thing in the BetterCampus corpus that made anyone happy was a term
// recap ("weirdly motivating seeing everything broken down like this"). This
// is that shape, on Prepkin's rules: reflective, once, at the end of a term,
// from what the laptop already holds. Never a daily counter, never a streak,
// and the picture a student can save carries no grade.

const RECAP_DAY = 86_400_000;

/// Whether a term is ending or just ended, so the recap has a moment.
/// A course's term end within a week ahead or three weeks behind says so;
/// with no dates at all, a list whose last due date is two weeks gone and
/// has real work in it is a term that ended quietly.
function recapDue(courses, tasks, now = new Date()) {
  const t = now.getTime();
  const ends = (courses ?? []).map((c) => Date.parse(c.termEndsAt ?? '')).filter(Number.isFinite);
  if (ends.length) return ends.some((e) => e - t < 7 * RECAP_DAY && t - e < 21 * RECAP_DAY);
  const due = (tasks ?? []).map((x) => Date.parse(x.dueAt ?? '')).filter(Number.isFinite);
  if (due.length < 10) return false;
  return t - Math.max(...due) > 14 * RECAP_DAY;
}

/// The numbers. `tasks` is the whole list the laptop holds for the term.
function termRecap(tasks, now = new Date()) {
  const dated = (tasks ?? []).filter((x) => x.dueAt && Number.isFinite(Date.parse(x.dueAt)) && !x.own);
  const done = dated.filter((x) => x.submittedAt && Number.isFinite(Date.parse(x.submittedAt)));
  const onTime = done.filter((x) => Date.parse(x.submittedAt) <= Date.parse(x.dueAt) + 60_000).length;

  const byCourse = new Map();
  for (const x of dated) {
    const k = String(x.courseId);
    if (!byCourse.has(k)) byCourse.set(k, { courseId: k, name: x.courseName ?? '', colorHex: x.colorHex ?? null, done: 0, total: 0 });
    const c = byCourse.get(k); c.total++; if (x.submittedAt) c.done++;
  }

  // The busiest week, by things handed in, Monday to Sunday.
  const weeks = new Map();
  for (const x of done) {
    const d = new Date(x.submittedAt); d.setHours(0, 0, 0, 0);
    const start = new Date(d.getTime() - ((d.getDay() + 6) % 7) * RECAP_DAY);
    const k = start.getTime();
    weeks.set(k, (weeks.get(k) ?? 0) + 1);
  }
  let busiestWeek = null;
  for (const [k, count] of weeks) if (!busiestWeek || count > busiestWeek.count) busiestWeek = { start: new Date(k), end: new Date(k + 7 * RECAP_DAY - 1), count };

  // The hour of day you hand things in most. Late at night is a real answer.
  const hours = new Array(24).fill(0);
  for (const x of done) hours[new Date(x.submittedAt).getHours()]++;
  const top = hours.indexOf(Math.max(...hours));
  const hour = done.length ? { hour: top, count: hours[top] } : null;

  const dues = dated.map((x) => Date.parse(x.dueAt));
  return {
    handedIn: done.length,
    total: dated.length,
    onTime,
    onTimePct: done.length ? Math.round((onTime / done.length) * 100) : null,
    byCourse: [...byCourse.values()].sort((a, b) => b.done - a.done || b.total - a.total),
    busiestWeek,
    hour,
    firstDue: dues.length ? new Date(Math.min(...dues)) : null,
    lastDue: dues.length ? new Date(Math.max(...dues)) : null,
  };
}

/// "11pm", "8am", "noon".
function hourLabel(h) {
  if (h === 0) return 'midnight';
  if (h === 12) return 'noon';
  return h < 12 ? `${h}am` : `${h - 12}pm`;
}

if (typeof module !== 'undefined') module.exports = { recapDue, termRecap, hourLabel };
