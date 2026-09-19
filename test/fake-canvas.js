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
  // Pages added by the parallel sessions of 2026-09-18, each in its own function
  // below, tried first so nobody edits the chain that follows.
  for (const extra of [pageC, pageD, pageE, pageF]) {
    const r = extra(p, url);
    if (r) { main = r.main ?? ''; side = r.side ?? ''; }
  }
  if (main) {
  } else if ((p === '/' || p === '/dashboard') && url.searchParams.get('view') === 'list') {
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

// Each parallel session (2026-09-18) fills its own function with the pages it
// needs, trimmed from a sandbox dump: return { main, side } or null. Edit only
// inside your own marker pair.
// ---- Session C pages (course home, page, assignment, quiz) ----
// Trimmed from the sandbox (2026-09-19). The course home is course 1's, as a
// student sees it: the h1 screen-reader-only, Collapse All in a bar inside
// #course_home_content, a module carrying both `item-group-condensed` and
// `context_module` (real Canvas gives it both), three wide buttons and Canvas's
// To Do and Recent Feedback in the sidebar. The assignment (12), the quiz (2)
// and the wiki page are on ids the older fixtures do not use.
const C_FOOTER = (prev) => `<div class="module-sequence-padding"></div>
<div class="module-sequence-footer" role="navigation"><div class="module-sequence-footer-content">
<div class="module-sequence-footer-left">${prev ? '<span class="module-sequence-footer-button--previous"><span class="css-1ihz85b-position"><a dir="ltr" href="/courses/1/modules/items/1" class="css-1sec0gm-view--inlineBlock-baseButton"><span class="css-1ta5ds2-baseButton__content"><span class="css-11xkk0o-baseButton__children"><span dir="ltr" class="css-p0uk0p-view--flex-flex"><svg name="IconMiniArrowStart" viewBox="0 0 1920 1920" width="1em" height="1em" role="presentation" class="css-1xnn9jb-inlineSVG-svgIcon"><path d="M694 926c-27 19-27 49 0 68l510 351c27 19 49 7 49-26V601c0-33-22-45-49-26L694 926Z"/></svg> Previous</span></span></span></a></span></span>' : ''}</div>
<div class="module-sequence-footer-right"><span class="module-sequence-footer-button--next"><span class="css-1ihz85b-position"><a dir="ltr" href="/courses/1/modules/items/3" class="css-1sec0gm-view--inlineBlock-baseButton"><span class="css-1ta5ds2-baseButton__content"><span class="css-11xkk0o-baseButton__children"><span dir="ltr" class="css-p0uk0p-view--flex-flex">Next <svg name="IconMiniArrowEnd" viewBox="0 0 1920 1920" width="1em" height="1em" role="presentation" class="css-1xnn9jb-inlineSVG-svgIcon"><path d="M1226 926c27 19 27 49 0 68l-510 351c-27 19-49 7-49-26V601c0-33 22-45 49-26l510 351Z"/></svg></span></span></span></a></span></span></div>
</div></div>`;
const C_MODULE = (id, name, cls, items) => `<div class="item-group-condensed context_module ${cls}" id="context_module_${id}"><div class="ig-header header" id="${id}"><h2 class="screenreader-only">${name}</h2>
<span role="button" tabindex="0" class="ig-header-title collapse_module_link ellipsis" aria-controls="context_module_content_${id}" aria-expanded="true"><i class="icon-mini-arrow-down"></i><span class="name">${name}</span></span>
<span role="button" tabindex="0" class="ig-header-title expand_module_link ellipsis" aria-controls="context_module_content_${id}" aria-expanded="false"><i class="icon-mini-arrow-right"></i><span class="name ellipsis">${name}</span></span>
<div class="prerequisites"><div class="prerequisites_message">Prerequisites: </div></div>
<div class="module_header_items"><div class="ig-header-admin"><div class="requirements_message"><ul class="pill"><li>Complete All Items</li></ul></div><div class="completion_status"><i class="icon-check complete_icon"></i><i class="icon-minimize in_progress_icon"></i><i class="icon-lock locked_icon"></i></div></div></div></div>
<div class="content" id="context_module_content_${id}"><ul class="ig-list items context_module_items">${items}</ul></div></div>`;
const C_ITEM = (id, cls, indent, title, details, status) => `<li id="context_module_item_${id}" class="context_module_item student-view ${cls} indent_${indent} rendered"><div class="ig-row with-completion-requirements ig-published student-view">
<span class="type_icon" role="none"><span class="ig-type-icon"><i class="icon-document"></i></span></span>
<div class="ig-info"><div class="module-item-title"><span class="item_name"><a class="ig-title title item_link" href="/courses/1/modules/items/${id}">${title}</a><span class="title locked_title">${title}</span></span></div>
<div class="ig-details">${details}</div></div>${status ? `<div class="module-item-status-icon"><i class="${status}"></i></div>` : ''}</div></li>`;
function pageC(p, url) {
  if (/^\/courses\/1\/?$/.test(p)) {
    const main = `<h1 class="screenreader-only">AP Physics C: Mechanics</h1>
<div id="course_home_content"><div class="screenreader-only">AP Physics C: Mechanics</div><h2 class="context-modules-title screenreader-only">Course Modules</h2>
<div class="header-bar"><div class="header-bar-right header-bar__module-layout"><div class="header-bar-right__buttons"><button class="btn" id="expand_collapse_all" aria-expanded="true" data-expand="false" aria-label="Collapse All Modules">Collapse All</button></div></div></div>
<div class="item-group-container" id="context_modules_sortable_container"><div id="context_modules" class="ig-list">
${C_MODULE(1, 'Unit 4 — Rotation', 'has_requirements student-view started', [
  C_ITEM(1, 'wiki_page completed_item', 0, 'Rotation: the short version', '<div class="requirement-description ig-details__item"><span class="completion_requirement"><span class="requirement_type must_view_requirement"><span class="unfulfilled">View</span><span class="fulfilled">Viewed</span></span></span></div>', 'icon-check'),
  C_ITEM(2, 'assignment', 1, 'Problem Set 7', '<div class="ig-details__item"><span class="due_date_display">Sep 5 at 5:03am</span></div><div class="ig-details__item"><span class="points_possible_display">50 pts</span></div><div class="requirement-description ig-details__item"><span class="completion_requirement"><span class="requirement_type must_submit_requirement"><span class="unfulfilled">Submit</span><span class="fulfilled">Submitted</span></span></span></div>', 'icon-minimize'),
].join(''))}
${C_MODULE(2, 'Unit 5 — Oscillation', 'locked', C_ITEM(3, 'wiki_page', 0, "Read: Hooke's law", '', ''))}
</div></div></div>`;
    const side = `<div id="course_show_secondary"><div class="course-options"><a id="view_course_stream_btn" class="btn button-sidebar-wide" href="/courses/1?view=feed"><i class="icon-stats"></i> View Course Stream</a></div>
<a class="btn button-sidebar-wide" href="/calendar?include_contexts=course_1"><i class="icon-calendar-day"></i> View Course Calendar</a>
<a id="view_course_notifications_btn" class="btn button-sidebar-wide" href="/courses/1?view=notifications"><i class="icon-unmuted"></i> View Course Notifications</a>
<div class="todo-list Sidebar__TodoListContainer"><div><h2 class="todo-list-header">To Do</h2><div data-testid="ToDoSidebar"><ul><li class="ToDoSidebarItem"><span class="ToDoSidebarItem__Title">Turn in Problem Set 7</span></li></ul></div></div></div></div>
<div class="events_list recent_feedback"><div class="h2 shared-space"><h2>Recent Feedback</h2></div><ul class="right-side-list events">
<li class="event"><a class="recent_feedback_icon" href="/courses/1/assignments/22/submissions/3"><i class="icon-check"></i><div class="event-details"><b class="event-details__title recent_feedback_title">In-class derivation check</b><p><strong>18 out of 20</strong></p></div><div class="clear"></div></a><div class="clear"></div></li>
<li class="event"><a class="recent_feedback_icon" href="/courses/1/assignments/21/submissions/3"><i class="icon-check"></i><div class="event-details"><b class="event-details__title recent_feedback_title">Problem Set 5: Kinematics</b><p>"Redo part (c) and resubmit."</p></div><div class="clear"></div></a><div class="clear"></div></li>
<li><a href="#" class="more_link">4 more…</a></li></ul></div>`;
    return { main, side };
  }
  if (/^\/courses\/1\/assignments\/12\/?$/.test(p)) {
    // A short description, a hand-in already marked; `?open=1` is the unsubmitted case (no Submission box).
    const marked = url.searchParams.get('open') !== '1';
    const main = `<div id="assignment_show" class="assignment content_underline_links"><div class="assignment-title"><div class="title-content"><h1 class="title">Problem Set 8: Angular Momentum</h1></div><div class="assignment-buttons"><button type="button" class="Button Button--primary submit_assignment_link">${marked ? 'New Attempt' : 'Start Assignment'}</button></div></div>
<ul class="student-assignment-overview"><li><span class="title">Due</span><span class="value"><span class="date_text"><span class="display_date">Sep 11</span> by <span class="display_time">5:03am</span></span></span></li><li><span class="title">Points</span><span class="value">50</span></li><li><span class="title">Submitting</span><span class="value">a text entry box</span></li><div class="clear"></div></ul>
<div class="clear"></div><div class="description user_content enhanced"><p>Read the chapter, then write a short response. Three paragraphs is plenty.</p><ul><li>State the claim.</li><li>Give one piece of evidence.</li><li>Say what it does not explain.</li></ul></div>
<div style="display: none;"><span class="timestamp">1789124629</span></div></div>
<div style="display: none;" id="submit_assignment"><form id="submit_online_text_entry_form" class="submit_assignment_form" action="/courses/1/assignments/12/submissions" method="post"><textarea name="submission[body]"></textarea><button type="button" class="cancel_button btn">Cancel</button><button type="submit" class="btn btn-primary">Submit Assignment</button></form></div>`;
    const side = marked ? `<div id="sidebar_content"><div class="details"><h2>Submission</h2><div class="header"><i class="icon-check"></i> Submitted!</div>
<div class="content"><span class="">Sep 5 at 5:14am</span><div><a href="/courses/1/assignments/12/submissions/3">Submission Details</a></div>
<div class="module"><div>Grade: 47 <span style="font-size: 0.8em;">(50 pts possible)</span></div><div>Graded Anonymously: no</div></div>
<div class="comments module"><h3>Comments: </h3><div class="comment"><div class="comment">Good, but part (b) is one step short.</div><div class="signature">Dr. Vega, Sep 6 at 9:12am</div></div></div></div></div></div>` : '';
    return { main, side };
  }
  if (/^\/courses\/1\/quizzes\/2\/?$/.test(p)) {
    // Six details (Available until among them), the lock explanation with its
    // prerequisites, a footer; `?open=1` is the unlocked quiz: Instructions and Take the Quiz.
    const isOpen = url.searchParams.get('open') === '1';
    const main = `<div id="quiz_show"><header class="quiz-header"><h1 id="quiz_title">Unit 4 concept check</h1><div class="row-fluid"><div id="quiz_details_wrapper"></div></div><div class="row-fluid">
<ul id="quiz_student_details"><li><span class="title">Due</span><span class="value"><span>Sep 8 at 5:03am</span></span></li><li><span class="title">Points</span><span class="value">6</span></li><li><span class="title">Questions</span><span class="value">3</span></li><li><span class="title">Available</span><span class="value"><span>Sep 1 at 12am - Sep 20 at 11:59pm</span></span></li><li><span class="title">Time Limit</span><span class="value">None</span></li><li><span class="title">Allowed Attempts</span><span class="value">Unlimited</span></li></ul>
${isOpen ? '<h2>Instructions</h2><div class="description user_content" role="region">Five questions on Hooke\'s law.</div></div><div class="take_quiz_button"><a class="btn btn-primary" id="take_quiz_link" role="button" href="/courses/1/quizzes/2/take">Take the Quiz</a></div>' : '</div>'}
${isOpen ? '' : `<div class="lock_explanation">This quiz is part of the module <b>Unit 4 — Rotation</b> and hasn't been unlocked yet.<br><div class="spinner"></div><a style="display: none;" class="module_prerequisites_fallback" href="/courses/1/modules#module_1">Visit the course modules page for information on how to unlock this content.</a><br><h2 style="margin-top: 15px;">Completion Prerequisites</h2>The following requirements need to be completed before this page will be unlocked:<ul id="module_prerequisites_list"><li class="module"><i></i><h3>Unit 4 — Rotation</h3><ul><li class="requirement"><a href="/courses/1/modules/items/2">Problem Set 7</a><div class="description">must submit the assignment</div></li><li class="requirement locked_requirement"><a href="/courses/1/modules/items/3" class="icon-lock">Unit 4 concept check</a><div class="description">must score at least a 4.0</div></li></ul></li></ul></div>`}
<div id="quiz-submission-version-table"></div></header><div id="assignment_external_tools"><div></div></div><div id="module_sequence_footer">${C_FOOTER(true)}</div></div>`;
    const side = `<div id="sidebar_content" class="rs-margin-bottom"><ul class="page-action-list" style="display:none;"><h2>Related Items</h2></ul></div>`;
    return { main, side };
  }
  if (/^\/courses\/1\/pages\/rotation-the-short-version\/?$/.test(p)) {
    // A page with a heading, prose, a wide table and a wide image: nothing may run past the sheet.
    const main = `<div id="wiki_page_show"><div class="header-bar-outer-container"><div class="sticky-toolbar"><div class="header-bar page-toolbar"><div class="page-toolbar-start"><div class="page-heading"><a class="btn view_all_pages" href="/courses/1/pages">View All Pages</a></div></div><div class="page-toolbar-end"><div class="blueprint-label"></div><div class="publishing"><div class="published"></div></div><div class="buttons"></div></div></div></div><div class="page-changed-alert" role="alert"></div></div>
<div id="direct-share-mount-point"></div>
<div class="show-content user_content clearfix enhanced"><h1 class="page-title">Rotation: the short version</h1><div id="todo-date-mount-point"></div>
<h2>What actually matters</h2><p>Three equations. That is the unit. Torque is force times lever arm, angular momentum is inertia times angular speed, and the second one is conserved when the first is zero.</p>
<h3>The table</h3><table style="width: 1400px; border-collapse: collapse;"><thead><tr><th>Quantity</th><th>Symbol</th><th>Unit</th><th>Linear twin</th></tr></thead><tbody><tr><td>Torque</td><td>τ</td><td>N·m</td><td>Force</td></tr><tr><td>Moment of inertia</td><td>I</td><td>kg·m²</td><td>Mass</td></tr></tbody></table>
<p><img src="data:image/gif;base64,R0lGODlhAQABAIAAAMLCwgAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==" width="1600" height="400" alt="A wide diagram"></p>
<div id="assign-to-mount-point"></div></div></div>
<div id="module_navigation_target"><div>${C_FOOTER(false)}</div></div>`;
    // Real Canvas keeps an empty aside on a wiki page (the space keeps the wrapper).
    return { main, side: ' ' };
  }
  return null;
}
// ---- end Session C ----
// ---- Session D pages (all courses, files, people, syllabus) ----
// Trimmed from the sandbox (2026-09-18) into test/d-pages/. The real All
// Courses markup answers `/courses?full=1` only, so the chain's flat table
// below still serves R16 and R20 as it always has; Files, People and the
// Syllabus have no page in the chain and answer here. `?empty=1` on the
// syllabus blanks the teacher's body.
function pageD(p, url) {
  const read = (name) => require('fs').readFileSync(require('path').join(__dirname, 'd-pages', name), 'utf8');
  // The little of InstUI's own CSS these pages lean on (its flex boxes, its
  // screen-reader clip, its checkbox and icon-button sizes), so a row in the
  // fake is the height it is on Canvas.
  const instui = '<style>[class*="screenReaderContent"]{position:absolute;left:-10000px;width:1px;height:1px;overflow:hidden}[class*="view--flex-flex"]{display:flex;align-items:center}[class*="view--flex-flex"][direction="column"]{flex-direction:column;align-items:stretch}[class*="view--flex-flex"][wrap="wrap"]{flex-wrap:wrap}[class*="view-flexItem"]{min-width:0}[class*="checkboxFacade__facade"]{display:inline-block;width:16px;height:16px;border:1px solid #888;border-radius:3px}[class*="checkbox__input"]{position:absolute;left:-10000px}[class*="-baseButton"]{background:#fff;border:1px solid #ccc;border-radius:4px;padding:6px 10px;font:inherit}[class*="baseButton__iconOnly"] svg{width:16px;height:16px}[class*="textInput__facade"]{display:flex;border:1px solid #ccc;border-radius:4px;padding:0 8px}[class*="textInput__facade"] input{border:0;outline:0;flex:1}.ui-tabs-nav{list-style:none;display:flex;gap:4px;padding:10px 130px 0 14px;margin:0}.roster td,.roster th{padding:12px 8px}#syllabus{width:100%;table-layout:fixed}.mini_calendar{width:100%}</style>';
  if (p === '/courses' && url.searchParams.get('full') === '1') return { main: read('courses-main.html') };
  if (/^\/courses\/\d+\/files\/?$/.test(p)) return { main: instui + read('files-main.html') };
  if (/^\/courses\/\d+\/users\/?$/.test(p)) return { main: instui + read('people-main.html') };
  if (/^\/courses\/\d+\/assignments\/syllabus\/?$/.test(p)) {
    let main = read('syllabus-main.html');
    if (url.searchParams.get('empty') === '1') main = main.replace(/(<div id="course_syllabus"[^>]*>)[\s\S]*?(<\/div>\s*<div id="course_syllabus_details")/, '$1 $2');
    return { main: instui + main, side: read('syllabus-side.html') };
  }
  return null;
}
// ---- end Session D ----
// ---- Session E pages (calendar, inbox) ----
// The calendar (FullCalendar's rendered month with its sidebar) and the Inbox
// (InstUI, a list of four and a thread open at `?open=1`), dumped from the
// sandbox on 2026-09-19 into test/e-pages/. InstUI's hashes read `css-x-`.
const E_PAGES = {};
function ePage(name) {
  if (!(name in E_PAGES)) E_PAGES[name] = fs.readFileSync(path.join(__dirname, 'e-pages', `${name}.html`), 'utf8');
  return E_PAGES[name];
}
function pageE(p, url) {
  if (p === '/calendar') { const v = url.searchParams.get('view'); return { main: ePage(v === 'week' || v === 'agenda' ? `calendar-${v}-main` : 'calendar-main'), side: ePage('calendar-side') }; }
  if (p === '/conversations') return { main: ePage(url.searchParams.get('open') === '1' ? 'inbox-open-main' : 'inbox-main'), side: '' };
  return null;
}
// ---- end Session E ----
// ---- Session F pages (discussions, settings) ----
// The discussions index (the sandbox, 2026-09-19): an InstUI heading inside a
// screen-reader span, a filter select, a search, Add Discussion (an InstUI
// primary link) and Settings; three sections as ToggleDetails, each row in
// a two-column grid (the unread badge, then the row); the closed section
// empty with its drawing. `?empty=1` is a course with no discussions at all.
const SVG = '<svg width="1em" height="1em"><path d="M0 0h1v1H0z"/></svg>';
const discussionRow = ({ id, title, unread, replies, fresh, last }) => `<div data-testid="discussion-row-container"><div><div><span class="css-1-grid"><span class="css-2-gridRow"><span class="css-3-gridCol"><div data-testid="ic-blue-unread-badge" style="top: 0px; position: relative; margin-left: 0px;">${unread ? '<span dir="ltr" title="" data-cid="Badge" class="css-4-view--inlineBlock-badge"></span>' : ''}</div></span><span class="css-3-gridCol"><div class="ic-item-row ic-discussion-row" style="opacity: 1;"><div class="ic-discussion-row-container"><span class="ic-drag-handle-container"></span><span class="ic-discussion-content-container" style="margin-left: 0px;"><span class="css-1-grid"><span class="css-2-gridRow"><span class="css-3-gridCol"><h3 dir="ltr" data-cid="Heading" class="css-5-view-heading"><a dir="ltr" data-testid="discussion-link-${id}" href="/courses/1/discussion_topics/${id}" data-cid="Link" class="css-6-view-link">${unread ? '<span class="css-7-screenReaderContent">unread,</span>' : ''}<span aria-hidden="true">${title}</span><span class="css-7-screenReaderContent">${title}</span></a></h3></span><span class="css-3-gridCol"><div style="display: flex; justify-content: end; padding: 0px;"><div class="ic-button-line-left ">${replies ? `<span class="ic-unread-badge"><span data-position="Popover___1" data-cid="Position Popover Tooltip" class="css-8-position"><span aria-describedby="Tooltip___0" data-popover-trigger="true" data-position-target="Popover___1"><span class="css-7-screenReaderContent">${fresh} unread replies</span><span aria-hidden="true" class="ic-unread-badge__count ic-unread-badge__unread-count">${fresh}</span></span></span><span data-position="Popover___2" data-cid="Position Popover Tooltip" class="css-8-position"><span aria-describedby="Tooltip___1" data-popover-trigger="true" data-position-target="Popover___2"><span class="css-7-screenReaderContent">${replies} total replies</span><span aria-hidden="true" class="ic-unread-badge__count ic-unread-badge__total-count">${replies}</span></span></span></span>` : ''}</div><div class="ic-button-line-right "><span class="subscribe-button" data-testid="discussion-subscribe" data-action-state="subscribeButton"><span data-position="Popover___3" data-cid="Position Popover Tooltip" class="css-8-position"><button dir="ltr" aria-pressed="false" data-cid="BaseButton IconButton ToggleButton" aria-describedby="Tooltip___2" data-popover-trigger="true" data-position-target="Popover___3" cursor="pointer" type="button" class="css-9-view--inlineBlock-baseButton"><span class="css-a-baseButton__content"><span class="css-b-baseButton__childrenLayout"><span class="css-c-baseButton__iconOnly"><span class="css-d-baseButton__iconSVG">${SVG}</span><span class="css-7-screenReaderContent">Unsubscribed</span></span></span></span></button></span></span></div></div></span></span><span class="css-2-gridRow"><span class="css-3-gridCol"><span aria-hidden="true">${last ? `<span class="ic-discussion-row__content last-reply-at"><span wrap="normal" letter-spacing="normal" class="css-e-text">Last post at ${last}</span></span>` : ''}</span></span><span class="css-3-gridCol"><span aria-hidden="true"></span></span><span class="css-3-gridCol"><span aria-hidden="true"></span></span></span></span></span></div></div></span></span></span></div></div></div>`;
const discussionSection = ([cls, kind], title, rows, { ordered = true, link = false, text = '' } = {}) => `<div class="${cls}-discussions-v2__wrapper" data-testid="discussion-connected-container"><div class="discussions-container__wrapper" data-testid="discussions-container-${kind}" data-action-state="discussions-container-${kind}-expanded"><span><span class="css-7-screenReaderContent"><h2 dir="ltr" data-cid="Heading" class="css-5-view-heading">${title}</h2></span><div data-cid="ToggleDetails" class="css-f-toggleDetails"><button aria-controls="Expandable___${kind}" aria-expanded="true" type="button" class="css-g-toggleDetails__toggle"><span class="css-h-toggleDetails__summary"><span class="css-i-toggleDetails__icon">${SVG}</span><span class="css-j-toggleDetails__summaryText"><span dir="ltr" direction="row" wrap="no-wrap" class="css-k-view--flex-flex"><span dir="ltr" class="css-l-view-flexItem"><span wrap="normal" letter-spacing="normal" class="css-e-text">${title}</span></span>${ordered ? '<span dir="ltr" class="css-l-view-flexItem"><span class="recent-activity-text-container"><span font-style="italic" wrap="normal" letter-spacing="normal" class="css-e-text">Ordered by Recent Activity</span></span></span>' : ''}</span></span></span></button><div id="Expandable___${kind}" class="css-m-toggleDetails__details"><div class="css-n-toggleDetails__content">${rows.length ? rows.map(discussionRow).join('') : `<div class="discussions-v2__container-image"><span dir="ltr" class="css-o-view--block"><span dir="ltr" class="css-o-view--block"><img alt="" src="data:image/gif;base64,R0lGODlhAQABAAAAACw="></span><span dir="ltr" class="css-p-view"><div wrap="normal" letter-spacing="normal" class="css-e-text">${text}</div></span>${link ? '<a dir="ltr" href="/courses/1/discussion_topics/new" data-cid="Link" class="css-6-view-link">Click here to add a discussion</a>' : ''}</span></div>`}</div></div></div></span></div></div>`;
function discussionsIndex(empty) {
  const sections = empty
    ? [discussionSection(['unpinned', 'discussions'], 'Discussions', [], { link: true, text: 'There are no discussions to show in this section' }), discussionSection(['closed-for-comments', 'closed-for-comments'], 'Closed for Comments', [], { text: 'You currently have no discussions with closed comments' })]
    : [discussionSection(['pinned', 'pinned-discussions'], 'Pinned Discussions', [{ id: 5, title: 'Introduce yourself', unread: true, replies: 0, fresh: 0, last: '' }], { ordered: false }),
      discussionSection(['unpinned', 'discussions'], 'Discussions', [{ id: 6, title: 'Problem Set 8: where did you get stuck?', unread: false, replies: 2, fresh: 1, last: 'Sep 19, 12:47 AM' }, { id: 7, title: 'Lab 3 partner sign-up', unread: true, replies: 0, fresh: 0, last: '' }, { id: 8, title: 'Reading group: chapter 9', unread: false, replies: 1, fresh: 0, last: 'Sep 12, 9:10 AM' }]),
      discussionSection(['closed-for-comments', 'closed-for-comments'], 'Closed for Comments', [], { text: 'You currently have no discussions with closed comments' })];
  return `<div><div><div class="discussions-v2__wrapper"><span class="css-7-screenReaderContent"><h1 dir="ltr" data-cid="Heading" class="css-5-view-heading">Discussions</h1></span><div><span dir="ltr" class="css-p-view"><span dir="ltr" data-testid="discussions-index-container" class="css-o-view--block"><span dir="ltr" wrap="wrap" direction="row" class="css-k-view--flex-flex"><span dir="ltr" class="css-l-view-flexItem"><span data-cid="Select SimpleSelect" class="css-q-select"><label data-cid="TextInput" for="discussion-filter" class="css-r-formFieldLayout"><div id="FormField-Label___0" style="display: contents;"><span class="css-7-screenReaderContent">Discussion Filter</span></div><span class="css-s-formFieldLayout__children"><span class="css-t-textInput__facade"><span class="css-u-textInput__layout"><span class="css-v-textInput__inputLayout"><input id="discussion-filter" aria-haspopup="listbox" aria-expanded="false" name="filter-dropdown" data-cid="SimpleSelect" role="combobox" autocomplete="off" readonly="" title="All" aria-readonly="true" type="text" class="css-w-textInput" value="All"><span class="css-x-textInput__afterElement"><span class="css-y-select__icon">${SVG}</span></span></span></span></span></span></label></span></span><span dir="ltr" class="css-l-view-flexItem"><label data-cid="TextInput" for="discussion-search" class="css-r-formFieldLayout"><div id="FormField-Label___1" style="display: contents;"><span class="css-7-screenReaderContent">Search discussions by title</span></div><span class="css-s-formFieldLayout__children"><span class="css-t-textInput__facade"><span class="css-u-textInput__layout">${SVG}<span class="css-v-textInput__inputLayout"><input name="discussion_search" id="discussion-search" data-testid="discussion-search" placeholder="Search by title or author..." type="text" class="css-w-textInput" value=""></span></span></span></span></label></span><span dir="ltr" class="css-l-view-flexItem"><span dir="ltr" wrap="no-wrap" direction="row" class="css-k-view--flex-flex"><a dir="ltr" id="add_discussion" data-cid="BaseButton Button" cursor="pointer" href="/courses/1/discussion_topics/new" class="css-9-view--inlineBlock-baseButton"><span class="css-a-baseButton__content"><span class="css-b-baseButton__childrenLayout"><span class="css-z-baseButton__iconWrapper"><span class="css-d-baseButton__iconSVG">${SVG}</span></span><span class="css-aa-baseButton__childrenWrapper"><span class="css-ab-baseButton__children">Add Discussion</span></span></span></span></a><span><span dir="ltr" id="discussion_settings" data-testid="discussion-setting-button" data-cid="BaseButton Button" cursor="pointer" type="button" role="button" tabindex="0" class="css-ac-view--block-baseButton"><span class="css-a-baseButton__content"><span class="css-b-baseButton__childrenLayout"><span class="css-z-baseButton__iconWrapper"><span class="css-d-baseButton__iconSVG">${SVG}</span></span><span class="css-aa-baseButton__childrenWrapper"><span class="css-ab-baseButton__children">Settings<span class="css-7-screenReaderContent">Discussion Settings</span></span></span></span></span></span></span></span></span></span></span></div><span dir="ltr" class="css-p-view">${sections.join('')}</span></div></div></div>`;
}
// The profile settings (the sandbox, 2026-09-19): the name table with its
// display spans, edit fields and hints (Canvas toggles them by the table's
// `editing` class and jQuery show/hide on the edit-only rows), Web Services,
// Approved Integrations with its primary, the InstUI feature table with two
// rows; the sidebar's contact tables and its two wide buttons.
const featureRow = (i, name, on) => `<tr dir="ltr" data-testid="ff-table-row" class="css-11-view-row"><td dir="ltr" class="css-12-view-cell"><div data-cid="ToggleDetails" class="css-f-toggleDetails"><button aria-controls="Expandable___${i}" aria-expanded="false" type="button" class="css-g-toggleDetails__toggle"><span class="css-h-toggleDetails__summary"><span class="css-i-toggleDetails__icon">${SVG}</span><span class="css-j-toggleDetails__summaryText">${name}</span></span></button><div id="Expandable___${i}" class="css-m-toggleDetails__details"></div></div></td><td dir="ltr" class="css-12-view-cell"></td><td dir="ltr" class="css-12-view-cell"><div title="${on ? 'Enabled' : 'Disabled'}"><span dir="ltr" direction="row" wrap="no-wrap" class="css-k-view--flex-flex"><span data-position="Menu___${i}" data-cid="Position Popover Menu" class="css-8-position"><button dir="ltr" aria-haspopup="true" id="Menu__label___${i}" aria-expanded="false" data-cid="BaseButton IconButton" cursor="pointer" type="button" class="css-9-view--inlineBlock-baseButton"><span class="css-a-baseButton__content"><span class="css-b-baseButton__childrenLayout"><span class="css-c-baseButton__iconOnly"><span class="css-d-baseButton__iconSVG">${SVG}</span><span class="css-7-screenReaderContent">${name}, current state: ${on ? 'Enabled' : 'Disabled'}</span></span></span></span></button></span></span></div></td></tr>`;
const SETTINGS_MAIN = `<h1 style="padding-top: 0.3em;">Alex Rivera's Settings</h1><div class="clear"></div>
<form class="form-inline" id="update_profile_form" style="margin-bottom: 20px;" action="/profile" accept-charset="UTF-8" method="POST"><input type="hidden" name="_method" value="PUT" autocomplete="off">
<table class="profile_table"><tbody>
<tr><th scope="row"><label for="user_name">Full Name:<span aria-hidden="true" title="This field is required">*</span></label></th><td><span class="full_name display_data">Alex Rivera</span><input class="edit_data" maxlength="255" size="30" aria-describedby="hints_name" type="text" value="Alex Rivera" name="user[name]" id="user_name" aria-required="true"><span id="hints_name" class="edit_or_show_data data_description"><br>This name will be used for grading.</span></td></tr>
<tr><th scope="row"><label for="user_short_name">Display Name:</label></th><td><span class="short_name display_data">Alex Rivera</span><input class="edit_data" maxlength="255" size="30" aria-describedby="hints_short_name" type="text" value="Alex Rivera" name="user[short_name]" id="user_short_name"><span id="hints_short_name" class="edit_or_show_data data_description"><br>People will see this name in discussions, messages and comments.</span></td></tr>
<tr><th scope="row"><label for="user_locale">Language:</label></th><td><span class="locale display_data">English (United States)</span><span class="edit_data"><select class="locale" aria-describedby="hints_language" name="user[locale]" id="user_locale"><option value="">System Default (English (United States))</option><option selected="selected" value="en">English (United States)</option></select><span id="hints_language" class="data_description"><br>This will override any browser or account settings.</span></span></td></tr>
<tr><th scope="row"><label for="user_time_zone">Time Zone:</label></th><td><span class="time_zone display_data">Mountain Time (US &amp; Canada)</span><span class="edit_data"><select name="user[time_zone]" id="user_time_zone"><option selected="selected" value="Mountain Time (US &amp; Canada)">Mountain Time (US &amp; Canada) (-07:00/-06:00)</option></select></span></td></tr>
<tr><td colspan="2"><div class="edit_data"><label for="user_subscribe_to_emails" class="checkbox"><input name="user[subscribe_to_emails]" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="user[subscribe_to_emails]" id="user_subscribe_to_emails"> I want to receive information, news and tips from Instructure</label></div></td></tr>
<tr class="edit_data_row select_change_password_row" style="display: none;"><th scope="row">Password:</th><td><label for="change_password_checkbox" class="checkbox"><input type="checkbox" id="change_password_checkbox" name="pseudonym[change_password]" value="1">Change Password</label></td></tr>
<tr class="change_password_row" style="display: none;"><th scope="row"><label for="old_password">Old Password:</label></th><td><input type="password" style="width: 150px;" id="old_password" name="pseudonym[old_password]"></td></tr>
<tr class="change_password_row" style="display: none;"><th scope="row"><label for="pseudonym_password">New Password:</label></th><td><input value="" style="width: 150px;" type="password" name="pseudonym[password]" id="pseudonym_password"></td></tr>
<tr class="edit_data_row more_options_link_row" style="display: none;"><th scope="row" colspan="2"><a href="#" class="more_options_link" style="display: none;">more options</a></th></tr>
<tr class="edit_data_row" style="display: none;"><td colspan="2"><div class="form-actions"><button type="button" class="btn cancel_button">Cancel</button><button type="submit" class="btn btn-primary">Update Settings</button></div></td></tr>
</tbody></table></form>
<a name="registered_web_services"></a><h2>Web Services</h2><p>Canvas can make your life a lot easier by tying itself in with the web tools you already use.  Click any of the services in "Other Services" to see what we mean.</p>
<p><input type="checkbox" id="show_user_services" checked=""><label for="show_user_services">Let fellow course/group members see which services I've linked to my profile</label></p>
<table role="presentation" style="width: 100%;"><tbody><tr><td class="services-cell"><div><h3>Registered Services</h3><div style="margin-left: 20px; margin-bottom: 20px;"><ul id="registered_services" class="unstyled_list"></ul>No Registered Services</div></div></td><td class="services-cell"><h3>Other Services</h3><div style="margin-left: 20px;">Click any service below to register:<ul id="unregistered_services" class="unstyled_list"><li id="unregistered_service_google_drive" class="service" style="display: none;"><a href="#" class="btn btn-small">Google Drive</a></li></ul><div id="register_service_mount_point"></div></div></td></tr></tbody></table>
<h2>Approved Integrations:</h2><div style="margin-left: 20px;"><div id="no_approved_integrations">Third-party applications can request permission to access the Canvas site on your behalf.  As you begin authorizing applications you will see them listed here.</div><div id="access_tokens_holder" style="display: none;">These are the third-party applications you have authorized to access the Canvas site on your behalf:</div><div style="margin-top: 10px;"><a href="#" class="btn btn-primary add_access_token_link"><i class="icon-plus" aria-hidden="true"></i> New Access Token</a></div><div id="new_access_token_mount_point"></div></div>
<h2 aria-hidden="true">Feature Options</h2><div class="feature-flag-wrapper"><div dir="ltr" class="css-p-view"><span dir="ltr" direction="row" wrap="no-wrap" class="css-k-view--flex-flex"><span dir="ltr" class="css-l-view-flexItem"><span data-cid="Select SimpleSelect" class="css-q-select"><label data-cid="TextInput" for="Select___0" class="css-r-formFieldLayout" style="width: 10rem;"><div id="FormField-Label___0" style="display: contents;"><span class="css-7-screenReaderContent">Filter by</span></div><span class="css-s-formFieldLayout__children"><span class="css-t-textInput__facade"><span class="css-u-textInput__layout"><span class="css-v-textInput__inputLayout"><input id="Select___0" aria-haspopup="listbox" aria-expanded="false" data-cid="SimpleSelect" role="combobox" autocomplete="off" readonly="" width="10rem" title="All" aria-readonly="true" type="text" class="css-w-textInput" value="All"><span class="css-x-textInput__afterElement"><span class="css-y-select__icon">${SVG}</span></span></span></span></span></span></label></span></span><span dir="ltr" class="css-l-view-flexItem"><label data-cid="TextInput" for="TextInput___1" class="css-r-formFieldLayout"><div id="FormField-Label___1" style="display: contents;"><span class="css-7-screenReaderContent">Search Features</span></div><span class="css-s-formFieldLayout__children"><span class="css-t-textInput__facade"><span class="css-u-textInput__layout">${SVG}<span class="css-v-textInput__inputLayout"><input placeholder="Search by name or id" type="search" id="TextInput___1" class="css-w-textInput" value=""></span></span></span></span></label></span><span dir="ltr" class="css-l-view-flexItem"><button dir="ltr" data-cid="BaseButton Button" cursor="pointer" type="button" class="css-9-view--inlineBlock-baseButton"><span class="css-a-baseButton__content"><span class="css-ab-baseButton__children">Clear</span></span></button></span></span>
<h2 dir="ltr" data-testid="ff-table-heading" data-cid="Heading" class="css-5-view-heading">User</h2><table dir="ltr" class="css-10-view-table"><caption><span class="css-7-screenReaderContent">User Feature Flags: sorted by Feature in Ascending order.</span></caption><thead class="css-13-head"><tr dir="ltr" class="css-11-view-row"><th scope="col" aria-sort="ascending" class="css-14-colHeader" style="width: 50%;"><button class="css-15-colHeader__button"><div class="css-16-colHeader__buttonContent"><p aria-hidden="true">Feature</p><span class="css-7-screenReaderContent">Sort by Feature</span>${SVG}</div></button></th><th scope="col" aria-sort="none" class="css-14-colHeader" style="width: 50%;"><button class="css-15-colHeader__button"><div class="css-16-colHeader__buttonContent"><p aria-hidden="true">Status</p><span class="css-7-screenReaderContent">Sort by Status</span>${SVG}</div></button></th><th scope="col" aria-sort="none" class="css-14-colHeader"><button class="css-15-colHeader__button"><div class="css-16-colHeader__buttonContent"><p aria-hidden="true">State</p><span class="css-7-screenReaderContent">Sort by State</span>${SVG}</div></button></th></tr></thead><tbody dir="ltr" class="css-17-view-body">${featureRow(0, 'Auto Show Closed Captions', false)}${featureRow(1, 'Open to-do items in a new tab', true)}</tbody></table></div></div>`;
const SETTINGS_SIDE = `<style>#right-side .button-sidebar-wide { text-align: left; margin: 5px auto; display: block; } .btn { text-align: center; padding: 8px 14px; border: 1px solid #c7cdd1; background: #fff; }</style><h2>Ways to Contact</h2><div><table class="single channel_list email_channels ic-Table ic-Table--condensed"><thead><tr><th>Email Addresses</th><th><span class="screenreader-only">Set Email as Default</span></th><th><span class="screenreader-only">Email Actions</span></th></tr></thead><tbody>
<tr class="channel default  pseudonym_3" id="channel_3"><th scope="row"><p class="path email_channel contact_channel_path ellipsis">alex@prepkin.test</p></th><td class="email_meta"><a href="/profile" class="default_link no-hover" aria-label="Set default email address"><i class="icon-star standalone-icon" aria-hidden="true" title="Set email address as default"></i><span class="screenreader-only default_label">This is the default email address</span></a></td><td class="email_actions"><span class="hidden_for_single"><a href="/communication_channels/3" class="delete_channel_link no-hover" aria-label="Remove email address"><i class="icon-trash standalone-icon" title="Remove email address"></i></a></span></td></tr>
<tr class="channel blank unconfirmed" style="display: none;"><th scope="row"><a href="#" class="path email_channel contact_channel_path ellipsis" title="">&nbsp;</a></th><td class="email_meta"></td><td class="email_actions hidden_for_single"></td></tr>
<tr><td colspan="3" style="text-align: center;"><a href="#" class="add_email_link icon-add" title="Add Email Address" aria-label="Add Email Address">Email Address</a></td></tr></tbody></table>
<div class="content-box-mini"><table class="channel_list other_channels ic-Table ic-Table--condensed"><thead><tr><th>Other Contacts</th><th colspan="2">Type</th></tr></thead><tbody><tr class="channel blank unconfirmed" style="display: none;"><td><a href="#" class="path">&nbsp;</a></td><td><span id="communication_text_type">sms</span></td><td></td></tr></tbody><tfoot><tr><td colspan="3" style="text-align: center;"><a href="#" class="add_contact_link icon-add" title="Add Contact Method" aria-label="Add Contact Method">Contact Method</a></td></tr></tfoot></table></div></div>
<div><hr><a href="#" class="edit_settings_link btn button-sidebar-wide"><i class="icon-edit" aria-hidden="true"></i> Edit Settings</a><a href="/dashboard/data_exports" class="btn button-sidebar-wide"><i class="icon-download" aria-hidden="true"></i> Download Submissions</a></div>`;
function pageF(p, url) {
  if (/^\/courses\/\d+\/discussion_topics\/?$/.test(p)) return { main: discussionsIndex(url.searchParams.get('empty') === '1') };
  if (p === '/profile/settings') return { main: SETTINGS_MAIN, side: SETTINGS_SIDE };
  return null;
}
// ---- end Session F ----

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
