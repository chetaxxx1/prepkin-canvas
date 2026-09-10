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
/// Work the school itself marked missing keeps showing long after the overdue
/// window closes. A zero from three weeks ago is the thing a student most needs
/// to find, and dropping it at seven days is how it stays lost.
const DAYS_MISSING = 90;
/// Work you just handed in still shows briefly, so the app can tick it off and
/// pay for it rather than having it silently vanish.
const DAYS_AFTER_SUBMIT = 3;
/// How new an undated, unmarked assignment has to be to count as real work
/// rather than a leftover somebody never cleaned up.
const DAYS_NEW = 60;
/// The calendar looks further out than the task list does: a midterm in
/// six weeks belongs on a calendar even though it does not belong on tonight's
/// list. Events a week gone still show, as the tasks do.
const EVENT_DAYS_AHEAD = 90;
const EVENT_DAYS_BACK = 7;

const SUBMITTED_STATES = ['submitted', 'graded', 'pending_review'];
/// Ways of handing work in through Canvas itself. Anything else — on paper,
/// in class, "no submission" — is graded without a submission row ever
/// getting a time.
const ONLINE_TYPES = ['online_text_entry', 'online_url', 'online_upload', 'media_recording',
  'student_annotation', 'online_quiz', 'discussion_topic', 'external_tool'];

const DAY = 86_400_000;

// MARK: - Courses

/// Course list, current grade, and the dashboard colour, from
/// `GET /courses?enrollment_state=active&include[]=total_scores&include[]=term`
/// plus `GET /users/self/colors`.
function mapCourses(raw, colors = {}, { now = Date.now() } = {}) {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((course) => {
    if (!course || course.id == null || !course.name) return [];
    if (!isCurrentTerm(course, now)) return [];
    // total_scores puts the score on the student's own enrollment row. A course
    // you are only in as a TA, teacher or observer is not your coursework: its
    // assignments are somebody else's homework and its grade is not yours. When
    // Canvas lists no enrollments at all there is no evidence either way, so
    // the course stays.
    const enrollments = course.enrollments ?? [];
    const enrollment = enrollments.find((e) => e.type === 'student') ?? null;
    if (enrollments.length && !enrollment) return [];
    return [{
      id: String(course.id),
      name: course.name,
      code: course.course_code ?? '',
      // Canvas gives 0-100, or null before anything is graded. Null is a real
      // answer — "no grade yet" is not the same as a zero.
      score: numberOrNull(enrollment?.computed_current_score),
      grade: enrollment?.computed_current_grade ?? null,
      colorHex: safeColor(colors[`course_${course.id}`]),
      // Only when Canvas says so either way; absent means "assume weighted".
      ...(typeof course.apply_assignment_group_weights === 'boolean'
        ? { weighted: course.apply_assignment_group_weights } : {}),
    }];
  });
}

/// Canvas leaves you enrolled in a course forever, so `enrollment_state=active`
/// alone still hands back a class that finished years ago — and with it every
/// undated quiz nobody ever took. The term's end date and the course's own
/// state are what actually say "this is over".
///
/// A missing field is not evidence against a course: plenty of courses have no
/// term end date at all, so absence means keep, never drop.
function isCurrentTerm(course, now) {
  if (course.workflow_state != null && course.workflow_state !== 'available') return false;
  const ends = course.term?.end_at;
  if (!ends) return true;
  const at = Date.parse(ends);
  return Number.isFinite(at) ? at > now : true;
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

    // Excused work is neither owed nor done: nothing to do, nothing to pay.
    if (a.submission?.excused === true) return [];
    const submittedAt = submissionTime(a.submission, a.submission_types);
    const dueAt = a.due_at ?? null;
    // Canvas sets `missing` itself once the due date passes with nothing handed
    // in. Taking the school's own word for it rather than guessing is the same
    // rule as the weights: we do not invent a judgement Canvas did not make.
    const missing = !submittedAt && a.submission?.missing === true;
    if (!isWorthShowing({ dueAt, submittedAt, missing, now })) return [];
    // Undated work carrying no marks is far more often a leftover — an old
    // practice quiz, a placeholder — than something you owe. Recent work gets
    // the benefit of the doubt. The course is current by construction: the
    // caller only walks courses mapCourses kept.
    if (!dueAt && !numberOrNull(a.points_possible) && !createdRecently(a.created_at, now)) return [];

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
      gradedAt: a.submission?.graded_at ?? null,
      missing,
      url: typeof a.html_url === 'string' ? a.html_url : null,
    }];
  });
}

/// Canvas reports an unsubmitted assignment as a submission row in state
/// `unsubmitted`, so the state is what counts, not whether the row exists.
///
/// A `graded` row with no submission time means the teacher entered a mark
/// for something never handed in through Canvas. For work done offline — on
/// paper, in class — the grade is the proof it was turned in. For anything
/// that should have come in online it is a zero for missing work (Canvas only
/// sets `missing` once the due date has passed, so that flag alone is not
/// enough), and paying for it would reward skipping the work.
function submissionTime(submission, types) {
  if (!submission || !SUBMITTED_STATES.includes(submission.workflow_state)) return null;
  if (submission.submitted_at) return submission.submitted_at;
  return expectsOnline(types) ? null : (submission.graded_at ?? null);
}

/// Missing or empty types are read as online: the safe side is not paying.
function expectsOnline(types) {
  if (!Array.isArray(types) || !types.length) return true;
  return types.some((t) => ONLINE_TYPES.includes(t));
}

function createdRecently(createdAt, now) {
  if (!createdAt) return false;
  const at = Date.parse(createdAt);
  return Number.isFinite(at) && now - at <= DAYS_NEW * DAY;
}

function isWorthShowing({ dueAt, submittedAt, missing = false, now }) {
  if (submittedAt) {
    const age = now - Date.parse(submittedAt);
    return Number.isFinite(age) ? age <= DAYS_AFTER_SUBMIT * DAY : false;
  }
  // Undated work is still owed, so it stays on the list.
  if (!dueAt) return true;
  const due = Date.parse(dueAt);
  if (!Number.isFinite(due)) return true;
  if (missing) return now - due <= DAYS_MISSING * DAY;
  return due - now <= DAYS_AHEAD * DAY && now - due <= DAYS_OVERDUE * DAY;
}

// MARK: - To-do feed

/// The cheap cross-course sweep. Used to catch anything the per-course pass
/// missed, so its rows carry no grade or submission detail.
///
/// Filtered through the same date window as the per-course pass — with
/// `ungraded_quizzes` included, the feed can surface a quiz months out, and a
/// syllabus full of May deadlines must not bury this week here either.
/// `courseIds`, when given, is the set of courses the term filter kept. The
/// sweep is the one call that crosses every enrolment you have, concluded ones
/// included, so without it a 2020 course walks back in through the side door.
function mapTodo(raw, host, now = Date.now(), courseIds = null) {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((item) => {
    if (!item || item.type !== TODO_TYPE_TO_DO) return [];
    if (courseIds && !courseIds.has(String(item.course_id ?? ''))) return [];
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

// MARK: - Grades over time

/// The graded items in one course, oldest first, for the sparkline and the
/// "recent" list under an expanded grade row. Only work that actually carries a
/// score counts — an ungraded submission is not a data point.
function mapGraded(raw, { limit = 24, host = '' } = {}) {
  if (!Array.isArray(raw)) return [];
  return raw
    .flatMap((a) => {
      if (!a || a.id == null || !a.name) return [];
      const score = numberOrNull(a.submission?.score);
      const outOf = numberOrNull(a.points_possible);
      if (score === null || !outOf) return [];
      const at = a.submission?.graded_at ?? a.submission?.submitted_at ?? a.due_at ?? null;
      // Canvas only publishes score_statistics once enough of the class has been
      // marked, so `mean` is absent far more often than not. Absent stays absent.
      const mean = numberOrNull(a.score_statistics?.mean);
      return [{
        // Same id as the task row, so a zero for missing work is not listed
        // twice: once as missing, once as a grade.
        id: `c-${host}-a${a.id}`,
        title: a.name,
        score,
        outOf,
        percent: Math.round((score / outOf) * 1000) / 10,
        classMean: mean === null ? null : Math.round(mean * 10) / 10,
        at,
      }];
    })
    .sort((x, y) => String(x.at ?? '').localeCompare(String(y.at ?? '')))
    .slice(-limit);
}

/// Assignment-group weights, from `GET /courses/:id/assignment_groups`.
///
/// Canvas only honours these when the course turns weighting on, so an
/// unweighted course returns null rather than a set of numbers that look
/// authoritative and are not. The what-if screen asks the student instead.
function mapWeights(raw, { weighted = true } = {}) {
  if (!weighted || !Array.isArray(raw)) return null;
  const groups = raw.flatMap((g) => {
    if (!g || g.id == null || !g.name) return [];
    const weight = numberOrNull(g.group_weight);
    return weight ? [{ id: String(g.id), name: g.name, weight }] : [];
  });
  return groups.length ? groups : null;
}

/// What you need on the remaining work to finish on `target`.
///
/// `weight` is the share of the grade still outstanding, as a percent. Returns
/// null when there is nothing left to weigh, and can exceed 100 — the caller
/// decides how to say that kindly.
function requiredScore({ current, target, weight }) {
  if (![current, target, weight].every((n) => typeof n === 'number')) return null;
  if (weight <= 0 || weight > 100) return null;
  const done = (100 - weight) / 100;
  const needed = (target - current * done) / (weight / 100);
  return Math.round(needed * 10) / 10;
}

// MARK: - Paging

/// The `next` link out of Canvas's `Link` header, or null when there isn't one.
///
/// The header is data from the server and these fetches carry the student's
/// cookies, so a next-page link pointing off `origin` is refused. That is either
/// a misconfigured Canvas or somebody steering a credentialed read; neither is
/// worth following.
function nextLink(header, origin) {
  if (!header) return null;
  for (const part of header.split(',')) {
    const m = part.match(/<([^>]+)>\s*;\s*rel="next"/);
    if (!m) continue;
    try {
      return new URL(m[1]).origin === origin ? m[1] : null;
    } catch {
      return null;
    }
  }
  return null;
}

// MARK: - Joining it up

/// Every id the per-course pass looked at, kept or dropped — and for a quiz,
/// the quiz's own key too. The sweep must not bring back work that pass
/// deliberately left out, nor list a quiz a second time under its quiz id.
function examinedIds(raw, host, into = new Set()) {
  if (!Array.isArray(raw)) return into;
  for (const a of raw) {
    if (!a || a.id == null) continue;
    into.add(`c-${host}-a${a.id}`);
    if (a.quiz_id != null) into.add(`c-${host}-q${a.quiz_id}`);
  }
  return into;
}

// MARK: - Course calendar

/// Things that happen rather than get handed in: an exam sitting, a class a
/// teacher put on the course calendar by hand, office hours. Canvas returns
/// assignments through the same endpoint with `type=assignment`; those are the
/// task list's job, and a row wearing an `assignment` is dropped here so the
/// same quiz is never both a task and an event.
function mapEvents(raw, { host, courses = [], now = Date.now() } = {}) {
  if (!Array.isArray(raw)) return [];
  const byCode = new Map(courses.map((c) => [`course_${c.id}`, c]));
  const out = [];
  const seen = new Set();
  for (const e of raw) {
    if (!e || e.id == null || !e.title) continue;
    if (e.assignment || e.type === 'assignment') continue;
    if (e.hidden === true || e.workflow_state === 'deleted') continue;
    const startAt = e.start_at ?? null;
    const start = Date.parse(startAt);
    if (!Number.isFinite(start)) continue;
    if (start - now > EVENT_DAYS_AHEAD * DAY || now - start > EVENT_DAYS_BACK * DAY) continue;
    const course = byCode.get(e.context_code) ?? null;
    // Personal events (context_code user_…) are the student's own; the phone
    // only wants the school's.
    if (!course) continue;
    const id = `e-${host}-${e.id}`;
    if (seen.has(id)) continue;
    seen.add(id);
    out.push({
      id,
      title: e.title,
      courseName: course.name,
      courseId: course.id,
      colorHex: course.colorHex ?? null,
      startAt,
      endAt: e.end_at ?? null,
      allDay: e.all_day === true,
      location: typeof e.location_name === 'string' && e.location_name ? e.location_name : null,
      url: typeof e.html_url === 'string' ? e.html_url : null,
    });
  }
  return out.sort((a, b) => a.startAt.localeCompare(b.startAt));
}

/// Canvas caps `context_codes[]` at ten per request, so a student with twelve
/// courses needs two calls. Returns the query strings, one per chunk.
function eventQueries(courses, now = Date.now()) {
  const day = (d) => new Date(d).toISOString().slice(0, 10);
  const from = day(now - EVENT_DAYS_BACK * DAY);
  const to = day(now + EVENT_DAYS_AHEAD * DAY);
  const codes = courses.map((c) => `context_codes[]=course_${encodeURIComponent(c.id)}`);
  const queries = [];
  for (let i = 0; i < codes.length; i += 10) {
    queries.push(
      `/api/v1/calendar_events?type=event&start_date=${from}&end_date=${to}&per_page=100&${codes.slice(i, i + 10).join('&')}`
    );
  }
  return queries;
}

/// The per-course pass knows about submissions and grades, so it wins any tie.
/// The to-do sweep only adds what that pass never saw — a course whose
/// assignment list failed to load, say.
function merge(detailed, fallback, examined = new Set()) {
  const seen = new Set([...examined, ...detailed.map((t) => t.id)]);
  return [...detailed, ...fallback.filter((t) => !seen.has(t.id))]
    .sort((a, b) => (a.dueAt ?? '9999') .localeCompare(b.dueAt ?? '9999'));
}

/// A dashboard colour goes straight into a `style="background:…"` attribute, so
/// it has to be a colour and nothing else. Escaping the string is not enough —
/// `;` and `(` are legal there and would let a second declaration ride along.
function safeColor(value) {
  return typeof value === 'string' && /^#[0-9a-fA-F]{3,8}$/.test(value) ? value : null;
}

function numberOrNull(value) {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

if (typeof module !== 'undefined') {
  module.exports = {
    mapCourses, mapAssignments, mapTodo, merge, examinedIds, mapGraded, mapWeights, requiredScore, safeColor, nextLink,
    mapEvents, eventQueries,
    TODO_TYPE_TO_DO, DAYS_AHEAD, DAYS_OVERDUE, DAYS_MISSING, DAYS_AFTER_SUBMIT, DAYS_NEW, EVENT_DAYS_AHEAD, EVENT_DAYS_BACK,
  };
}
