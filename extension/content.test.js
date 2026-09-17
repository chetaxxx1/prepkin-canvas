// Run with: node --test extension/content.test.js
// Also worth running under a different clock: TZ=Asia/Kolkata node --test extension/content.test.js
const test = require('node:test');
const assert = require('node:assert');
const { sameLocalDay, buckets, dueLabel, voice, gpa, targetsFor, safeURL, escapeHTML, sparkline, LETTERS,
        dayKey, dayFromKey, planDay, isMoved, missingCost } = require('./content.js');

const local = (y, m, d, hh = 0, mm = 0) => new Date(y, m - 1, d, hh, mm);
const task = (over = {}) => ({ id: 't', title: 'x', courseName: 'c', dueAt: null, submittedAt: null, ...over });

// MARK: - Days

test('a task due at 23:59 tonight is today, one due 00:01 tomorrow is not', () => {
  const now = local(2026, 9, 5, 14, 0);
  const b = buckets([
    task({ id: 'a', dueAt: local(2026, 9, 5, 23, 59).toISOString() }),
    task({ id: 'b', dueAt: local(2026, 9, 6, 0, 1).toISOString() }),
  ], now);
  assert.deepEqual(b.today.map((t) => t.id), ['a']);
  assert.deepEqual(b.week.map((t) => t.id), ['b']);
});

test('overdue is by the clock, not the calendar', () => {
  const now = local(2026, 9, 5, 14, 0);
  const b = buckets([task({ id: 'a', dueAt: local(2026, 9, 5, 9, 0).toISOString() })], now);
  assert.deepEqual(b.overdue.map((t) => t.id), ['a']);
  assert.equal(dueLabel(b.overdue[0], now).startsWith('Was due'), true);
  assert.match(dueLabel(b.overdue[0], now), /today/);
});

test('undated and unparseable work sits in the week, never overdue', () => {
  const b = buckets([task({ id: 'a' }), task({ id: 'b', dueAt: 'not-a-date' })], local(2026, 9, 5, 14));
  assert.deepEqual(b.week.map((t) => t.id).sort(), ['a', 'b']);
  assert.equal(dueLabel(b.week[1]), 'No due date');
});

test('"yesterday" is a calendar day, even across the spring clock change', () => {
  // US spring forward is the second Sunday of March: 2027-03-14. The day is
  // 23 hours long, so "two days ago by the calendar" can be under 48 hours of
  // elapsed time. The label must still say the weekday, not "yesterday".
  const due = local(2027, 3, 13, 23, 30);
  const now = local(2027, 3, 15, 0, 30);
  const label = dueLabel(task({ dueAt: due.toISOString() }), now);
  assert.doesNotMatch(label, /yesterday/);
  assert.match(label, /Sat/);
  assert.match(dueLabel(task({ dueAt: local(2027, 3, 14, 9).toISOString() }), now), /yesterday/);
});

test('done today means submitted on this local day', () => {
  const now = local(2026, 9, 5, 14);
  const b = buckets([
    task({ id: 'a', submittedAt: local(2026, 9, 5, 0, 30).toISOString() }),
    task({ id: 'b', submittedAt: local(2026, 9, 4, 23, 30).toISOString() }),
  ], now);
  assert.deepEqual(b.doneToday.map((t) => t.id), ['a']);
  assert.equal(sameLocalDay(local(2026, 9, 5, 0, 0), local(2026, 9, 5, 23, 59)), true);
});

// MARK: - Voice

test('the buddy never scolds', () => {
  for (const shape of [{ overdue: [1, 2, 3], today: [], doneToday: [] }, { overdue: [], today: [1], doneToday: [] }, { overdue: [], today: [], doneToday: [] }]) {
    const v = voice(shape);
    assert.ok(v.headline && v.subline);
    assert.doesNotMatch(`${v.headline} ${v.subline}`, /late!|fail|shame|behind!/i);
  }
});

// MARK: - Grades

test('gpa ignores courses with no grade and never invents one', () => {
  assert.equal(gpa([{ score: null }, { score: undefined }]), null);
  assert.equal(gpa([{ score: 93 }, { score: null }]).unweighted, '4.00');
  assert.equal(gpa([{ score: 0 }]).unweighted, '0.00', 'a zero is a grade');
});

test('four what-if targets from anywhere in the table', () => {
  for (const score of [100, 95, 88, 75, 60, 0]) {
    const t = targetsFor(score);
    assert.equal(t.length, 4, `score ${score} offered ${t.length}`);
  }
  assert.deepEqual(targetsFor(60).map(([l]) => l), ['B', 'B−', 'C+', 'C']);
  assert.deepEqual(targetsFor(100).map(([l]) => l), ['A', 'A−', 'B+', 'B']);
  assert.equal(LETTERS.length, 7);
});

test('a sparkline needs two points and survives a flat line', () => {
  assert.equal(sparkline([{ percent: 80 }], '#000'), '');
  assert.match(sparkline([{ percent: 80 }, { percent: 80 }, { percent: 80 }], '#000'), /<path/);
  assert.doesNotMatch(sparkline([{ percent: 80 }, { percent: 90 }], '#000'), /NaN/);
});

// MARK: - Safety

test('only https links ever become hrefs', () => {
  assert.equal(safeURL('https://canvas.school.edu/courses/1'), 'https://canvas.school.edu/courses/1');
  for (const bad of ['javascript:alert(1)', 'http://x', 'data:text/html,hi', '//x', null, 42]) {
    assert.equal(safeURL(bad), null, String(bad));
  }
});

test('Canvas text is text, never markup', () => {
  assert.equal(escapeHTML(`<img src=x onerror=alert('1')>&"`), '&lt;img src=x onerror=alert(&#39;1&#39;)&gt;&amp;&quot;');
  assert.equal(escapeHTML(null), '');
});

test('the GPA is unweighted until the student marks a class Honors or AP', () => {
  const { gpa } = require('./content.js');
  const courses = [{ id: 'a', score: 95 }, { id: 'b', score: 85 }, { id: 'c', score: 40 }, { id: 'd' }];
  assert.deepEqual(gpa(courses), { unweighted: '2.33', weighted: null }, 'the unscored course does not count');
  assert.equal(gpa(courses, { a: 'regular' }).weighted, null, 'Regular is no bump');
  const w = gpa(courses, { a: 'ap', b: 'honors', c: 'ap' });
  assert.equal(w.unweighted, '2.33');
  assert.equal(w.weighted, '2.83', 'AP +1, Honors +0.5, and a failing class gets nothing');
  assert.equal(gpa([{ id: 'x' }]), null);
});

test('weekStats counts the Monday-to-Sunday week by course and handed-in tasks', () => {
  const { weekStats, DAY_MS } = require('./day.js');
  const now = new Date(2026, 8, 9, 12); // a Wednesday
  const day = (n, h = 10) => new Date(2026, 8, 9 + n, h).toISOString();
  const tasks = [
    { id: 1, courseId: 1, courseName: 'Physics', colorHex: '#ff6f61', dueAt: day(0), submittedAt: day(-1) },
    { id: 2, courseId: 1, courseName: 'Physics', dueAt: day(2) },
    { id: 3, courseId: 2, courseName: 'English', dueAt: day(4), submittedAt: day(0, 8) },
    { id: 4, courseId: 2, courseName: 'English', dueAt: day(9) },      // next week
    { id: 5, courseId: 3, courseName: 'Art', dueAt: day(-3) },         // last Sunday
    { id: 6, courseId: 3, courseName: 'Art' },                         // undated
  ];
  const w = weekStats(tasks, now);
  assert.equal(w.start.getDay(), 1, 'starts Monday');
  assert.equal(Math.round((w.end - w.start) / DAY_MS), 7);
  assert.deepEqual([w.total, w.done], [3, 2]);
  assert.deepEqual(w.byCourse.map((c) => [c.name, c.total, c.done]), [['Physics', 2, 1], ['English', 1, 1]]);
});

test('composeData: nicknames rename courses everywhere, own tasks join the list, the payload itself is untouched', () => {
  const { composeData } = require('./content.js');
  const payload = { tasks: [{ id: 'a', courseId: 1, courseName: 'AP Physics C: Mechanics', title: 'PS7' }], courses: [{ id: 1, name: 'AP Physics C: Mechanics' }], graded: {}, weights: {} };
  const own = [{ id: 'own-1', title: 'Buy a calculator', dueAt: null, courseId: null, courseName: '' }];
  const d = composeData(payload, own, { 1: 'Physics' });
  assert.equal(d.courses[0].name, 'Physics');
  assert.equal(d.courses[0].fullName, 'AP Physics C: Mechanics');
  assert.equal(d.tasks[0].courseName, 'Physics');
  assert.deepEqual([d.tasks[1].own, d.tasks[1].courseId, d.tasks[1].courseName], [true, 'own', 'My tasks']);
  assert.equal(payload.courses[0].name, 'AP Physics C: Mechanics', 'never mutated');
  assert.equal(composeData(null).tasks.length, 0);
});

test('searchRank: every word must match, what starts with the query comes first, empty query lists the top items', () => {
  const { searchItems, searchRank } = require('./content.js');
  const d = { courses: [{ id: 1, name: 'Physics', fullName: 'AP Physics C' }], tasks: [{ id: 't', title: 'Problem Set 7', courseId: 1, courseName: 'Physics', url: 'https://school.edu/courses/1/assignments/7', dueAt: null }] };
  const items = searchItems(d);
  assert.ok(items.some((i) => i.url === '/courses/1/grades'), 'course tabs are reachable');
  assert.equal(searchRank(items, 'phys')[0].label, 'Physics');
  assert.equal(searchRank(items, 'set 7')[0].label, 'Problem Set 7');
  assert.equal(searchRank(items, 'physics grades')[0].url, '/courses/1/grades');
  assert.equal(searchRank(items, 'zzz').length, 0);
  assert.equal(searchRank(items, '').length, 8);
});

test('searchGroups: before typing, classes then Canvas pages; what is due is the rail\'s to say', () => {
  const { searchItems, searchGroups, _setData } = require('./content.js');
  _setData({
    courses: [{ id: 1, name: 'AP Physics C', courseCode: 'PHYS', url: 'https://x/courses/1', colorHex: '#123' }],
    tasks: [{ id: 't1', title: 'Problem Set 7', courseId: 1, courseName: 'AP Physics C', dueAt: '2026-09-20T05:00:00Z', url: 'https://x/courses/1/assignments/7', submittedAt: null }],
  });
  const groups = searchGroups(searchItems());
  assert.deepEqual(groups.map((g) => g[0]), ['Classes', 'Canvas']);
  assert.ok(!groups.flatMap((g) => g[1]).some((i) => i.kind === 'task'), 'no task before typing');
});



test('the buddy is the student\'s own kin, mint until the phone says otherwise', () => {
  const { ownSpecies, _setWallet } = require('./content.js');
  _setWallet({});
  assert.equal(ownSpecies(), 'mint');
  _setWallet({ league: { board: [{ species: 'sky' }, { you: true, species: 'coral' }] } });
  assert.equal(ownSpecies(), 'coral');
  _setWallet({ league: { board: [{ you: true, species: 'dragon' }] } });
  assert.equal(ownSpecies(), 'mint');
});

// MARK: - Missing, and the day you will actually do it

test('old missing work is its own list, so the buddy still counts only this week', () => {
  const now = local(2026, 9, 6, 12);
  const recent = task({ id: 'a', dueAt: local(2026, 9, 4, 9).toISOString(), missing: true });
  const ancient = task({ id: 'b', dueAt: local(2026, 8, 10, 9).toISOString(), missing: true });
  const b = buckets([recent, ancient], now);
  assert.deepEqual(b.overdue.map((t) => t.id), ['a'], 'this week still slipped');
  assert.deepEqual(b.missed.map((t) => t.id), ['b']);
  assert.equal(voice(b).headline, 'Late work still counts', 'a term of old zeros is not a scolding');
});

test('work overdue a long time but never flagged stays overdue, not missing', () => {
  const now = local(2026, 9, 6, 12);
  const b = buckets([task({ id: 'a', dueAt: local(2026, 8, 10, 9).toISOString() })], now);
  assert.equal(b.missed.length, 0);
  assert.equal(b.overdue.length, 1);
});

test('a date more than a week old says its date, not a weekday that could be any', () => {
  const now = local(2026, 9, 6, 12);
  assert.match(dueLabel(task({ dueAt: local(2026, 9, 4, 9).toISOString() }), now), /Was due Fri/);
  assert.match(dueLabel(task({ dueAt: local(2026, 8, 10, 9).toISOString() }), now), /Was due Aug 10/);
});

test('a task sits on the day you planned it, and otherwise the day it is due', () => {
  const t = task({ id: 'a', dueAt: local(2026, 9, 11, 23, 59).toISOString() });
  assert.ok(sameLocalDay(planDay(t, {}), local(2026, 9, 11)), 'no plan, so the due date');
  assert.ok(sameLocalDay(planDay(t, { a: '2026-09-07' }), local(2026, 9, 7)), 'planned wins');
  assert.equal(isMoved(t, { a: '2026-09-07' }), true);
  assert.equal(isMoved(t, { a: '2026-09-11' }), false, 'planning it for the due date is not a move');
  assert.equal(isMoved(t, {}), false);
});

test('a plan on undated work places it, and rubbish in storage never does', () => {
  const t = task({ id: 'a' });
  assert.equal(planDay(t, {}), null);
  assert.ok(sameLocalDay(planDay(t, { a: '2026-09-07' }), local(2026, 9, 7)));
  for (const bad of ['', 'tomorrow', '2026-9-7', '2026-13-40', null]) {
    assert.equal(dayFromKey(bad), null, String(bad));
  }
});

test('the day key is the local date, not UTC', () => {
  assert.equal(dayKey(local(2026, 1, 5, 23, 30)), '2026-01-05');
});

// MARK: - What a plan does to today, and what the zeros cost

test('a plan moves work in and out of today, and never out of overdue', () => {
  const now = local(2026, 9, 6, 12);
  const dueFriday = task({ id: 'a', dueAt: local(2026, 9, 11, 23, 59).toISOString() });
  const dueToday = task({ id: 'b', dueAt: local(2026, 9, 6, 23, 59).toISOString() });
  const late = task({ id: 'c', dueAt: local(2026, 9, 4, 9).toISOString() });
  const plans = { a: '2026-09-06', b: '2026-09-09', c: '2026-09-06' };
  const b = buckets([dueFriday, dueToday, late], now, (t) => (plans[t.id] ? new Date(...plans[t.id].split('-').map((n, i) => (i === 1 ? Number(n) - 1 : Number(n)))) : null));
  assert.deepEqual(b.today.map((t) => t.id), ['a'], 'Friday work planned for today joins today');
  assert.deepEqual(b.week.map((t) => t.id), ['b'], 'today work planned for Wednesday leaves it');
  assert.deepEqual(b.overdue.map((t) => t.id), ['c'], 'a plan does not un-slip work');
});

test('with no plans at all, the buckets are exactly what they were', () => {
  const now = local(2026, 9, 6, 12);
  const list = [task({ id: 'a', dueAt: local(2026, 9, 11).toISOString() }),
                task({ id: 'b', dueAt: local(2026, 9, 6, 23).toISOString() }),
                task({ id: 'c' })];
  const b = buckets(list, now);
  assert.deepEqual([b.today.map((t) => t.id), b.week.map((t) => t.id)], [['b'], ['a', 'c']]);
});

const missed = (over) => task({ courseId: 1, courseName: 'AP Physics C', missing: true, ...over });

test('the zeros are counted in points, and in a grade only when the sum checks out', () => {
  // We hold every graded item and the course does not weight: 25 out of 100,
  // the zero included, is exactly the 25% Canvas reports.
  const courses = [{ id: 1, name: 'AP Physics C', score: 25 }];
  const graded = { 1: [{ id: 'g1', score: 25, outOf: 50 }, { id: 'x', score: 0, outOf: 50 }] };
  const [row] = missingCost([missed({ id: 'x', pointsPossible: 50 })], courses, graded);
  assert.deepEqual([row.name, row.count, row.points], ['AP Physics C', 1, 50]);
  assert.deepEqual([row.from, row.to], [25, 75], 'the zero is already in the bottom half');
});

test('work never marked at all lands in both halves', () => {
  const courses = [{ id: 1, name: 'AP Physics C', score: 50 }];
  const graded = { 1: [{ id: 'g1', score: 25, outOf: 50 }] };
  const [row] = missingCost([missed({ id: 'never', pointsPossible: 50 })], courses, graded);
  assert.deepEqual([row.from, row.to], [50, 75]);
});

test('a grade we cannot check is not printed', () => {
  const courses = [{ id: 1, name: 'AP Physics C', score: 88.5 }];
  // A weighted course, or a truncated list: our own average is nowhere near it.
  const graded = { 1: [{ id: 'g1', score: 25, outOf: 50 }] };
  const [row] = missingCost([missed({ id: 'x', pointsPossible: 40 })], courses, graded);
  assert.deepEqual([row.points, row.from, row.to], [40, null, null]);
});

test('classes are separate lines, biggest first', () => {
  const courses = [{ id: 1, name: 'AP Physics C', score: null }, { id: 2, name: 'English 11', score: null }];
  const rows = missingCost([
    missed({ id: 'a', pointsPossible: 10 }),
    missed({ id: 'b', courseId: 2, courseName: 'English 11', pointsPossible: 60 }),
  ], courses, {});
  assert.deepEqual(rows.map((r) => [r.name, r.points]), [['English 11', 60], ['AP Physics C', 10]]);
});

test('dayShort: the rail row gets one word for the day', () => {
  const { dayShort } = require('./content.js');
  const now = new Date(2026, 8, 11, 14); // a Friday
  const at = (d, h = 9) => ({ dueAt: new Date(2026, 8, d, h).toISOString() });
  assert.equal(dayShort(at(11, 23), now), 'Today');
  assert.equal(dayShort(at(12), now), 'Tomorrow');
  assert.equal(dayShort(at(14), now), 'Mon');
  assert.equal(dayShort(at(9), now), 'Wed', 'a late one names the day it was due');
  assert.equal(dayShort(at(1), now), 'Sep 1', 'past a week, the date');
  assert.equal(dayShort({ dueAt: 'nope' }, now), '');
});

test('tankId: the band paints the tank the phone named, and Lagoon until it names one', () => {
  const { tankId, TANKS, _setWallet } = require('./content.js');
  assert.deepEqual(TANKS, ['lagoon', 'reef', 'kelp', 'dusk', 'deep']);
  _setWallet({ coins: null, owned: ['classic'], wearing: 'classic' });
  assert.equal(tankId(), 'lagoon');
  _setWallet({ coins: 0, owned: ['classic'], wearing: 'classic', kin: { species: 'sky', level: 2, skin: '', scene: 'deep' } });
  assert.equal(tankId(), 'deep');
  _setWallet({ coins: 0, owned: ['classic'], wearing: 'classic', kin: { species: 'sky', level: 2, skin: '', scene: '../x' } });
  assert.equal(tankId(), 'lagoon', 'an unknown name is the default, never a path');
});


test('voice: a short line for the rail, one line wide', () => {
  const { voice } = require('./day.js');
  assert.equal(voice({ overdue: [1], today: [], doneToday: [] }).short, 'Pick one to start.');
  assert.equal(voice({ overdue: [], today: [1, 2], doneToday: [1] }).short, '1 done, 2 to go.');
  assert.equal(voice({ overdue: [], today: [1], doneToday: [] }).short, 'One thing today.');
  assert.equal(voice({ overdue: [], today: [], doneToday: [] }).short, 'Enjoy the space.');
});

test('a tick is finished: it leaves today, counts as done today and in the week, and never becomes a submission', () => {
  const { buckets, weekStats, withDone, isDone, pruneDone } = require('./day.js');
  const now = new Date('2026-09-14T15:00:00');
  const due = new Date('2026-09-14T23:59:00').toISOString();
  const tasks = [
    { id: 'a', title: 'Read chapter 4', dueAt: due, submittedAt: null, courseId: 1 },
    { id: 'b', title: 'Problem set', dueAt: due, submittedAt: null, courseId: 1 },
    { id: 'c', title: 'Lab', dueAt: due, submittedAt: '2026-09-14T09:00:00', courseId: 1 },
  ];
  const laid = withDone(tasks, { a: '2026-09-14T14:00:00', c: '2026-09-14T14:30:00', zzz: '2026-09-14T14:00:00' });
  assert.equal(laid[0].doneAt, '2026-09-14T14:00:00');
  assert.equal(laid[0].submittedAt, null, 'a tick never becomes a submission');
  assert.equal(laid[2].doneAt, undefined, 'a task Canvas verified takes no tick');
  assert.ok(isDone(laid[0]) && !isDone(laid[1]) && isDone(laid[2]));
  const b = buckets(laid, now);
  assert.deepEqual(b.today.map((t) => t.id), ['b'], 'the ticked one left today');
  assert.deepEqual(b.doneToday.map((t) => t.id).sort(), ['a', 'c'], 'and counts as done today, beside the hand-in');
  const w = weekStats(laid, now);
  assert.equal(w.done, 2);
  assert.equal(w.byCourse[0].done, 2);
  // After a sync: the submitted one and the one Canvas no longer lists are pruned.
  const pruned = pruneDone({ a: 'x', c: 'x', zzz: 'x' }, tasks);
  assert.deepEqual(Object.keys(pruned), ['a']);
  const same = { a: 'x' };
  assert.equal(pruneDone(same, tasks), same, 'unchanged means the same object, so nothing is written');
});

test('dayGroups: slipped, today and six days, later folded, undated, old zeros apart; a plan moves a thing; finished work stays today only', () => {
  const { dayGroups, startOfDay, DAY_MS } = require('./day.js');
  const now = new Date('2026-09-14T15:00:00');
  const at = (d, h = 23) => new Date(now.getFullYear(), now.getMonth(), now.getDate() + d, h, 59).toISOString();
  const tasks = [
    { id: 'y', title: 'Yesterday', dueAt: at(-1), submittedAt: null },
    { id: 'old', title: 'Old zero', dueAt: at(-20), submittedAt: null, missing: true },
    { id: 't', title: 'Today', dueAt: at(0), submittedAt: null },
    { id: 'f', title: 'Friday', dueAt: at(4), submittedAt: null },
    { id: 'n', title: 'Sixteen days out', dueAt: at(16), submittedAt: null },
    { id: 'w', title: 'Nine days out', dueAt: at(9), submittedAt: null },
    { id: 'u', title: 'No date', dueAt: null, submittedAt: null },
    { id: 'd', title: 'Ticked today', dueAt: at(2), submittedAt: null, doneAt: now.toISOString() },
    { id: 'e', title: 'Handed in last week', dueAt: at(-3), submittedAt: at(-3, 10) },
  ];
  const dayOf = (t, plans = {}) => plans[t.id] ? new Date(plans[t.id]) : (t.dueAt ? startOfDay(new Date(t.dueAt)) : null);
  const g = dayGroups(tasks, now, (t) => dayOf(t));
  assert.deepEqual(g.past.map((t) => t.id), ['y'], 'a day old is past due');
  assert.deepEqual(g.missed.map((t) => t.id), ['old'], 'an old zero is its own folded list');
  assert.equal(g.days.length, 14, 'two weeks by day');
  assert.deepEqual(g.days[9].items.map((t) => t.id), ['w'], 'nine days out is a day of its own');
  assert.deepEqual(g.days[0].items.map((t) => t.id), ['t', 'd'], 'today: pending first, then what was finished today');
  assert.deepEqual(g.days[4].items.map((t) => t.id), ['f']);
  assert.deepEqual(g.later.map((t) => t.id), ['n'], 'sixteen days out is later; nine is a day');
  assert.deepEqual(g.undated.map((t) => t.id), ['u']);
  assert.ok(!g.days.some((d) => d.items.some((t) => t.id === 'e')), 'handed in last week is nowhere on the list');
  // A plan moves Friday's thing to today.
  const planned = dayGroups(tasks, now, (t) => dayOf(t, { f: at(0) }));
  assert.deepEqual(planned.days[0].items.map((t) => t.id), ['t', 'f', 'd']);
  assert.deepEqual(planned.days[4].items, []);
});
