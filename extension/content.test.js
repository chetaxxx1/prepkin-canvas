// Run with: node --test extension/content.test.js
// Also worth running under a different clock: TZ=Asia/Kolkata node --test extension/content.test.js
const test = require('node:test');
const assert = require('node:assert');
const { sameLocalDay, buckets, dueLabel, voice, gpa, targetsFor, safeURL, escapeHTML, sparkline, LETTERS }
  = require('./content.js');

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

test('the slime never scolds', () => {
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

test('weekStats counts the Monday-to-Sunday week by course and the streak of handed-in days', () => {
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
  assert.equal(w.streak, 2, 'today and yesterday');
  assert.equal(weekStats(tasks.map((t) => ({ ...t, submittedAt: undefined })), now).streak, 0);
  assert.equal(weekStats([{ id: 9, courseId: 1, submittedAt: day(-1) }], now).streak, 1, 'a streak ending yesterday still counts');
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
