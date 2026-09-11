const test = require('node:test');
const assert = require('node:assert');
const { recapDue, termRecap, hourLabel } = require('./recap.js');

const day = 86_400_000;
const at = (d, h = 23) => { const x = new Date(2026, 10, d, h, 15); return x.toISOString(); };

test('the recap waits for a term to end, and never nags mid-term', () => {
  const now = new Date(2026, 10, 15);
  assert.equal(recapDue([{ termEndsAt: new Date(2026, 11, 18).toISOString() }], [], now), false, 'a month out: nothing');
  assert.equal(recapDue([{ termEndsAt: new Date(2026, 10, 20).toISOString() }], [], now), true, 'five days out: the moment');
  assert.equal(recapDue([{ termEndsAt: new Date(2026, 10, 1).toISOString() }], [], now), true, 'two weeks gone: still there');
  assert.equal(recapDue([{ termEndsAt: new Date(2026, 9, 1).toISOString() }], [], now), false, 'six weeks gone: over');
  const old = Array.from({ length: 12 }, (_, i) => ({ dueAt: new Date(now - (20 + i) * day).toISOString() }));
  assert.equal(recapDue([], old, now), true, 'no term dates, but every due date is weeks gone');
  assert.equal(recapDue([], old.slice(0, 4), now), false, 'four things is not a term');
});

test('the numbers: handed in, on time, by course, the busiest week, the hour', () => {
  const tasks = [
    { courseId: 1, courseName: 'Physics', colorHex: '#123456', dueAt: at(2), submittedAt: at(1, 23) },
    { courseId: 1, courseName: 'Physics', colorHex: '#123456', dueAt: at(4), submittedAt: at(5, 23) },
    { courseId: 1, courseName: 'Physics', colorHex: '#123456', dueAt: at(9), submittedAt: null },
    { courseId: 2, courseName: 'English', colorHex: '#654321', dueAt: at(3), submittedAt: at(3, 9) },
    { courseId: 2, courseName: 'English', colorHex: '#654321', dueAt: at(10), submittedAt: at(10, 23) },
    { courseId: 3, courseName: 'Own', dueAt: at(6), submittedAt: at(6), own: true },
    { courseId: 4, courseName: 'Undated', dueAt: null, submittedAt: null },
  ];
  const r = termRecap(tasks, new Date(2026, 10, 20));
  assert.equal(r.total, 5, 'own tasks and undated work are not the term');
  assert.equal(r.handedIn, 4);
  assert.equal(r.onTime, 3, 'one was a day late');
  assert.equal(r.onTimePct, 75);
  assert.deepEqual(r.byCourse.map((c) => [c.name, c.done, c.total]), [['Physics', 2, 3], ['English', 2, 2]]);
  assert.equal(r.hour.hour, 23, 'three of four went in at 11pm');
  assert.equal(r.busiestWeek.count, 2, 'the week of Nov 2 to 8 holds the 3rd and the 5th; Nov 1 is a Sunday in the week before');
});

test('the busiest week is Monday to Sunday', () => {
  // Nov 2026: the 1st is a Sunday, so it belongs to the week of Oct 26; the 2nd starts a new week.
  const tasks = [
    { courseId: 1, courseName: 'A', dueAt: at(1), submittedAt: at(1) },
    { courseId: 1, courseName: 'A', dueAt: at(2), submittedAt: at(2) },
    { courseId: 1, courseName: 'A', dueAt: at(8), submittedAt: at(8) },
  ];
  const r = termRecap(tasks);
  assert.equal(r.busiestWeek.count, 2);
  assert.equal(r.busiestWeek.start.getDay(), 1, 'starts on a Monday');
});

test('hours read like a person says them', () => {
  assert.equal(hourLabel(23), '11pm'); assert.equal(hourLabel(8), '8am'); assert.equal(hourLabel(0), 'midnight'); assert.equal(hourLabel(12), 'noon');
});
