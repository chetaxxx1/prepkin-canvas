// A fake Canvas and a fake bridge, in one https server, for the end-to-end
// tests in e2e.test.js.
//
// Canvas: only the six endpoints the extension calls, with real `Link` paging
// and a world per hostname — so https://localhost:8443 and
// https://127.0.0.1:8443 are two different schools on one process.
//
// Bridge: the seven functions from bridge/schema.sql with the same rules
// (15-minute claim window, first laptop wins, token hashes, size caps), so the
// pairing and unpairing paths can be driven without Supabase.
//
// Control endpoints under /__ let a test swap a world, log the student out,
// break an endpoint, move the bridge's clock, or read what was requested.

const https = require('https');
const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const DAY = 86_400_000;

/// A throwaway cert per run, unless PREPKIN_CERT_DIR names a folder with a
/// lasting one (made by test/make-cert.sh) — that one is also installed into an
/// iOS simulator's trust store, so the real app can reach the fake bridge.
function selfSignedCert() {
  const keep = process.env.PREPKIN_CERT_DIR;
  if (keep && fs.existsSync(path.join(keep, 'cert.pem'))) {
    return { key: fs.readFileSync(path.join(keep, 'key.pem')), cert: fs.readFileSync(path.join(keep, 'cert.pem')) };
  }
  const dir = fs.mkdtempSync(path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'prepkin-cert-'));
  const key = path.join(dir, 'key.pem');
  const cert = path.join(dir, 'cert.pem');
  execFileSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', key,
    '-out', cert, '-days', '2', '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1'], { stdio: 'ignore' });
  return { key: fs.readFileSync(key), cert: fs.readFileSync(cert) };
}

// MARK: - Canvas worlds

function blankWorld() {
  return {
    me: { id: 501, name: 'Alex Rivera', sortable_name: 'Rivera, Alex', short_name: 'Alex' },
    loggedIn: true,
    notCanvas: false,
    courses: [],
    pastCourses: [],
    colors: {},
    assignments: {},
    groups: {},
    todoExtra: [],
    perPage: 100,
    linkHost: null,
    // path substring -> { status, body } | 'drop' | 'html' | 'hang'
    fail: {},
    // added to every Canvas answer, to stand in for a slow school
    delayMs: 0,
    // Canvas's leaky bucket (app/middleware/request_throttle.rb), when set:
    // { hwm: 600, upFront: 50, outflow: 10, cost: 8 }. Every request in
    // flight reserves `upFront`; at `hwm` the answer is Canvas's own 403.
    bucket: null,
  };
}

/// One school's bucket: what is banked, what is in flight, and what was seen.
function bucketState(world) {
  return (world._bucket ??= { level: 0, at: Date.now(), inFlight: 0, peakInFlight: 0, throttled: 0, served: 0 });
}

function bucketAdmit(world) {
  const b = bucketState(world); const cfg = world.bucket;
  const now = Date.now();
  b.level = Math.max(0, b.level - ((now - b.at) / 1000) * cfg.outflow);
  b.at = now;
  b.inFlight += 1;
  b.peakInFlight = Math.max(b.peakInFlight, b.inFlight);
  if (b.level + b.inFlight * cfg.upFront >= cfg.hwm) { b.inFlight -= 1; b.throttled += 1; return false; }
  return true;
}

function bucketRelease(world) {
  const b = bucketState(world);
  b.inFlight -= 1; b.served += 1; b.level += world.bucket.cost;
}

function paged(req, url, rows, world) {
  const perPage = Math.min(Number(url.searchParams.get('per_page')) || 10, world.perPage);
  const page = Number(url.searchParams.get('page')) || 1;
  const slice = rows.slice((page - 1) * perPage, page * perPage);
  const headers = { 'Content-Type': 'application/json' };
  if (page * perPage < rows.length) {
    const next = new URL(url);
    if (world.linkHost) { next.protocol = 'https:'; next.host = world.linkHost; }
    next.searchParams.set('page', String(page + 1));
    next.searchParams.set('per_page', String(perPage));
    headers.Link = `<${next.href}>; rel="next",<${url.href}>; rel="current"`;
  }
  return { status: 200, headers, body: JSON.stringify(slice) };
}

/// Canvas's to-do sweep crosses every enrolment, concluded ones included, and
/// only ever lists work you have not handed in.
function derivedTodo(world) {
  const items = [];
  for (const c of world.courses) {
    for (const a of world.assignments[c.id] ?? []) {
      const s = a.submission;
      const handedIn = s && ['submitted', 'graded', 'pending_review'].includes(s.workflow_state) && s.submitted_at;
      if (handedIn || s?.excused) continue;
      if (a.due_at && Date.parse(a.due_at) < Date.now()) continue; // the sweep is "upcoming", never past due
      items.push({
        type: c.enrollments?.[0]?.type === 'teacher' ? 'grading' : 'submitting',
        context_type: 'Course', course_id: c.id, context_name: c.name,
        assignment: { id: a.id, name: a.name, due_at: a.due_at, points_possible: a.points_possible, html_url: a.html_url },
        html_url: a.html_url,
      });
    }
  }
  return items.concat(world.todoExtra);
}

function canvasRoute(req, url, world) {
  const p = url.pathname;
  for (const [needle, how] of Object.entries(world.fail)) {
    if (!p.includes(needle) && !url.href.includes(needle)) continue;
    if (how === 'drop') return { destroy: true };
    if (how === 'hang') return { hang: true };
    if (how === 'html') return { status: 200, headers: { 'Content-Type': 'text/html' }, body: '<html><body>Maintenance</body></html>' };
    return { status: how.status, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(how.body ?? {}) };
  }
  const sub = req.method === 'POST' && p.match(/^\/courses\/(\d+)\/assignments\/(\d+)\/submissions$/);
  if (sub) {
    // Classic Canvas: the form posts, the submission is recorded, and the
    // browser is sent back to the assignment page.
    const a = (world.assignments[sub[1]] ?? []).find((x) => String(x.id) === sub[2]);
    if (a) a.submission = { workflow_state: 'submitted', submitted_at: new Date().toISOString() };
    return { status: 302, headers: { Location: `/courses/${sub[1]}/assignments/${sub[2]}` }, body: '' };
  }
  if (!p.startsWith('/api/v1/')) {
    return { status: 200, headers: { 'Content-Type': 'text/html' }, body: pageFor(url) };
  }
  if (world.notCanvas) {
    return { status: 200, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id: 1 }) };
  }
  if (!world.loggedIn) {
    return { status: 401, headers: { 'Content-Type': 'application/json' }, body: '{"status":"unauthenticated"}' };
  }
  const json = (body) => ({ status: 200, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (p === '/api/v1/users/self') return json(world.me);
  if (p === '/api/v1/users/self/colors') return json({ custom_colors: world.colors });
  if (p === '/api/v1/courses') {
    const state = url.searchParams.get('enrollment_state');
    // Finished courses answer only to `completed`, as Canvas's do; a course
    // with an ended term still sits in the active list, as Canvas's does.
    if (state === 'completed') return paged(req, url, world.pastCourses ?? [], world);
    const rows = world.courses.filter((c) => state !== 'active' || (c.enrollments ?? []).some((e) => e.enrollment_state === 'active'));
    return paged(req, url, rows, world);
  }
  if (p === '/api/v1/users/self/todo') return paged(req, url, derivedTodo(world), world);
  let m = p.match(/^\/api\/v1\/courses\/(\d+)\/assignments$/);
  if (m) return paged(req, url, world.assignments[m[1]] ?? [], world);
  m = p.match(/^\/api\/v1\/courses\/(\d+)\/assignment_groups$/);
  if (m) return paged(req, url, world.groups[m[1]] ?? [], world);
  return { status: 404, headers: { 'Content-Type': 'application/json' }, body: '{"errors":[{"message":"not found"}]}' };
}

const ASSIGNMENTS_INDEX = `<h1 class="screenreader-only">Assignments</h1>
<div class="header-bar"><div class="header-bar-left ic-Form-control assignment-search"><div class="ic-Multi-input"><label for="search_term" class="screenreader-only">Search for Assignment</label><span id="search_input_container"><label data-cid="TextInput" for="TextInput___0" class="css-1-formFieldLayout" style="width: 16rem;"><span class="css-2-formFieldLayout__children"><span class="css-3-textInput__facade"><span class="css-4-textInput__layout"><svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg><span class="css-5-textInput__inputLayout"><input data-testid="assignment-search-input" placeholder="Search..." type="text" id="TextInput___0" class="css-6-textInput" value=""></span></span></span></span></label></span><input class="ic-Input" id="search_term" type="hidden" name="search_term" value=""></div></div>
<div class="header-bar-right"><div style="display:inline-block" data-view="showBy"><fieldset role="radiogroup" data-cid="RadioInputGroup" class="css-7-formFieldLayout"><legend style="display: contents;"><span class="css-8-screenReaderContent">Show By</span></legend><span class="css-9-formFieldLayout__children"><span class="css-a-formFieldGroup"><span class="css-b-grid"><span class="css-c-gridRow"><span class="css-d-gridCol"><div data-cid="RadioInput" class="css-e-radioInput"><div class="css-f"><input tabindex="0" id="show_by_date" name="show_by" type="radio" class="css-g-radioInput__input" value="date" checked=""><label for="show_by_date" class="css-h-radioInput__control"><span aria-hidden="true" class="css-i-radioInput__facade"></span><span class="css-j-radioInput__label">Show by Date</span></label></div></div></span><span class="css-d-gridCol"><div data-cid="RadioInput" class="css-e-radioInput"><div class="css-f"><input tabindex="-1" id="show_by_type" name="show_by" type="radio" class="css-g-radioInput__input" value="type"><label for="show_by_type" class="css-h-radioInput__control"><span aria-hidden="true" class="css-i-radioInput__facade"></span><span class="css-j-radioInput__label">Show by Type</span></label></div></div></span></span></span></span></span></fieldset></div></div></div>
<div data-view="assignmentGroups" class="item-group-container" id="ag-list"><ul class="collectionViewItems ig-list"><li class="item-group-condensed"><div id="assignment_group_overdue" class="assignment_group"><div class="ig-header"><h2 class="ig-header-title"><button class="element_toggler accessible-toggler" aria-controls="assignment_group_overdue_assignments" aria-expanded="true" aria-label="Overdue Assignments toggle assignment visibility">
<i class="icon-mini-arrow-down" aria-hidden="true"></i> Overdue Assignments</button></h2><div class="ag-header-controls"></div></div><div id="assignment_group_overdue_assignments" class="assignment-list"><ul class="collectionViewItems ig-list draggable"><li class="assignment search_show"><div id="assignment_20" class="ig-row ig-published"><div class="ig-row__layout"><div class="ig-type-icon"><i aria-hidden="true" class="icon-assignment"></i><span class="screenreader-only">Assignment</span></div><div class="ig-info"><a href="/courses/1/assignments/20" class="ig-title">Quiz corrections</a><div class="ig-details rendered"><div class="ig-details__item assignment-date-due"><span class="css-1-text">Due</span> <span><time>Aug 30 at 5:03am</time></span></div><div class="ig-details__item js-score"><span class="non-screenreader" aria-hidden="true">Excused</span><span class="screenreader-only">This assignment has been excused.</span></div></div></div></div></div></li><li class="assignment search_show"><div id="assignment_23" class="ig-row ig-published"><div class="ig-row__layout"><div class="ig-type-icon"><i aria-hidden="true" class="icon-assignment"></i><span class="screenreader-only">Assignment</span></div><div class="ig-info"><a href="/courses/1/assignments/23" class="ig-title">Reading response: Chapter 10</a><div class="ig-details rendered"><div class="ig-details__item assignment-date-due"><span class="css-1-text">Due</span> <span><time>Sep 9 at 5:03am</time></span></div><div class="ig-details__item js-score"><span class="non-screenreader" aria-hidden="true"><span data-tooltip="" class="score-display" title="No Submission">-/15 pts</span></span><span class="screenreader-only">No submission for this assignment. 15 points possible.</span></div></div></div></div></div></li></ul></div></div></li><li class="item-group-condensed"><div id="assignment_group_upcoming" class="assignment_group"><div class="ig-header"><h2 class="ig-header-title"><button class="element_toggler accessible-toggler" aria-controls="assignment_group_upcoming_assignments" aria-expanded="true" aria-label="Upcoming Assignments toggle assignment visibility">
<i class="icon-mini-arrow-down" aria-hidden="true"></i> Upcoming Assignments</button></h2><div class="ag-header-controls"></div></div><div id="assignment_group_upcoming_assignments" class="assignment-list"><ul class="collectionViewItems ig-list draggable"><li class="assignment search_show"><div id="assignment_12" class="ig-row ig-published"><div class="ig-row__layout"><div class="ig-type-icon"><i aria-hidden="true" class="icon-assignment"></i><span class="screenreader-only">Assignment</span></div><div class="ig-info"><a href="/courses/1/assignments/12" class="ig-title">Unit 4 project proposal</a><div class="ig-details rendered"><div class="ig-details__item assignment-date-due"><span class="css-1-text">Due</span> <span><time>Oct 2 at 5:03am</time></span></div><div class="ig-details__item js-score"><span class="non-screenreader" aria-hidden="true"><span data-tooltip="" class="score-display" title="No Submission">-/50 pts</span></span><span class="screenreader-only">No submission for this assignment. 15 points possible.</span></div></div></div></div></div></li></ul></div></div></li><li class="item-group-condensed"><div id="assignment_group_past" class="assignment_group"><div class="ig-header"><h2 class="ig-header-title"><button class="element_toggler accessible-toggler" aria-controls="assignment_group_past_assignments" aria-expanded="true" aria-label="Past Assignments toggle assignment visibility">
<i class="icon-mini-arrow-down" aria-hidden="true"></i> Past Assignments</button></h2><div class="ag-header-controls"></div></div><div id="assignment_group_past_assignments" class="assignment-list"><ul class="collectionViewItems ig-list draggable"><li class="assignment search_show"><div id="assignment_19" class="ig-row ig-published"><div class="ig-row__layout"><div class="ig-type-icon"><i aria-hidden="true" class="icon-assignment"></i><span class="screenreader-only">Assignment</span></div><div class="ig-info"><a href="/courses/1/assignments/19" class="ig-title">Problem Set 8: Angular Momentum</a><div class="ig-details rendered"><div class="ig-details__item assignment-date-due"><span class="css-1-text">Due</span> <span><time>Sep 11 at 5:03am</time></span></div><div class="ig-details__item js-score"><span class="non-screenreader" aria-hidden="true"><span class="score-display">47/50 pts</span></span><span class="screenreader-only">Scored.</span></div></div></div></div></div></li></ul></div></div></li></ul></div>`;
const QUIZZES_INDEX = `<h1 class="screenreader-only">Quizzes</h1>
<div class="header-bar"><div class="header-bar-left"><div class="ic-Search"><label for="searchTerm" class="screenreader-only">Search for Quiz</label><div class="ic-Search-icon-container"><i class="icon-search ic-Search-icon" aria-hidden="true"></i></div><input class="ic-Input ic-Search-input" id="searchTerm" type="search" name="search_term" value="" placeholder="Search for Quiz"></div></div></div>
<div class="item-group-container"><div data-view="assignment" class="item-group-condensed"><div class="ig-header"><h2 class="ig-header-title"><button aria-controls="assignment-quizzes" class="element_toggler accessible-toggler" aria-expanded="true" aria-label="Assignment Quizzes toggle quiz visibility"><i class="icon-mini-arrow-down"></i> Assignment Quizzes</button></h2></div>
<ul id="assignment-quizzes" class="ig-list collectionViewItems"><li class="quiz"><div id="summary_quiz_1" class="ig-row"><div class="ig-row__layout"><div class="ig-type-icon"><i class="icon-quiz icon-Solid" aria-hidden="true"></i><span class="screenreader-only">Quiz</span></div><div class="ig-info"><a href="/courses/1/quizzes/1" class="ig-title">Unit 4 concept check</a><div class="ig-details"><div class="ig-details__item date-due"><span class="css-1-text">Due</span> <span><time>Sep 8 at 5:03am</time></span></div><div class="ig-details__item">6 pts</div><div class="ig-details__item">3 Questions</div><div class="ig-details__item">Available until Sep 30 at 11:59pm</div></div></div></div></div></li></ul>
<ul class="ig-list no_content" style="display: none;"><li><div class="ig-row ig-row-empty"><div class="ig-empty-msg">No quizzes found</div></div></li></ul></div></div>`;
const QUIZZES_EMPTY = `<h1 class="screenreader-only">Quizzes</h1>
<div class="header-bar"><div class="header-bar-left"><div class="ic-Search"><label for="searchTerm" class="screenreader-only">Search for Quiz</label><div class="ic-Search-icon-container"><i class="icon-search ic-Search-icon" aria-hidden="true"></i></div><input class="ic-Input ic-Search-input" id="searchTerm" type="search" name="search_term" value="" placeholder="Search for Quiz"></div></div></div>
<div class="item-group-container"><div data-view="assignment" class="item-group-condensed"><div class="ig-header"><h2 class="ig-header-title"><button aria-controls="assignment-quizzes" class="element_toggler accessible-toggler" aria-expanded="true" aria-label="Assignment Quizzes toggle quiz visibility"><i class="icon-mini-arrow-down"></i> Assignment Quizzes</button></h2></div>
<ul id="assignment-quizzes" class="ig-list collectionViewItems"></ul>
<ul class="ig-list no_content"><li><div class="ig-row ig-row-empty"><div class="ig-empty-msg">No quizzes found</div></div></li></ul></div></div>`;
const quizzesIndex = (empty) => empty ? QUIZZES_EMPTY : QUIZZES_INDEX;
const ANNOUNCEMENTS_INDEX = `<div class="announcements-v2__wrapper"><span class="css-7-screenReaderContent"><h1 dir="ltr" data-cid="Heading" class="css-a-view-heading">Announcements</h1></span><div><span dir="ltr" class="css-b-view"><span dir="ltr" class="css-1-view--block"><span dir="ltr" wrap="wrap" direction="row" class="css-c-view--flex-flex"><span dir="ltr" class="css-d-view-flexItem" style="min-width:100%"><span data-cid="Select SimpleSelect" class="css-e-select"><label data-cid="TextInput" for="announcement-filter" class="css-f-formFieldLayout"><span class="css-g-formFieldLayout__children"><span class="css-h-textInput__facade"><span class="css-i-textInput__layout"><span class="css-j-textInput__inputLayout"><input id="announcement-filter" role="combobox" readonly="" title="All" type="text" class="css-k-textInput" value="All"><span class="css-l-textInput__afterElement"><span class="css-m-select__icon"><svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg></span></span></span></span></span></span></label></span></span><span dir="ltr" class="css-d-view-flexItem"><label data-cid="TextInput" for="announcements-search" class="css-f-formFieldLayout"><span class="css-g-formFieldLayout__children"><span class="css-h-textInput__facade"><span class="css-i-textInput__layout"><svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg><span class="css-j-textInput__inputLayout"><input name="announcements_search" id="announcements-search" placeholder="Search..." type="text" class="css-k-textInput" value=""></span></span></span></span></label></span><span dir="ltr" class="css-d-view-flexItem"><span dir="ltr" class="css-c-view--flex-flex"><button dir="ltr" id="mark_all_announcement_read" data-testid="mark-all-announcement-read" data-cid="BaseButton Button" type="button" class="css-n-view--inlineBlock-baseButton"><span class="css-o-baseButton__content"><span class="css-p-baseButton__childrenLayout"><span class="css-q-baseButton__iconWrapper"><span class="css-r-baseButton__iconSVG"><svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg></span></span><span class="css-s-baseButton__childrenWrapper"><span class="css-t-baseButton__children">Mark All as Read</span></span></span></span></button></span></span></span></span><span dir="ltr" class="css-1-view--block"><button dir="ltr" id="external_feed" data-testid="external-feed-link" type="button" data-cid="Link" class="css-u-view-link">External Feeds</button></span></span></div><span dir="ltr" class="css-b-view"><span class="css-7-screenReaderContent"><h2 dir="ltr" data-cid="Heading" class="css-v-view-heading">Announcements List</h2></span><div class="ic-item-row ic-announcement-row" style="opacity: 1;"><span dir="ltr" class="css-1-view--block"><span dir="ltr" title="" data-cid="Badge" class="css-2-view--inlineBlock-badge"></span></span><div class="ic-item-row__author-col"><span dir="ltr" shape="circle" role="img" aria-label="admin@prepkin.test" class="css-3-view--inlineBlock-avatar"><img alt="admin@prepkin.test" aria-hidden="true" class="css-4-avatar__loadImage"><span aria-hidden="true" class="css-5-avatar__initials">A</span></span></div><div class="ic-item-row__content-col"><a class="ic-item-row__content-link" href="/courses/1/discussion_topics/4"><div class="ic-item-row__content-link-container" data-testid="single-announcement-test-id"><h3 dir="ltr" data-cid="Heading" class="css-6-view-heading"><span class="css-7-screenReaderContent">unread,</span>Problem Set 8 due date moved</h3></div></a><span class="ic-section-tooltip"><span class="css-8-text">All Sections</span></span><div class="ic-item-row__content-container"><div class="ic-announcement-row__content user_content enhanced">Set 8 is now due Thursday at 11:59pm. Nothing else moves.</div></div><a class="ic-item-row__content-link" href="/courses/1/discussion_topics/4"><div class="ic-item-row__content-link-container" data-testid="single-announcement-test-id"><span dir="ltr" data-testid="announcement-reply" class="css-9-view--block"><span color="brand" class="css-8-text"><svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg> Reply</span></span></div></a></div><div class="ic-item-row__meta-col"><div class="ic-item-row__meta-actions"><span class="ic-item-row__master-course-lock lock-icon"></span></div><div class="ic-item-row__meta-content"><div><span class="ic-item-row__meta-content-heading"><p class="css-8-text">Posted on:</p></span><span class="ic-item-row__meta-content-timestamp"><p color="secondary" class="css-8-text">Sep 12, 2026, 4:38 AM</p></span></div></div></div></div><div class="ic-item-row ic-announcement-row" style="opacity: 1;"><span dir="ltr" class="css-1-view--block"><span dir="ltr" class="css-1-view--block"></span></span><div class="ic-item-row__author-col"><span dir="ltr" shape="circle" role="img" aria-label="admin@prepkin.test" class="css-3-view--inlineBlock-avatar"><img alt="admin@prepkin.test" aria-hidden="true" class="css-4-avatar__loadImage"><span aria-hidden="true" class="css-5-avatar__initials">A</span></span></div><div class="ic-item-row__content-col"><a class="ic-item-row__content-link" href="/courses/1/discussion_topics/3"><div class="ic-item-row__content-link-container" data-testid="single-announcement-test-id"><h3 dir="ltr" data-cid="Heading" class="css-6-view-heading">Lab safety refresher on Friday</h3></div></a><span class="ic-section-tooltip"><span class="css-8-text">All Sections</span></span><div class="ic-item-row__content-container"><div class="ic-announcement-row__content user_content enhanced">Goggles on before the door opens. Ten minutes, then the pendulum lab.</div></div><a class="ic-item-row__content-link" href="/courses/1/discussion_topics/3"><div class="ic-item-row__content-link-container" data-testid="single-announcement-test-id"><span dir="ltr" data-testid="announcement-reply" class="css-9-view--block"><span color="brand" class="css-8-text"><svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg> Reply</span></span></div></a></div><div class="ic-item-row__meta-col"><div class="ic-item-row__meta-actions"><span class="ic-item-row__master-course-lock lock-icon"></span></div><div class="ic-item-row__meta-content"><div><span class="ic-item-row__meta-content-heading"><p class="css-8-text">Posted on:</p></span><span class="ic-item-row__meta-content-timestamp"><p color="secondary" class="css-8-text">Sep 12, 2026, 4:38 AM</p></span></div></div></div></div></span></div>`;

// Enough of Canvas's skeleton for the skin, the receipt and the panel to have
// something real to hang on: the global rail with its logomark, a course nav
// with the four low-use tabs, dashboard cards, both To Do lists, a truncated
// Coming Up, a module with due dates, an assignment with Word-pasted ink, a
// grades table, an LTI frame. `?hc=1` turns the school's High Contrast on in
// ENV; `?nq=1` makes it a New Quizzes page; `?wd=1` the widget dashboard.
function pageFor(url) {
  const q = url.searchParams;
  const env = JSON.stringify({ use_high_contrast: q.get('hc') === '1', FEATURES: { widget_dashboard: q.get('wd') === '1' } });
  const bodyClass = q.get('nq') === '1' ? 'native-new-quizzes' : '';
  const p = url.pathname;
  const chrome = `<header id="header" class="ic-app-header"><a id="skip_navigation_link" href="#content">Skip</a>
<div class="ic-app-header__main-navigation"><div class="ic-app-header__logomark-container"><a class="ic-app-header__logomark" href="/"><span class="screenreader-only">School</span></a></div>
<ul class="ic-app-header__menu-list"><li class="ic-app-header__menu-list-item"><a id="global_nav_dashboard_link" class="ic-app-header__menu-list-link" href="/"><span class="menu-item__text">Dashboard</span></a></li>
<li class="ic-app-header__menu-list-item"><a id="global_nav_help_link" class="ic-app-header__menu-list-link" href="#"><span class="menu-item__text">Help</span></a></li></ul></div></header>`;
  const courseNav = `<div class="ic-app-nav-toggle-and-crumbs"><div id="breadcrumbs"><ul><li><a href="/courses/1">AP Physics C</a></li></ul></div></div>
<div id="left-side" class="ic-app-course-menu ic-sticky-on list-view"><ul id="section-tabs">
<li class="section"><a class="home" href="/courses/1">Home</a></li><li class="section"><a class="modules" href="/courses/1/modules">Modules</a></li>
<li class="section"><a class="assignments" href="/courses/1/assignments">Assignments</a></li><li class="section"><a class="grades" href="/courses/1/grades">Grades</a></li>
<li class="section"><a class="files" href="/courses/1/files">Files</a></li><li class="section"><a class="outcomes" href="/courses/1/outcomes">Outcomes</a></li>
<li class="section"><a class="conferences" href="/courses/1/conferences">Conferences</a></li><li class="section"><a class="collaborations" href="/courses/1/collaborations">Collaborations</a></li></ul></div>`;
  let main = '';
  let side = '';
  if ((p === '/' || p === '/dashboard') && url.searchParams.get('view') === 'list') {
    // Canvas's List View: its planner in the main column, its toolbar in the title row, no cards drawn.
    main = `<div id="dashboard_header_container" class="ic-Dashboard-header"><div class="ic-Dashboard-header__layout"><h1 class="ic-Dashboard-header__title">Dashboard</h1><div id="dashboard-planner-header" class="CanvasPlanner__HeaderContainer"><div class="PlannerHeader"><button id="planner-today-btn" type="button">Today</button><button type="button" data-testid="add-to-do-button"><svg/></button></div></div></div></div><div id="DashboardCard_Container"></div>
<div id="dashboard-planner"><div class="PlannerApp"><div class="planner-day"><h2>Today</h2><p>Nothing Planned Yet</p></div></div></div>`;
    side = `<div class="ic-sidebar-logo"><img class="ic-sidebar-logo__image" alt="School" src="data:image/gif;base64,R0lGODlhAQABAAAAACw="></div>`;
  } else if (p === '/' || p === '/dashboard') {
    main = `<div id="dashboard_header_container" class="ic-Dashboard-header"><div class="ic-Dashboard-header__layout"><h1 class="ic-Dashboard-header__title">Dashboard</h1><div id="dashboard-planner-header" class="CanvasPlanner__HeaderContainer" style="display: none;"></div></div></div><div id="dashboard-planner" class="StudentPlanner__Container" style="display: none"></div><div id="DashboardCard_Container">
<div class="ic-DashboardCard__box"><div class="ic-DashboardCard__box__container">
<div class="ic-DashboardCard" data-testid="dashboard-card"><div class="ic-DashboardCard__header"><a class="ic-DashboardCard__link" href="/courses/1"><div class="ic-DashboardCard__header_hero" style="background-color: rgb(255, 111, 97); opacity: 0.6;"></div><div class="ic-DashboardCard__header_content"><h3 class="ic-DashboardCard__header-title ellipsis"><span style="color: rgb(255, 111, 97);">AP Physics C</span></h3><div class="ic-DashboardCard__header-subtitle">PHYS-C</div></div></a></div><nav class="ic-DashboardCard__action-container"><a class="ic-DashboardCard__action announcements" href="/courses/1/announcements"><div class="ic-DashboardCard__action-layout"><svg name="IconAnnouncement" width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg></div></a><a class="ic-DashboardCard__action assignments" href="/courses/1/assignments"><div class="ic-DashboardCard__action-layout"><svg name="IconAssignment" width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg></div><span class="ic-DashboardCard__action-badge">0</span></a></nav></div>
<div class="ic-DashboardCard" data-testid="dashboard-card"><div class="ic-DashboardCard__header"><a class="ic-DashboardCard__link" href="/courses/2"><div class="ic-DashboardCard__header_hero" style="background-color: rgb(87, 199, 155); opacity: 0.6;"></div><div class="ic-DashboardCard__header_content"><h3 class="ic-DashboardCard__header-title ellipsis"><span style="color: rgb(87, 199, 155);">English 11</span></h3><div class="ic-DashboardCard__header-subtitle">ENG-11</div></div></a></div><nav class="ic-DashboardCard__action-container"></nav></div>
</div></div></div>`;
    side = `<div class="ic-sidebar-logo"><img class="ic-sidebar-logo__image" alt="School" src="data:image/gif;base64,R0lGODlhAQABAAAAACw="></div>
<div class="Sidebar__TodoListContainer"><div data-testid="ToDoSidebar"><h2 class="todo-list-header">To Do</h2><ul><li class="ToDoSidebarItem"><span class="ToDoSidebarItem__Title">Turn in Problem Set 7</span></li></ul></div></div>
<ul class="right-side-list to-do-list"><li class="todo"><a href="#">Turn in Problem Set 7 <span class="todo-badge">1</span></a></li></ul>
<div class="events_list coming_up"><h2>Coming Up</h2><ul class="right-side-list events">
<li class="event"><a href="#"><i class="icon-assignment"></i><div class="event-details"><b class="event-details__title">Problem Set 7</b><p>50 points • Sep 5 at 8:03am</p></div></a></li>
<li class="event"><a href="#"><i class="icon-assignment"></i><div class="event-details"><b class="event-details__title">Lab writeup</b><p>50 points • Sep 6</p></div></a></li>
<li class="event"><a href="#"><i class="icon-assignment"></i><div class="event-details"><b class="event-details__title">Problem Set 8</b><p>50 points • Sep 11</p></div></a></li>
<li class="event" style="display: none;"><a href="#"><i class="icon-assignment"></i><div class="event-details"><b class="event-details__title">Rhetorical analysis</b><p>60 points • Sep 14</p></div></a></li>
<li class="event" style="display: none;"><a href="#"><i class="icon-assignment"></i><div class="event-details"><b class="event-details__title">Unit 4 check</b><p>6 points • Sep 15</p></div></a></li>
</ul><a class="more_link" href="#">2 more…</a></div>
<div class="events_list recent_feedback"><h2>Recent Feedback</h2><ul class="right-side-list events"><li class="event"><a class="recent_feedback_icon" href="/courses/1/assignments/6/submissions/1"><i class="icon-check"></i><div class="event-details"><b class="event-details__title recent_feedback_title">Problem Set 6</b><p class="event-details__context">PHYS-C-1</p><p><strong>41 out of 50</strong></p><p>"Redo part (c) and resubmit."</p></div><div class="clear"></div></a></li>
<li class="event" style="display: none;"><a class="recent_feedback_icon" href="#"><i class="icon-check"></i><div class="event-details"><b class="event-details__title recent_feedback_title">Older feedback</b><p class="event-details__context">PHYS-C-1</p></div></a></li></ul><a class="more_link" href="#">1 more…</a></div>
<div><a href="/grades" class="Button button-sidebar-wide">View Grades</a></div>`;
  } else if (/\/courses\/\d+\/modules/.test(p)) {
    // Real Canvas (the sandbox, 2026-09-18): the bar with its one button after
    // the h1; a status mark at the right of a row (a green check, an orange
    // circle); the header's three marks, one shown by the module's state; a
    // locked module whose items Canvas fades to half and titles with `.locked_title`.
    main = `<h1>Modules</h1><div class="header-bar"><div class="header-bar-right header-bar__module-layout"><div class="header-bar-right__buttons"><button class="btn" id="expand_collapse_all" aria-expanded="true" data-expand="false" aria-label="Collapse All Modules">Collapse All</button></div></div></div>
<div id="context_modules_sortable_container" class="item-group-container"><div id="context_modules" class="ig-list">
<div class="context_module started has_requirements"><div class="ig-header header"><h2 class="screenreader-only">Unit 4 — Rotation</h2><span role="button" tabindex="0" class="ig-header-title collapse_module_link ellipsis" aria-expanded="true"><i class="icon-mini-arrow-down"></i><span class="name">Unit 4 — Rotation</span></span><span role="button" tabindex="0" class="ig-header-title expand_module_link ellipsis" aria-expanded="false"><i class="icon-mini-arrow-right"></i><span class="name ellipsis">Unit 4 — Rotation</span></span><div class="ig-header-admin"><div class="completion_status"><i class="icon-check complete_icon" title="Completed"></i><i class="icon-minimize in_progress_icon" title="Started"></i><i class="icon-lock locked_icon" title="Locked"></i></div></div></div>
<ul class="ig-list items context_module_items">
<li class="context_module_item indent_0"><div class="ig-row ig-published student-view"><div class="ig-info"><a class="ig-title" href="#">Rotation: the short version</a><div class="ig-details"><div class="ig-details__item"><span class="completion_requirement">View</span></div></div></div><div class="module-item-status-icon"><i class="icon-check" title="Completed" aria-label="Completed"></i></div></div></li>
<li class="context_module_item indent_1"><div class="ig-row ig-published student-view with-completion-requirements"><div class="ig-info"><a class="ig-title" href="#">Problem Set 7</a><div class="ig-details"><div class="ig-details__item"><span class="due_date_display">Sep 5 at 8:03am</span></div><div class="ig-details__item"><span class="completion_requirement">Submit</span></div></div></div><div class="module-item-status-icon"><i class="icon-minimize" title="This assignment is overdue" aria-label="This assignment is overdue"></i></div></div></li>
<li class="context_module_item indent_1"><div class="ig-row ig-published student-view"><div class="ig-info"><a class="ig-title" href="#">Unit 4 concept check</a><div class="ig-details"><div class="ig-details__item"><span class="due_date_display">Sep 8 at 5:03am</span></div></div></div></div></li>
</ul></div>
<div class="context_module locked"><div class="ig-header header"><h2 class="screenreader-only">Unit 5 — Oscillation</h2><span role="button" tabindex="0" class="ig-header-title collapse_module_link ellipsis" aria-expanded="true"><i class="icon-mini-arrow-down"></i><span class="name">Unit 5 — Oscillation</span></span><span role="button" tabindex="0" class="ig-header-title expand_module_link ellipsis" aria-expanded="false"><i class="icon-mini-arrow-right"></i><span class="name ellipsis">Unit 5 — Oscillation</span></span><div class="ig-header-admin"><div class="completion_status"><i class="icon-check complete_icon" title="Completed"></i><i class="icon-minimize in_progress_icon" title="Started"></i><i class="icon-lock locked_icon" title="Locked"></i></div></div></div><ul class="ig-list items context_module_items"><li class="context_module_item indent_0"><div class="ig-row"><div class="ig-info"><span class="item_name"><a class="title" href="#">Read: Hooke's law</a><span class="title locked_title">Read: Hooke's law</span></span></div></div></li></ul></div>
</div></div>`;
  } else if (/^\/courses\/\d+\/?$/.test(p)) {
    // A course home: the modules as the front page, Canvas's own To Do beside it.
    main = `<div id="course_home_content"><h2 class="screenreader-only">Course home</h2><div id="context_modules" class="ig-list"><div class="context_module"><div class="ig-header header"><h2 class="ig-header-title"><span class="name">Unit 4 — Rotation</span></h2></div></div></div></div>`;
    side = `<div id="course_show_secondary"><div class="course-options"><a class="btn button-sidebar-wide" id="view_course_stream_btn" href="#">View Course Stream</a></div>
<h2 class="todo-list-header">To Do</h2><ul class="right-side-list to-do-list"><li class="todo"><a href="#">Turn in Problem Set 7 <span class="todo-badge">1</span></a></li></ul></div>`;
  } else if (/^\/courses\/\d+\/assignments\/?$/.test(p)) {
    // The assignments index (the sandbox, 2026-09-18): an InstUI search and the
    // Show by radio group in the bar; three groups; an unscored row says "-/15 pts".
    main = ASSIGNMENTS_INDEX;
  } else if (/^\/courses\/\d+\/quizzes\/?$/.test(p)) {
    // The quizzes index: a jQuery search in the bar, one group, one row with four
    // details; `?empty=1` shows Canvas's "No quizzes found" row instead.
    main = quizzesIndex(q.get('empty') === '1');
  } else if (/^\/courses\/\d+\/announcements\/?$/.test(p)) {
    // The announcements index: an InstUI heading inside a screen-reader span,
    // a filter select, a search, Mark All as Read; two rows, the first unread.
    main = ANNOUNCEMENTS_INDEX;
  } else if (/\/courses\/\d+\/assignments\/\d+/.test(p)) {
    main = `<div id="assignment_show"><h1 id="assignment_head">Problem Set 7</h1><div class="user_content"><p>Read the chapter.</p>
<p><span style="color: #000000; font-family: Calibri;">This paragraph came from Word.</span></p>
<p><span style="color: windowtext;">So did this one.</span></p>
<p><span style="background-color:#ffff00">Highlighted, not black.</span></p>
<table><tr><td style="color: #c00000">A red cell the teacher meant</td></tr></table></div>
<div class="submit_assignment"><button type="button" class="btn btn-primary" id="assignment_submit">Start Assignment</button></div>
<div id="submit_assignment"><form id="submit_online_text_entry_form" method="post" action="${p}/submissions"><textarea name="submission[body]"></textarea><button type="submit" class="btn btn-primary" id="submit_text_entry">Submit Assignment</button></form></div></div>`;
  } else if (/\/courses\/\d+\/grades/.test(p)) {
    // Real Canvas: Print Grades in the title row; the right column says the
    // total a second time, offers Show All Details and explains what-if.
    main = `<div id="grade-summary-content"><div id="print-grades-container" class="ic-Action-header"><div class="ic-Action-header__Primary"><h1 class="ic-Action-header__Heading">Grades for Alex Rivera</h1></div><div id="print-grades-button-container" class="ic-Action-header__Secondary"><a role="button" id="print-grades-button" class="Button print-grades icon-printer" href="#">Print Grades</a></div></div><div id="assignments"><table id="grades_summary"><thead><tr><th>Name</th><th>Due</th><th>Score</th></tr></thead>
<tbody><tr class="student_assignment"><th class="title">Problem Set 6</th><td class="due">Sep 1</td><td class="assignment_score"><span class="grade">41</span><span class="possible points_possible">/ 50</span></td></tr></tbody></table></div>
<div id="student-grades-final">Total: 82%</div></div>`;
    side = `<div id="student-grades-right-content"><div class="student_assignment final_grade">Total: <span class="grade">82%</span> (<span class="letter_grade">B-</span>)</div><div id="student-grades-show-all" class="show_all_details"><button type="button" class="Button" id="show_all_details_button">Show All Details</button></div><p>You can view your grades based on What-If scores so that you know how grades will be affected by upcoming or resubmitted assignments.</p></div>`;
  } else if (/\/courses\/\d+\/external_tools\//.test(p)) {
    main = `<h1>Tool</h1><div class="tool_content_wrapper"><iframe id="tool_content" src="about:blank" title="tool"></iframe></div>`;
  } else if (/^\/login/.test(p)) {
    return `<!doctype html><html><head><title>Log in</title></head><body class="ic-Login-body"><div id="application"><div class="ic-Login"><form id="login_form"><input id="pseudonym_session_unique_id"><input id="pseudonym_session_password" type="password"><input type="submit" name="commit" value="Log In"></form></div></div></body></html>`;
  } else if (/\/courses\/\d+\/quizzes\/\d+/.test(p)) {
    main = `<h1>Quiz - Safety</h1><div class="quiz-header"><ul class="quiz_details"><li>Due <span>No due date</span></li></ul></div>
<div class="box"><p>Take the quiz when ready.</p><a href="/courses/1/quizzes/1/take" class="btn btn-primary">Take the Quiz</a></div>`;
  } else if (/^\/courses\/\d+/.test(p)) {
    main = `<h1>AP Physics C</h1><p>Welcome.</p>`;
  } else if (p === '/calendar') {
    main = `<div id="calendar_header" class="calendar_header"><div class="header-bar"><button class="btn navigate_today">Today</button><h2 class="navigation_title">September 2026</h2></div></div>
<div id="calendar-app"><div class="fc-view"><table><thead><tr><th class="fc-widget-header fc-day-header">Mon</th><th class="fc-widget-header fc-day-header">Tue</th></tr></thead>
<tbody class="fc-widget-content"><tr><td class="fc-day fc-widget-content">1<a class="fc-event" style="background-color: #fff; border: 1px solid rgb(255, 111, 97); color: rgb(255, 111, 97)"><span class="fc-time">5:03a</span> <span class="fc-title">Problem Set 7</span></a></td><td class="fc-day fc-widget-content">2</td></tr></tbody></table></div></div>`;
    side = `<div id="calendar-list"><h2>Calendars</h2><ul class="context-list"><li class="context"><a href="#">AP Physics C</a></li></ul></div>`;
  } else if (p === '/grades') {
    // The student's own Grades page: a plain h1, two headings, two tables.
    main = `<h1>Grades</h1><h2>Courses I'm Taking</h2><table class="course_details student_grades"><tbody><tr><td class="course"><a href="/courses/1/grades">AP Physics C</a></td><td class="percent">82%</td></tr></tbody></table>
<h2>Courses I'm Teaching</h2><table class="course_details teacher_grades"><tbody><tr><td class="course">Intro Lab (TA)</td><td class="percent">no grades</td></tr></tbody></table>`;
  } else if (p === '/courses') {
    main = `<div class="header-bar"><div class="ic-Action-header"><h1 class="ic-Action-header__Heading">All Courses</h1></div></div>
<table id="my_courses_table" class="ic-Table ic-Table--bordered course-list-table"><thead><tr><th class="course-list-column-header">Course</th><th>Term</th></tr></thead>
<tbody><tr class="course-list-table-row"><td><a href="/courses/1">AP Physics C</a></td><td>Fall 2026</td></tr></tbody></table>
<h2>Past Enrollments</h2>
<table id="past_enrollments_table" class="ic-Table ic-Table--bordered course-list-table"><thead><tr><th class="course-list-column-header">Course</th><th>Term</th></tr></thead>
<tbody><tr class="course-list-table-row"><td><a href="/courses/9">Intro Chemistry</a></td><td>Spring 2025</td></tr></tbody></table>
<h2>Future Enrollments</h2>
<table id="future_enrollments_table" class="ic-Table ic-Table--bordered course-list-table"><thead><tr><th class="course-list-column-header">Course</th><th>Term</th></tr></thead>
<tbody><tr class="course-list-table-row"><td><a href="/courses/8">Organic Chemistry</a></td><td>Spring 2027</td></tr></tbody></table>
<p><span class="css-k2x9q1-text">Nickname</span> <a class="css-4h7pq3-view-link" href="/courses/1">Open</a></p>`;
  } else {
    main = `<h1>Canvas</h1><p>Fake Canvas for Prepkin tests.</p>`;
  }
  const inCourse = /^\/courses\/\d+/.test(p);
  const editor = q.get('rce') === '1' ? '<div class="rce-wrapper"><textarea aria-label="Rich Content Editor"></textarea></div>' : '';
  return `<!doctype html><html><head><title>Dashboard</title><script>ENV = ${env};</script>
<style>body{margin:0;font-family:Lato,sans-serif} .ic-DashboardCard__box__container{margin:-36px 0 0 -36px} .ic-DashboardCard{display:inline-block;width:262px;margin:36px 0 0 36px;background:#fff;border-radius:4px;vertical-align:top} .ic-DashboardCard__header_hero{height:146px} .ic-DashboardCard__header_content{padding:12px 18px 0;height:80px;overflow:hidden;background:#fff} .ig-title{color:#273540} .ic-DashboardCard__action-container{display:flex;height:2.5rem} #left-side{width:192px;float:left} #right-side{width:288px;float:right} .ig-header{background:#f5f5f5;padding:8px} .context_module{margin-bottom:24px} .context_module.locked .context_module_item{opacity:.5} .context_module.locked .context_module_item .title{display:none} .context_module.locked .context_module_item .locked_title{display:inline} .module-item-status-icon i.icon-check,.completion_status .complete_icon{color:#03893d} .module-item-status-icon i.icon-minimize,.completion_status .in_progress_icon{color:#f06e26} .context_module .completion_status i{display:none} .context_module .expand_module_link{display:none} .screenreader-only{position:absolute;left:-10000px} .context_module.started .completion_status .in_progress_icon,.context_module.locked .completion_status .locked_icon{display:inline} .item-group-condensed{padding:9px 0} .btn{display:inline-block;padding:8px 14px;border:1px solid transparent;border-radius:3px;background:#f5f5f5;color:#2d3b45} .btn-primary{background:#0374B5;border-color:#0374B5;color:#fff}</style></head>
<body class="${bodyClass}"><div id="application" class="ic-app">${chrome}
<div id="wrapper" class="ic-Layout-wrapper"><div id="main" class="ic-Layout-columns">${inCourse ? courseNav : ''}
<div id="content-wrapper" class="ic-Layout-contentWrapper"><div id="content" class="ic-Layout-contentMain">${editor}${main}</div></div>
${side ? `<div id="right-side-wrapper" class="ic-app-main-content__secondary"><aside id="right-side">${side}</aside></div>` : ''}
</div></div></div></body></html>`;
}

// MARK: - Bridge

const CODE_RE = /^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/;
const sha = (t) => crypto.createHash('sha256').update(t ?? '').digest('hex');
const token = () => crypto.randomBytes(32).toString('hex');

class FakeBridge {
  constructor() { this.reset(); }
  reset() { this.rows = new Map(); this.skew = 0; this.down = false; this.legacy = false; this.calls = []; }
  now() { return Date.now() + this.skew; }

  call(fn, body) {
    this.calls.push({ fn, body });
    // The Supabase project before schema.sql was re-run: the token functions do not exist.
    if (this.legacy && ['claim_code', 'bind_writer', 'fetch_state'].includes(fn)) {
      return { status: 404, body: JSON.stringify({ code: 'PGRST202', message: `Could not find the function public.${fn}` }) };
    }
    const raise = (message) => ({ status: 400, body: JSON.stringify({ code: 'P0001', message }) });
    const ok = (value) => ({ status: 200, body: JSON.stringify(value === undefined ? null : value) });
    const done = () => ({ status: 204, body: '' });
    const live = (row) => row && row.expires_at > this.now();
    const code = body.p_code;
    const row = this.rows.get(code);
    switch (fn) {
      case 'claim_code': {
        if (!CODE_RE.test(code ?? '')) return raise('bad code');
        if (live(row)) return ok(null);
        const t = token();
        this.rows.set(code, { owner_hash: sha(t), writer_hash: null, claimable_until: this.now() + 15 * 60_000,
          todo: [], state: {}, expires_at: this.now() + 30 * DAY });
        return ok(t);
      }
      case 'bind_writer': {
        if (!CODE_RE.test(code ?? '')) return raise('bad code');
        if (!row || row.writer_hash || row.claimable_until <= this.now() || !live(row)) return ok(null);
        const t = token();
        row.writer_hash = sha(t);
        return ok(t);
      }
      case 'push_todo': {
        if (Buffer.byteLength(JSON.stringify(body.p_todo ?? null)) > 262144) return raise('payload too large');
        if (!live(row) || row.writer_hash !== sha(body.p_token)) return raise('not paired');
        row.todo = body.p_todo; row.expires_at = this.now() + 30 * DAY;
        return done();
      }
      case 'fetch_state':
        return ok(live(row) && row.writer_hash === sha(body.p_token) ? row.state : null);
      case 'fetch_todo':
        return ok(live(row) && row.owner_hash === sha(body.p_token) ? row.todo : null);
      case 'push_state': {
        if (Buffer.byteLength(JSON.stringify(body.p_state ?? null)) > 32768) return raise('state too large');
        if (!live(row) || row.owner_hash !== sha(body.p_token)) return raise('not paired');
        row.state = body.p_state; row.expires_at = this.now() + 30 * DAY;
        return done();
      }
      case 'delete_pairing':
        if (row && row.owner_hash === sha(body.p_token)) this.rows.delete(code);
        return done();
      default:
        return { status: 404, body: JSON.stringify({ code: 'PGRST202', message: `Could not find the function public.${fn}` }) };
    }
  }
}

// MARK: - Server

class FakeServer {
  /// `upstream`: a real Canvas to stand in front of (e.g. http://127.0.0.1:3000,
  /// the SSH tunnel to the sandbox). Everything that is not the bridge or a
  /// control call is passed through, so the real Canvas sits on the same
  /// https origin the extension already trusts. `record`: a folder to write
  /// every proxied API reply into, one JSON file per request, for the fixture
  /// diff against the fake's own shapes.
  constructor({ upstream = null, record = null } = {}) {
    this.worlds = {};
    this.bridge = new FakeBridge();
    this.log = [];
    this.upstream = upstream;
    this.record = record;
    // A school's Theme Editor files (a folder from test/schools/), put into
    // every proxied page where Canvas itself puts them: the stylesheets at the
    // end of <head>, the script deferred at the end of <body>.
    this.theme = null;
    if (record) fs.mkdirSync(record, { recursive: true });
  }

  world(host) {
    return (this.worlds[host] ??= blankWorld());
  }

  async start(port = 8443) {
    const cert = selfSignedCert();
    this.server = https.createServer(cert, (req, res) => this.handle(req, res));
    await new Promise((r) => this.server.listen(port, r));
    this.port = port;
    return this;
  }

  async stop() {
    await new Promise((r) => this.server.close(r));
  }

  handle(req, res) {
    const url = new URL(req.url, `https://${req.headers.host}`);
    const host = url.hostname;
    let raw = '';
    req.on('data', (c) => { raw += c; });
    req.on('end', () => {
      let body = {};
      if (raw) { try { body = JSON.parse(raw); } catch { body = {}; } } // a posted form is not JSON
      if (url.pathname.startsWith('/__theme/')) return this.themeFile(url, res);
      if (url.pathname.startsWith('/__')) return this.control(url, body, res);
      if (url.pathname.startsWith('/rest/v1/rpc/')) {
        if (this.bridge.down) return req.socket.destroy();
        const out = this.bridge.call(url.pathname.slice('/rest/v1/rpc/'.length), body);
        res.writeHead(out.status, { 'Content-Type': 'application/json' });
        return res.end(out.body);
      }
      this.log.push({ host, path: url.pathname + url.search });
      if (this.upstream) return this.proxy(req, url, raw, res);
      const w = this.world(host);
      const metered = w.bucket && url.pathname.startsWith('/api/v1/');
      if (metered && !bucketAdmit(w)) {
        // Word for word what Canvas answers (request_throttle.rb#rate_limit_exceeded).
        res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8', 'X-Rate-Limit-Remaining': '0.0' });
        return res.end('403 Forbidden (Rate Limit Exceeded)\n');
      }
      const out = canvasRoute(req, url, w);
      if (out.destroy) return req.socket.destroy();
      if (out.hang) return; // never answer: a school behind a dead SSO hop
      if (this.theme && /html/.test(String(out.headers?.['Content-Type'] ?? ''))) out.body = this.dress(out.body);
      setTimeout(() => {
        if (metered) bucketRelease(w);
        res.writeHead(out.status, out.headers); res.end(out.body);
      }, w.delayMs || 0);
    });
  }

  /// Pass one request to the real Canvas and hand its answer back untouched,
  /// except that absolute links are rewritten onto this origin so the
  /// extension's paging (which refuses another host) and `html_url` line up.
  proxy(req, url, raw, res) {
    const target = new URL(url.pathname + url.search, this.upstream);
    const headers = { ...req.headers, host: target.host, 'accept-encoding': 'identity',
      'x-forwarded-proto': 'https', 'x-forwarded-host': req.headers.host };
    const up = http.request(target, { method: req.method, headers }, (r) => {
      const chunks = [];
      r.on('data', (c) => chunks.push(c));
      r.on('end', () => {
        let body = Buffer.concat(chunks);
        const mine = `https://${req.headers.host}`;
        const theirs = [`http://${target.host}`, `https://${target.host}`];
        const h = { ...r.headers };
        delete h['content-length'];
        delete h['transfer-encoding'];
        for (const k of ['link', 'location']) {
          if (h[k]) for (const t of theirs) h[k] = h[k].split(t).join(mine);
        }
        const type = String(h['content-type'] ?? '');
        if (/json|html|javascript|text/.test(type)) {
          let text = body.toString('utf8');
          for (const t of theirs) text = text.split(t).join(mine);
          if (this.theme && /html/.test(type)) text = this.dress(text);
          body = Buffer.from(text, 'utf8');
        }
        if (this.record && url.pathname.startsWith('/api/v1/')) {
          const name = (url.pathname + url.search).replace(/[^a-z0-9]+/gi, '_').slice(0, 150);
          fs.writeFileSync(path.join(this.record, `${name}.json`),
            JSON.stringify({ path: url.pathname + url.search, status: r.statusCode, link: h.link ?? null,
              body: /json/.test(type) ? JSON.parse(body.toString('utf8').replace(/^while\(1\);/, '')) : null }, null, 2));
        }
        h['content-length'] = String(body.length);
        res.writeHead(r.statusCode, h);
        res.end(body);
      });
    });
    up.on('error', (e) => { res.writeHead(502); res.end(`upstream: ${e.message}`); });
    if (raw) up.write(raw);
    up.end();
  }

  /// The school's files into a real Canvas page, where the Theme Editor puts
  /// them (app/views/layouts/_head.html.erb, _foot.html.erb).
  dress(html) {
    const has = (f) => fs.existsSync(path.join(this.theme, f));
    const head = [
      has('variables.css') ? '<link rel="stylesheet" href="/__theme/variables.css">' : '',
      has('custom.css') ? '<link rel="stylesheet" href="/__theme/custom.css">' : '',
    ].join('');
    const foot = has('custom.js') ? '<script defer src="/__theme/custom.js"></script>' : '';
    return html.replace(/<\/head>/i, `${head}</head>`).replace(/<\/body>/i, `${foot}</body>`);
  }

  themeFile(url, res) {
    const name = url.pathname.slice('/__theme/'.length);
    const file = this.theme && /^[\w.-]+(\/[\w.-]+)?$/.test(name) ? path.join(this.theme, name) : null;
    if (!file || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
    const type = name.endsWith('.css') ? 'text/css' : 'application/javascript';
    res.writeHead(200, { 'Content-Type': `${type}; charset=utf-8`, 'Cache-Control': 'no-store' });
    res.end(fs.readFileSync(file));
  }

  control(url, body, res) {
    const send = (v) => { res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(v ?? null)); };
    switch (url.pathname) {
      case '/__reset':
        this.worlds = {}; this.bridge.reset(); this.log = [];
        return send(true);
      case '/__world':
        Object.assign(this.world(body.host), body.world);
        return send(true);
      case '/__log':
        return send(this.log);
      case '/__log/clear':
        this.log = [];
        return send(true);
      case '/__bucket':
        return send(bucketState(this.world(body.host)));
      case '/__theme':
        this.theme = body.dir ?? null;
        return send(true);
      case '/__bridge':
        Object.assign(this.bridge, body);
        return send(true);
      case '/__bridge/rows':
        return send(Object.fromEntries(this.bridge.rows));
      default:
        return send(null);
    }
  }
}

module.exports = { FakeServer, FakeBridge, blankWorld, DAY };

if (require.main === module) {
  // node test/fake-canvas.js [port] [--upstream http://127.0.0.1:3000] [--record dir]
  const argv = process.argv.slice(2);
  const opt = (k) => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : null; };
  new FakeServer({ upstream: opt('--upstream'), record: opt('--record') })
    .start(Number(argv.find((a) => /^\d+$/.test(a))) || 8443).then((s) => {
      console.log(`fake bridge on https://localhost:${s.port}` + (s.upstream ? `, Canvas proxied from ${s.upstream}` : ', fake Canvas'));
    });
}
