// Run with: node --test extension/canvas.test.js
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { mapCourses, mapAssignments, mapTodo, merge, examinedIds, mapGraded, mapWeights, requiredScore,
        DAYS_AHEAD, DAYS_OVERDUE, DAYS_MISSING, DAYS_NEW, safeColor, nextLink } = require('./canvas.js');

const HOST = 'canvas.dartmouth.edu';
const NOW = Date.parse('2026-09-01T12:00:00Z');
const DAY = 86_400_000;
const at = (days) => new Date(NOW + days * DAY).toISOString();
const COURSE = { id: '1', name: 'AP Physics', colorHex: '#FF6F61' };

const map = (raw, now = NOW) => mapAssignments(raw, { host: HOST, course: COURSE, now });
const assignment = (over = {}) => ({ id: 77, name: 'Lab writeup', due_at: at(2), points_possible: 50, ...over });

// MARK: - Extension version

test('the pushed list carries the extension version', () => {
  const source = fs.readFileSync(path.join(__dirname, 'background.js'), 'utf8');
  const [definition] = source.match(/^const payloadVersion = .*;$/m) ?? [];
  assert.ok(definition, 'the manifest reader stays available as a one-line helper');
  const version = Function('chrome', `${definition}\nreturn payloadVersion();`)({
    runtime: { getManifest: () => ({ version: '0.6.0' }) },
  });
  assert.equal(version, '0.6.0');
  assert.match(source, /const payload = \{\s*version: payloadVersion\(\),/);
});

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

test('a course you only TA or teach is not your coursework', () => {
  // Found on the sandbox: the TA course's assignments were listed as homework.
  assert.deepEqual(mapCourses([{ id: 1, name: 'Lab', enrollments: [{ type: 'ta', computed_current_score: 100 }] }]), []);
  assert.deepEqual(mapCourses([{ id: 2, name: 'Lab', enrollments: [{ type: 'teacher' }] }]), []);
  const [both] = mapCourses([{ id: 3, name: 'Lab', enrollments: [{ type: 'ta' }, { type: 'student', computed_current_score: 90 }] }]);
  assert.equal(both.score, 90, 'a student who also TAs the same course keeps it');
});

test('a course with no colour set still maps', () => {
  const [c] = mapCourses([{ id: 9, name: 'History', enrollments: [] }], {});
  assert.equal(c.colorHex, null);
});

// MARK: - Courses from finished terms

const term = (over = {}) => ({ id: 1, name: 'AP Physics', workflow_state: 'available',
                               enrollments: [], ...over });

test('a course whose term has ended is not this term\'s work', () => {
  // "Thayer Welcome and Orientation 2020" — still an active enrolment, years dead.
  const raw = [term({ id: 2020, name: 'Orientation 2020', term: { end_at: '2020-12-31T00:00:00Z' } })];
  assert.deepEqual(mapCourses(raw, {}, { now: NOW }), []);
});

test('a term ending later this year is still current', () => {
  const raw = [term({ term: { end_at: at(90) } })];
  assert.equal(mapCourses(raw, {}, { now: NOW }).length, 1);
});

test('a course that is not available drops out', () => {
  for (const state of ['completed', 'unpublished', 'deleted']) {
    assert.deepEqual(mapCourses([term({ workflow_state: state })], {}, { now: NOW }), []);
  }
});

test('a missing term or state is not evidence against a course', () => {
  // Plenty of real courses have no term end date at all.
  assert.equal(mapCourses([term({ term: {} })], {}, { now: NOW }).length, 1);
  assert.equal(mapCourses([{ id: 3, name: 'Seminar', enrollments: [] }], {}, { now: NOW }).length, 1);
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

test('an undated, unmarked leftover does not count as homework', () => {
  const stale = assignment({ due_at: null, points_possible: null, created_at: at(-400) });
  assert.deepEqual(map([stale]), [], 'an old practice quiz nobody ever set is not a task');
  assert.deepEqual(map([{ ...stale, points_possible: 0 }]), [], 'zero points is no points');
});

test('an undated, unmarked assignment set this term is real work', () => {
  const fresh = assignment({ due_at: null, points_possible: null, created_at: at(-(DAYS_NEW - 1)) });
  assert.equal(map([fresh]).length, 1);
  assert.equal(map([{ ...fresh, created_at: at(-(DAYS_NEW + 1)) }]).length, 0);
});

test('marks alone keep undated work on the list', () => {
  // Something worth points is owed however long ago it was set up.
  assert.equal(map([assignment({ due_at: null, points_possible: 20, created_at: at(-400) })]).length, 1);
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

test('a zero entered for work never handed in is still owed, never paid', () => {
  // Canvas marks it `graded` with no submission time. `missing` is only set
  // once the due date passes, so it must not be what decides.
  for (const [due, missing] of [[at(-3), true], [at(1), false]]) {
    const [t] = map([assignment({ due_at: due, submission_types: ['online_text_entry'], submission: {
      workflow_state: 'graded', submitted_at: null, graded_at: at(-1), score: 0, missing } })]);
    assert.equal(t.submittedAt, null, 'not done');
    assert.equal(t.score, 0, 'but the zero shows');
  }
});

test('work graded on paper, with no online submission, counts as handed in', () => {
  const [t] = map([assignment({ due_at: at(-2), submission_types: ['on_paper'], submission: {
    workflow_state: 'graded', submitted_at: null, graded_at: at(-1), score: 18, missing: false } })]);
  assert.ok(t.submittedAt, 'the grade is the proof it was turned in');
});

test('with no submission types at all, a grade alone does not count as handed in', () => {
  const [t] = map([assignment({ due_at: at(-2), submission: {
    workflow_state: 'graded', submitted_at: null, graded_at: at(-1), score: 18 } })]);
  assert.equal(t.submittedAt, null, 'the safe side is not paying');
});

test('excused work is neither owed nor paid', () => {
  const [t] = [...map([assignment({ due_at: at(-2), submission: {
    workflow_state: 'graded', submitted_at: null, graded_at: at(-1), score: null, excused: true } })])];
  assert.equal(t, undefined, 'it leaves the list');
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

test('the sweep stays inside the courses that survived the term filter', () => {
  const raw = [
    { type: 'submitting', course_id: 1, context_name: 'AP Physics',
      quiz: { id: 20, title: 'Unit 3 quiz', due_at: at(1) } },
    { type: 'submitting', course_id: 2020, context_name: 'Orientation 2020',
      quiz: { id: 21, title: 'Welcome survey' } },
  ];
  const kept = mapTodo(raw, HOST, NOW, new Set(['1']));
  assert.deepEqual(kept.map((t) => t.title), ['Unit 3 quiz']);
  assert.equal(mapTodo(raw, HOST, NOW).length, 2, 'with no course list the sweep is unfiltered');
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

test('the sweep does not bring back what the course pass dropped', () => {
  // The course pass saw an old, undated, unmarked leftover and left it out.
  // The to-do sweep lists it too; it must stay out.
  const raw = [assignment({ id: 5, due_at: null, points_possible: null, created_at: at(-400) })];
  const examined = examinedIds(raw, HOST);
  const sweep = [{ id: 'c-canvas.dartmouth.edu-a5', title: 'Lab writeup', dueAt: null }];
  assert.deepEqual(merge(map(raw), sweep, examined), []);
  assert.equal(merge(map(raw), sweep).length, 1, 'without the examined set it would come back');
});

test('a quiz is not listed twice, once as an assignment and once as a quiz', () => {
  const raw = [assignment({ id: 9, name: 'Unit 4 check', quiz_id: 5001 })];
  const examined = examinedIds(raw, HOST);
  const sweep = [{ id: 'c-canvas.dartmouth.edu-q5001', title: 'Unit 4 check', dueAt: at(2) }];
  const out = merge(map(raw), sweep, examined);
  assert.deepEqual(out.map((t) => t.id), ['c-canvas.dartmouth.edu-a9']);
});

test('examinedIds survives junk', () => {
  assert.deepEqual([...examinedIds(null, HOST)], []);
  assert.deepEqual([...examinedIds([null, {}, { id: 1 }], HOST)], ['c-canvas.dartmouth.edu-a1']);
});

test('a course says whether it weights its groups, when Canvas says', () => {
  const [w] = mapCourses([{ id: 1, name: 'A', apply_assignment_group_weights: false }]);
  assert.equal(w.weighted, false);
  const [u] = mapCourses([{ id: 2, name: 'B' }]);
  assert.equal('weighted' in u, false, 'silence is not a claim either way');
});

test('the list comes back in due order, undated last', () => {
  const items = merge(map([
    assignment({ id: 1, name: 'Later', due_at: at(5) }),
    assignment({ id: 2, name: 'Sooner', due_at: at(1) }),
    assignment({ id: 3, name: 'Whenever', due_at: null }),
  ]), []);
  assert.deepEqual(items.map((t) => t.title), ['Sooner', 'Later', 'Whenever']);
});

// MARK: - Colours reach a CSS sink

test('a dashboard colour that is not a colour is dropped', () => {
  // content.js puts this straight into style="background:...", where escaping
  // the string is not enough: ; and ( are legal there.
  assert.equal(safeColor('#FF6F61'), '#FF6F61');
  assert.equal(safeColor('#abc'), '#abc');
  assert.equal(safeColor('red;background-image:url(https://evil/?x=)'), null);
  assert.equal(safeColor('url(javascript:alert(1))'), null);
  for (const junk of [null, undefined, 42, {}, '', 'red']) assert.equal(safeColor(junk), null);
});

test('a course carries a bad colour as no colour, not as markup', () => {
  const [c] = mapCourses([{ id: 1, name: 'Physics', enrollments: [] }],
    { course_1: '#fff;background-image:url(https://evil/)' });
  assert.equal(c.colorHex, null);
});

// MARK: - Paging cannot be steered off-origin

const ORIGIN = 'https://canvas.dartmouth.edu';
const link = (url) => `<${url}>; rel="next", <${ORIGIN}/x?page=1>; rel="first"`;

test('a next page on the same school is followed', () => {
  assert.equal(nextLink(link(`${ORIGIN}/api/v1/courses?page=2`), ORIGIN),
    `${ORIGIN}/api/v1/courses?page=2`);
});

test('a next page pointing somewhere else is refused', () => {
  // These fetches carry the student's Canvas cookies.
  assert.equal(nextLink(link('https://evil.example/steal'), ORIGIN), null);
  assert.equal(nextLink(link('http://canvas.dartmouth.edu/x'), ORIGIN), null, 'downgrade to http is off-origin');
  assert.equal(nextLink(link('https://canvas.dartmouth.edu.evil.example/x'), ORIGIN), null);
});

test('nextLink survives a missing or unparseable header', () => {
  assert.equal(nextLink(null, ORIGIN), null);
  assert.equal(nextLink('', ORIGIN), null);
  assert.equal(nextLink('<not a url>; rel="next"', ORIGIN), null);
  assert.equal(nextLink(`<${ORIGIN}/x>; rel="prev"`, ORIGIN), null, 'only rel=next counts');
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

// MARK: - Missing work

test('work the school marked missing outlives the overdue window', () => {
  const old = { due_at: at(-(DAYS_OVERDUE + 14)), submission_types: ['online_upload'] };
  const [kept] = map([assignment({ ...old, submission: { workflow_state: 'unsubmitted', missing: true } })]);
  assert.ok(kept, 'three weeks late is exactly the thing you need to find');
  assert.equal(kept.missing, true);

  const dropped = map([assignment({ ...old, submission: { workflow_state: 'unsubmitted', missing: false } })]);
  assert.equal(dropped.length, 0, 'without the flag, the old window still applies');
});

test('missing work stops showing after a term, not forever', () => {
  const raw = assignment({ due_at: at(-(DAYS_MISSING + 1)), submission_types: ['online_upload'],
    submission: { workflow_state: 'unsubmitted', missing: true } });
  assert.equal(map([raw]).length, 0);
});

test('handing it in clears missing, whatever Canvas still says', () => {
  const [t] = map([assignment({ due_at: at(-3), submission_types: ['online_upload'],
    submission: { workflow_state: 'submitted', submitted_at: at(-1), missing: true } })]);
  assert.equal(t.missing, false);
});

test('the class average rides along only when Canvas publishes one', () => {
  const graded = (stats) => mapGraded([{ id: 4, name: 'Quiz', points_possible: 20,
    submission: { score: 18, graded_at: at(-1) }, ...(stats ? { score_statistics: stats } : {}) }])[0];
  assert.equal(graded({ mean: 14.28 }).classMean, 14.3, 'rounded to one place, like the score');
  assert.equal(graded(null).classMean, null, 'a class too small to publish stays blank');
});

test('a graded row carries the same id as its task, so a missing zero is not listed twice', () => {
  const raw = assignment({ id: 15, due: at(-9), submission_types: ['online_upload'],
    sub: undefined, submission: { workflow_state: 'graded', submitted_at: null, graded_at: at(-8), score: 0, missing: true } });
  const [t] = mapAssignments([raw], { host: HOST, course: COURSE, now: NOW });
  const [g] = mapGraded([raw], { host: HOST });
  assert.equal(t.missing, true);
  assert.equal(g.id, t.id);
});
