// Run with: node --test extension/canvas.test.js
const test = require('node:test');
const assert = require('node:assert');
const { mapCourses, mapAssignments, mapTodo, merge, mapGraded, mapWeights, requiredScore,
        DAYS_AHEAD, DAYS_OVERDUE } = require('./canvas.js');

const HOST = 'canvas.dartmouth.edu';
const NOW = Date.parse('2026-09-01T12:00:00Z');
const DAY = 86_400_000;
const at = (days) => new Date(NOW + days * DAY).toISOString();
const COURSE = { id: '1', name: 'AP Physics', colorHex: '#FF6F61' };

const map = (raw, now = NOW) => mapAssignments(raw, { host: HOST, course: COURSE, now });
const assignment = (over = {}) => ({ id: 77, name: 'Lab writeup', due_at: at(2), points_possible: 50, ...over });

// MARK: - Courses and grades

test('a course carries its current grade and dashboard colour', () => {
  const [c] = mapCourses(
    [{ id: 1, name: 'AP Physics', course_code: 'PHYS-11',
       enrollments: [{ type: 'student', computed_current_score: 88.5, computed_current_grade: 'B+' }] }],
    { course_1: '#FF6F61' });
  assert.equal(c.name, 'AP Physics');
  assert.equal(c.score, 88.5);
  assert.equal(c.grade, 'B+');
  assert.equal(c.colorHex, '#FF6F61');
});

test('no grade yet is null, never zero', () => {
  // A course you have not been graded in is not a course you are failing.
  const [c] = mapCourses([{ id: 1, name: 'Seminar', enrollments: [{ type: 'student', computed_current_score: null }] }]);
  assert.equal(c.score, null);
  assert.notEqual(c.score, 0);
});

test('a course you teach does not borrow the student score row', () => {
  const [c] = mapCourses([{ id: 1, name: 'Lab', enrollments: [{ type: 'ta', computed_current_score: 100 }] }]);
  assert.equal(c.score, 100, 'falls back to the only enrollment there is');
});

test('a course with no colour set still maps', () => {
  const [c] = mapCourses([{ id: 9, name: 'History', enrollments: [] }], {});
  assert.equal(c.colorHex, null);
});

// MARK: - Which assignments show

test('work due soon shows', () => {
  assert.equal(map([assignment({ due_at: at(2) })]).length, 1);
});

test('work due after the horizon does not bury this week', () => {
  assert.equal(map([assignment({ due_at: at(DAYS_AHEAD + 1) })]).length, 0);
});

test('recently overdue work still shows', () => {
  assert.equal(map([assignment({ due_at: at(-2) })]).length, 1);
});

test('long-dead overdue work drops off', () => {
  assert.equal(map([assignment({ due_at: at(-(DAYS_OVERDUE + 1)) })]).length, 0);
});

test('undated work is still owed', () => {
  // bucket=upcoming would silently drop this, which is why we filter ourselves.
  assert.equal(map([assignment({ due_at: null })]).length, 1);
});

// MARK: - Submission state

test('an unsubmitted assignment reports no submission time', () => {
  const [t] = map([assignment({ submission: { workflow_state: 'unsubmitted' } })]);
  assert.equal(t.submittedAt, null, 'Canvas sends a row even when nothing was handed in');
});

test('handing something in is recorded, not just hidden', () => {
  const [t] = map([assignment({ submission: { workflow_state: 'submitted', submitted_at: at(-0.5) } })]);
  assert.equal(t.submittedAt, at(-0.5));
});

test('graded work counts as submitted and carries the score', () => {
  const [t] = map([assignment({
    points_possible: 50,
    submission: { workflow_state: 'graded', submitted_at: at(-1), score: 47 },
  })]);
  assert.equal(t.submittedAt, at(-1));
  assert.equal(t.score, 47);
  assert.equal(t.pointsPossible, 50);
});

test('a zero is a real score and must not read as ungraded', () => {
  const [t] = map([assignment({ submission: { workflow_state: 'graded', graded_at: at(-1), score: 0 } })]);
  assert.equal(t.score, 0);
});

test('work submitted a while ago stops taking up space', () => {
  assert.equal(map([assignment({ submission: { workflow_state: 'submitted', submitted_at: at(-10) } })]).length, 0);
});

test('a submitted assignment shows even when its due date has passed', () => {
  const [t] = map([assignment({ due_at: at(-30), submission: { workflow_state: 'submitted', submitted_at: at(-1) } })]);
  assert.ok(t, 'you should get credit for the late one you just handed in');
});

// MARK: - Identity

test('two schools do not collide on the same assignment id', () => {
  const a = mapAssignments([assignment()], { host: 'a.edu', course: COURSE, now: NOW })[0];
  const b = mapAssignments([assignment()], { host: 'b.edu', course: COURSE, now: NOW })[0];
  assert.notEqual(a.id, b.id);
});

test('a quiz and an assignment sharing an id do not collide', () => {
  const a = map([assignment({ id: 5 })])[0];
  const q = mapTodo([{ type: 'submitting', context_name: 'A', quiz: { id: 5, title: 'Pop quiz' } }], HOST)[0];
  assert.notEqual(a.id, q.id);
});

// MARK: - The to-do sweep

test('marking someone else\'s work is not your homework', () => {
  const grading = { type: 'grading', needs_grading_count: 3, context_name: 'AP Physics',
                    assignment: { id: 88, name: 'Grade the lab writeups' } };
  assert.deepEqual(mapTodo([grading], HOST), []);
});

test('quizzes come through under their own key', () => {
  const [t] = mapTodo([{ type: 'submitting', context_name: 'APUSH', quiz: { id: 12, title: 'Unit 3 quiz' } }], HOST);
  assert.equal(t.title, 'Unit 3 quiz', 'quizzes use title where assignments use name');
});

test('the sweep obeys the same date window as the per-course pass', () => {
  const monthsOut = mapTodo([{ type: 'submitting', context_name: 'APUSH',
    quiz: { id: 13, title: 'Final exam', due_at: at(DAYS_AHEAD + 30) } }], HOST, NOW);
  assert.deepEqual(monthsOut, [], 'a quiz months out must not bury this week');
});

test('an undated sweep item is still owed', () => {
  const [t] = mapTodo([{ type: 'submitting', context_name: 'APUSH',
    assignment: { id: 14, name: 'Reading response' } }], HOST, NOW);
  assert.equal(t.title, 'Reading response');
});

// MARK: - Merging the two passes

test('the detailed pass wins, and the sweep only adds what it alone found', () => {
  const detailed = map([assignment({ id: 77, submission: { workflow_state: 'graded', submitted_at: at(-1), score: 47 } })]);
  const sweep = mapTodo([
    { type: 'submitting', context_name: 'AP Physics', assignment: { id: 77, name: 'Lab writeup' } },
    { type: 'submitting', context_name: 'Art', assignment: { id: 99, name: 'Sketchbook', due_at: at(1) } },
  ], HOST);

  const merged = merge(detailed, sweep);
  assert.equal(merged.length, 2, 'the duplicate is dropped, not shown twice');
  assert.equal(merged.find((t) => t.id.endsWith('a77')).score, 47, 'the richer row survives');
  assert.ok(merged.find((t) => t.id.endsWith('a99')), 'and the one only the sweep saw is kept');
});

test('the list comes back in due order, undated last', () => {
  const items = merge(map([
    assignment({ id: 1, name: 'Later', due_at: at(5) }),
    assignment({ id: 2, name: 'Sooner', due_at: at(1) }),
    assignment({ id: 3, name: 'Whenever', due_at: null }),
  ]), []);
  assert.deepEqual(items.map((t) => t.title), ['Sooner', 'Later', 'Whenever']);
});

// MARK: - Bad input

test('junk from the network never throws', () => {
  for (const junk of [null, undefined, {}, 'nope', [null], [{}]]) {
    assert.deepEqual(mapCourses(junk), []);
    assert.deepEqual(map(junk), []);
    assert.deepEqual(mapTodo(junk, HOST), []);
  }
});

test('an unparseable due date is kept rather than silently dropped', () => {
  assert.equal(map([assignment({ due_at: 'sometime next week' })]).length, 1);
});

// MARK: - Grades over time

test('mapGraded keeps only scored work, oldest first', () => {
  const items = mapGraded([
    { id: 1, name: 'Late quiz', points_possible: 10, submission: { score: 8, graded_at: '2026-03-02T00:00:00Z' } },
    { id: 2, name: 'Early quiz', points_possible: 10, submission: { score: 9, graded_at: '2026-01-02T00:00:00Z' } },
    { id: 3, name: 'Not marked yet', points_possible: 10, submission: { score: null } },
    { id: 4, name: 'Ungraded practice', points_possible: 0, submission: { score: 0 } },
  ]);
  assert.deepEqual(items.map((g) => g.title), ['Early quiz', 'Late quiz']);
  assert.equal(items[0].percent, 90);
  assert.equal(items[1].score, 8);
});

test('mapGraded survives junk', () => {
  for (const junk of [null, undefined, 'nope', {}, [null, 3]]) {
    assert.deepEqual(mapGraded(junk), []);
  }
});

test('mapWeights ignores a course that does not weight its groups', () => {
  const groups = [{ id: 1, name: 'Final', group_weight: 30 }];
  assert.equal(mapWeights(groups, { weighted: false }), null);
  assert.deepEqual(mapWeights(groups), [{ id: '1', name: 'Final', weight: 30 }]);
  // Groups with no weight are not a weighting scheme.
  assert.equal(mapWeights([{ id: 2, name: 'Homework', group_weight: 0 }]), null);
});

test('requiredScore answers the what-if question', () => {
  // Sitting at 91.2 with a final worth 30%: holding an A- (90) is easy.
  assert.equal(requiredScore({ current: 91.2, target: 90, weight: 30 }), 87.2);
  // Reaching for more asks for more.
  assert.ok(requiredScore({ current: 91.2, target: 93, weight: 30 }) > 90);
  // A small remaining weight can put a target out of reach, and it says so
  // rather than pretending.
  assert.ok(requiredScore({ current: 70, target: 90, weight: 10 }) > 100);
});

test('requiredScore refuses nonsense rather than guessing', () => {
  assert.equal(requiredScore({ current: null, target: 90, weight: 30 }), null);
  assert.equal(requiredScore({ current: 80, target: 90, weight: 0 }), null);
  assert.equal(requiredScore({ current: 80, target: 90, weight: 140 }), null);
});
