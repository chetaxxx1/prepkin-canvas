// Turning Canvas's API into the shape the app wants.
//
// Kept free of any chrome.* call on purpose: the service worker pulls it in with
// importScripts, and `node --test` requires it directly. That is what makes the
// judgement calls here — which work counts, what "done" means — testable with no
// Canvas account and no network.

/// Canvas's to-do feed labels items `submitting` ("you owe this") or `grading`
/// ("you owe marks on this"). Only the first is homework; the second is what a
/// teacher, or a student who TAs, sees. Mixing them puts a marking queue on a
/// student's task list.
const TODO_TYPE_TO_DO = 'submitting';

/// How far around today an assignment has to fall to be worth showing.
/// Wider than "due today" so nothing lands as a surprise, narrow enough that a
/// syllabus full of May deadlines does not bury this week.
const DAYS_AHEAD = 14;
const DAYS_OVERDUE = 7;
/// Work you just handed in still shows briefly, so the app can tick it off and
/// pay for it rather than having it silently vanish.
const DAYS_AFTER_SUBMIT = 3;

const SUBMITTED_STATES = ['submitted', 'graded', 'pending_review'];

const DAY = 86_400_000;

// MARK: - Courses

/// Course list, current grade, and the dashboard colour, from
/// `GET /courses?include[]=total_scores` plus `GET /users/self/colors`.
function mapCourses(raw, colors = {}) {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((course) => {
    if (!course || course.id == null || !course.name) return [];
    // total_scores puts the score on the student's own enrollment row.
    const enrollment = (course.enrollments ?? []).find((e) => e.type === 'student')
      ?? (course.enrollments ?? [])[0];
    return [{
      id: String(course.id),
      name: course.name,
      code: course.course_code ?? '',
      // Canvas gives 0-100, or null before anything is graded. Null is a real
      // answer — "no grade yet" is not the same as a zero.
      score: numberOrNull(enrollment?.computed_current_score),
      grade: enrollment?.computed_current_grade ?? null,
      colorHex: colors[`course_${course.id}`] ?? null,
    }];
  });
}

// MARK: - Assignments

/// One course's assignments, from
/// `GET /courses/:id/assignments?include[]=submission`.
///
/// Deliberately filtered here rather than with Canvas's `bucket` parameter:
/// `bucket=upcoming` quietly drops overdue and undated work, which is exactly
/// the work a student most needs to see.
function mapAssignments(raw, { host, course, now = Date.now() } = {}) {
  if (!Array.isArray(raw) || !course) return [];
  return raw.flatMap((a) => {
    if (!a || a.id == null || !a.name) return [];

    const submittedAt = submissionTime(a.submission);
    const dueAt = a.due_at ?? null;
    if (!isWorthShowing({ dueAt, submittedAt, now })) return [];

    return [{
      // Host keeps two schools apart, the letter keeps an assignment from
      // colliding with a quiz of the same id.
      id: `c-${host}-a${a.id}`,
      title: a.name,
      courseName: course.name,
      courseId: course.id,
      colorHex: course.colorHex ?? null,
      dueAt,
      submittedAt,
      score: numberOrNull(a.submission?.score),
      pointsPossible: numberOrNull(a.points_possible),
      url: typeof a.html_url === 'string' ? a.html_url : null,
    }];
  });
}

/// Canvas reports an unsubmitted assignment as a submission row in state
/// `unsubmitted`, so the state is what counts, not whether the row exists.
function submissionTime(submission) {
  if (!submission || !SUBMITTED_STATES.includes(submission.workflow_state)) return null;
  return submission.submitted_at ?? submission.graded_at ?? null;
}

function isWorthShowing({ dueAt, submittedAt, now }) {
  if (submittedAt) {
    const age = now - Date.parse(submittedAt);
    return Number.isFinite(age) ? age <= DAYS_AFTER_SUBMIT * DAY : false;
  }
  // Undated work is still owed, so it stays on the list.
  if (!dueAt) return true;
  const due = Date.parse(dueAt);
  if (!Number.isFinite(due)) return true;
  return due - now <= DAYS_AHEAD * DAY && now - due <= DAYS_OVERDUE * DAY;
}

// MARK: - To-do feed

/// The cheap cross-course sweep. Used to catch anything the per-course pass
/// missed, so its rows carry no grade or submission detail.
///
/// Filtered through the same date window as the per-course pass — with
/// `ungraded_quizzes` included, the feed can surface a quiz months out, and a
/// syllabus full of May deadlines must not bury this week here either.
function mapTodo(raw, host, now = Date.now()) {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((item) => {
    if (!item || item.type !== TODO_TYPE_TO_DO) return [];
    const source = item.assignment ?? item.quiz;
    if (!source || source.id == null) return [];
    const title = source.name ?? source.title;
    if (!title) return [];
    if (!isWorthShowing({ dueAt: source.due_at ?? null, submittedAt: null, now })) return [];
    return [{
      id: `c-${host}-${item.assignment ? 'a' : 'q'}${source.id}`,
      title,
      courseName: item.context_name ?? '',
      courseId: item.course_id != null ? String(item.course_id) : null,
      colorHex: null,
      dueAt: source.due_at ?? null,
      submittedAt: null,
      score: null,
      pointsPossible: numberOrNull(source.points_possible),
      url: typeof source.html_url === 'string' ? source.html_url : null,
    }];
  });
}

// MARK: - Joining it up

/// The per-course pass knows about submissions and grades, so it wins any tie.
/// The to-do sweep only adds what it alone found.
function merge(detailed, fallback) {
  const seen = new Set(detailed.map((t) => t.id));
  return [...detailed, ...fallback.filter((t) => !seen.has(t.id))]
    .sort((a, b) => (a.dueAt ?? '9999') .localeCompare(b.dueAt ?? '9999'));
}

function numberOrNull(value) {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

if (typeof module !== 'undefined') {
  module.exports = {
    mapCourses, mapAssignments, mapTodo, merge,
    TODO_TYPE_TO_DO, DAYS_AHEAD, DAYS_OVERDUE, DAYS_AFTER_SUBMIT,
  };
}
