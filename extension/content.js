// Runs on a connected Canvas page: applies the skin and puts Sprout on screen.
//
// Injected on demand by background.js once you connect a site, so it never runs
// anywhere you have not approved.

{

if (typeof module !== 'undefined') {
  // Under node the sibling scripts are modules, not page globals.
  Object.assign(globalThis, require('./receipt.js'), require('./themes.js'), require('./art/manifest.js'), require('./selectors.js'), require('./looks.js'), require('./canvas.js'), require('./day.js'), require('./recap.js'));
}

const ROOT_ID = 'prepkin-buddy';
const DEFAULTS = { dark: false, cards: true, tidy: true, mascot: true, focusMinutes: 25, search: true };
const instanceId = typeof document === 'undefined' ? null : crypto.randomUUID();
let tornDown = false;
if (instanceId) document.documentElement.dataset.pkInstance = instanceId;

/// Take everything this instance put on Canvas back off in one pass. The page
/// observer and timers stop first, so none of them can rebuild after this.
function teardown() {
  if (tornDown || typeof document === 'undefined') return;
  tornDown = true;
  clearInterval(ticker);
  clearTimeout(showTimer);
  clearTimeout(pageTimer);
  pageObserver?.disconnect();
  pageObserver = null;
  const root = document.documentElement;
  for (const name of [...root.classList]) if (name.startsWith('pk-')) root.classList.remove(name);
  document.querySelectorAll('[data-pk-name]').forEach((el) => {
    el.textContent = el.dataset.pkName;
    delete el.dataset.pkName;
  });
  document.querySelectorAll('[id^="pk-"], .pk-card-due, .pk-card-grade').forEach((el) => el.remove());
  document.querySelectorAll('[data-pk-course]').forEach((el) => delete el.dataset.pkCourse);
  document.querySelectorAll('[class*="pk-"]').forEach((el) => {
    for (const name of [...el.classList]) if (name.startsWith('pk-')) el.classList.remove(name);
  });
  document.getElementById(ROOT_ID)?.remove();
  unmountSprite();
  shadow = null;
  styleEl = null;
}

/// Whether this instance can still ask the extension for anything.
function alive() {
  let current = false;
  try { current = typeof chrome !== 'undefined' && !!chrome.runtime?.id; } catch {}
  if (!current) teardown();
  return current;
}

/// Send only this isolated script's own errors back to the worker.
function logError(where, err) {
  if (!alive()) return;
  try {
    if (!alive()) return;
    const version = chrome.runtime.getManifest().version;
    if (!alive()) return;
    chrome.runtime.sendMessage({
      type: 'log-error',
      at: new Date().toISOString(),
      where,
      message: err?.message ?? String(err ?? 'Unknown error'),
      stack: err?.stack ?? '',
      version,
    }).catch(() => {});
  } catch {}
}

/// Canvas runs in another JavaScript world. A filename or stack from the
/// extension's own origin keeps the school's errors out of this record.
function isOwnError(source, err) {
  if (!alive()) return false;
  const ownOrigin = chrome.runtime.getURL('');
  return String(source ?? '').startsWith(ownOrigin)
    || String(err?.stack ?? '').includes(ownOrigin);
}

if (typeof window !== 'undefined') {
  window.addEventListener('error', (event) => {
    if (isOwnError(event.filename, event.error)) logError('Canvas page', event.error ?? event.message);
  });
  window.addEventListener('unhandledrejection', (event) => {
    if (isOwnError('', event.reason)) logError('Canvas page', event.reason);
  });
}

/// Matches TaskKind.canvas.reward in the app, so the "+30" here is the same 30
/// coins the phone actually pays for a verified submission.
const COIN_REWARD = 30;
/// A finished focus session. The phone pays it; the extension only asks.


/// Everything the panel needs to redraw itself. `data` is the last sync, `wallet`
/// is what the phone told us about coins and looks, `ui` is where the student is.
/// The view the last render drew, so the scroll position is kept within a view
/// and dropped when the student moves to a different one.
/// Whether the panel was open on the last draw, so focus moves in once, on the
/// draw that opened it, and never again while the student is typing.
let wasOpen = false;
/// The buddy's own state: the palette (Command-K) and the coin float.
/// Everything else lives on the dashboard's tabs.
const ui = { open: false, view: 'search', query: '', float: null };
let data = { tasks: [], courses: [], graded: {}, weights: {} };
/// Names the student gave courses, by course id, and tasks they added
/// themselves. Both live in this browser only: Canvas and the phone never see them.
let nicknames = {};
let ownTasks = [];
/// When the student said they will actually sit down and do a task: task id to
/// a local date, `YYYY-MM-DD`. A due date is when the work is owed; this is the
/// only place that knows when it will be done. It never leaves this browser and
/// is never pushed to the phone.
let plans = {};
/// The grade a student is aiming for in a class, by course id, as the cutoff
/// percentage behind a letter. Their own number, kept here.
let targets = {};
/// The student's own ticks, { taskId: isoAt }, read from storage; the worker is
/// the one writer (background.js `tick`). Laid over the synced tasks as `doneAt`.
let done = {};

/// The last sync plus the student's own tasks, with nicknames applied to every
/// course name. The payload itself is never changed, so nothing invented is
/// ever pushed to the phone.
function composeData(payload, own = [], nick = {}, ticks = {}) {
  const base = payload ?? { tasks: [], courses: [], graded: {}, weights: {} };
  const name = (id, fallback) => (id != null && nick[String(id)]) || fallback;
  const courses = (base.courses ?? []).map((c) => ({ ...c, fullName: c.name, name: name(c.id, c.name) }));
  const mine = own.map((t) => ({ ...t, own: true, courseId: t.courseId ?? 'own', courseName: t.courseName || 'My tasks' }));
  const tasks = [...withDone(base.tasks ?? [], ticks), ...mine].map((t) => ({ ...t, courseName: name(t.courseId, t.courseName ?? '') }));
  return { ...base, courses, tasks };
}

/// Search over everything the extension already knows: Canvas's own pages,
/// each course and its tabs, every task. Every word typed must appear; what
/// starts with the query ranks first.
const COURSE_TABS = [['Assignments', 'assignments'], ['Modules', 'modules'], ['Grades', 'grades'], ['Announcements', 'announcements'], ['Discussions', 'discussion_topics'], ['Files', 'files'], ['People', 'users'], ['Syllabus', 'assignments/syllabus']];
function searchItems(d = data) {
  const items = [
    { kind: 'page', label: 'Dashboard', sub: 'Canvas', url: '/' }, { kind: 'page', label: 'Calendar', sub: 'Canvas', url: '/calendar' },
    { kind: 'page', label: 'Inbox', sub: 'Canvas', url: '/conversations' }, { kind: 'page', label: 'All courses', sub: 'Canvas', url: '/courses' },
    { kind: 'page', label: 'Account settings', sub: 'Canvas', url: '/profile/settings' },
  ];
  for (const c of d.courses ?? []) {
    if (!c.name) continue;
    items.push({ kind: 'course', label: c.name, sub: c.fullName && c.fullName !== c.name ? c.fullName : 'Course', url: `/courses/${c.id}` });
    for (const [tab, path] of COURSE_TABS) items.push({ kind: 'tab', label: `${c.name} ${tab}`, sub: tab, url: `/courses/${c.id}/${path}` });
  }
  for (const t of d.tasks ?? []) {
    if (!t.title) continue;
    const url = safeURL(t.url) ?? (t.courseId && t.courseId !== 'own' ? `/courses/${t.courseId}/assignments` : null);
    if (url) items.push({ kind: 'task', label: t.title, sub: `${t.courseName}${t.dueAt ? ' · ' + dueLabel(t, new Date()) : ''}`, url, dueAt: t.dueAt ?? null, done: isDone(t) });
  }
  return items;
}
/// Before a word is typed, the palette is grouped the way Linear's is: your
/// classes, then Canvas's own pages. What is due sits on the rail beside it,
/// said once. Typing turns the palette into one ranked list, tasks included.
function searchGroups(items) {
  return [
    ['Classes', items.filter((i) => i.kind === 'course').slice(0, 6)],
    ['Canvas', items.filter((i) => i.kind === 'page').slice(0, 4)],
  ].filter(([, list]) => list.length);
}
function searchRank(items, query, limit = 8) {
  const q = String(query ?? '').trim().toLowerCase();
  if (!q) return items.slice(0, limit);
  const words = q.split(/\s+/);
  const scored = [];
  for (const it of items) {
    const hay = `${it.label} ${it.sub}`.toLowerCase();
    if (!words.every((w) => hay.includes(w))) continue;
    const label = it.label.toLowerCase();
    const score = (label.startsWith(q) ? 0 : label.includes(q) ? 1 : 2) * 1000 + hay.indexOf(words[0]);
    scored.push([score, it]);
  }
  return scored.sort((a, b) => a[0] - b[0]).slice(0, limit).map((x) => x[1]);
}
let wallet = { coins: null, owned: ['classic'], wearing: 'classic' };
let skin = { ...DEFAULTS };
let focus = { state: 'idle' };
let handInWatched = false;
let flags = null;

/// Settings live in one place so the popup and the page cannot disagree.
async function settings() {
  const { skin: saved } = await chrome.storage.local.get('skin');
  const s = { ...DEFAULTS, ...(saved ?? {}) };
  // "Auto" follows the OS, and nothing else does; the resolved answer is
  // what every rule below reads.
  if (s.mode === 'auto') s.dark = matchMedia('(prefers-color-scheme: dark)').matches;
  return s;
}
if (typeof matchMedia === 'function') {
  matchMedia('(prefers-color-scheme: dark)').addEventListener?.('change', () => { if (skin?.mode === 'auto') mount(); });
}

/// Why the skin has to stay out of the way on this page, or null. Worked out
/// from the three places Canvas signals it and from the OS.
let killed = null;
let remoteKilled = null;
/// Canvas's ENV is written once per document and can be a hundred kilobytes;
/// read it once, not on every observer pass.
let envText = null;
function detectKill() {
  if (envText === null) {
    envText = [...document.querySelectorAll('script:not([src])')].map((el) => el.textContent).join('\n');
  }
  const env = envText;
  remoteKilled = remoteKill(flags, {
    host: location.host,
    page: pageName(location.pathname),
    version: chrome.runtime.getManifest().version,
    now: Date.now(),
  });
  return killReason({
    remote: remoteKilled,
    loginPage: isLoginPath(location.pathname),
    quizTake: isQuizTake(location.pathname),
    submitting: isSubmissionPath(location.pathname, location.hash),
    editorOpen: !!document.querySelector(SELECTORS.rce.sel),
    forcedColors: matchMedia('(forced-colors: active)').matches,
    prefersContrast: matchMedia('(prefers-contrast: more)').matches,
    envHighContrast: /"use_high_contrast"\s*:\s*true/.test(env),
    newQuizzes: !!document.querySelector(SELECTORS.newQuizzes.sel),
    widgetDashboard: /"widget_dashboard"\s*:\s*true/.test(env),
  });
}

/// Facts about this page the stylesheet cannot see on its own.
function detectFacts() {
  const has = (k) => !!document.querySelector(SELECTORS[k].sel);
  return {
    logoDup: has('headerLogo') && has('sidebarLogo'),
    todoDup: has('todoReact') && has('todoLegacy'),
    // Canvas's To Do and Coming Up go only under our rail: with no rail there
    // is no other list, and a page with no to-do list is not calmer. boot.js
    // folds a synced dashboard from the first paint, before Canvas's list has
    // mounted; that fold is kept, or its spinner shows in the gap.
    todoFold: (has('todoReact') || has('todoLegacy') || document.documentElement.classList.contains('pk-todo-fold')) && (railShows() || courseNextShows()),
    // The announcements index: every row ends in a Reply link that goes where the row goes.
    replyDup: has('replyLink'),
    // "Next in this class" on a course's home page.
    courseNext: courseNextShows(),
    // The Planner tab, on the dashboard with cards to stand beside.
    planner: railShows() && !!document.getElementById('DashboardCard_Container'),
    // Our grades row on a course's own grades page, Canvas's table under it.
    gradesPage: gradesPageShows(),
    listView: listViewShows(),
    // The finished-courses fold under the cards on the Courses tab.
    pastFold: pastFoldShows(),
    wordPaste: WORD_INKS.some((ink) =>
      document.querySelector(`.user_content [style*="color:${ink}" i], .user_content [style*="color: ${ink}" i]`)),
  };
}

/// What the student has put back, by receipt key. From storage; the popup writes it.
let putBack = {};
let facts = {};

/// The stylesheet rides in with the boot set (background.js registers skin.css
/// at document_start). On 2026-09-17 a page came up with every class on <html>
/// and no stylesheet at all: our planner as a bulleted list, Canvas's List View
/// unfolded, the rail the school's green. Whatever dropped it (a reload with
/// the folder rewritten under Chrome, a registration that lapsed), the page
/// can tell: pk-on is set and the paper's token is not. It asks the worker to
/// put the sheet back, once, and looks again a moment later.
let cssAsked = false;
function ensureStylesheet() {
  if (cssAsked || killed || !alive()) return;
  const root = document.documentElement;
  if (!root.classList.contains('pk-on')) return;
  const check = () => root.classList.contains('pk-on') && !getComputedStyle(root).getPropertyValue('--pk-radius').trim();
  if (!check()) return;
  cssAsked = true;
  if (alive()) chrome.runtime.sendMessage({ type: 'css-missing' }).catch(() => {});
  setTimeout(() => { if (check() && alive()) chrome.runtime.sendMessage({ type: 'css-missing' }).catch(() => {}); }, 2000);
}

/// The skin is a set of classes on <html>, nothing else — no inline property is
/// ever written, so taking every class away leaves Canvas, unchanged. boot.js
/// put a first guess on before paint; this is the same answer with the DOM read.
// Per-visit classes of ours that the sweep in applySkin must leave on <html>.
// Each session that runs in parallel (2026-09-18) adds its own between its
// two marker lines and nowhere else, so branches merge without a conflict.
const KEPT_CLASSES = new Set([
  'pk-show', 'pk-planner-on', 'pk-list-on', 'pk-grades-open',
  // ---- Session C classes (course pages) ----
  // ---- end Session C ----
  // ---- Session D classes (tables) ----
  // ---- end Session D ----
  // ---- Session E classes (calendar, inbox) ----
  // ---- end Session E ----
  // ---- Session F classes (discussions, settings) ----
  // ---- end Session F ----
]);

function applySkin(s) {
  const root = document.documentElement;
  killed = detectKill();
  facts = detectFacts();
  const look = wornLook();
  const next = new Set(killed ? [] : skinClasses({ on: !!s.cards, dark: !!s.dark, dense: !!s.dense, hidePast: !!s.hidePast, gradeHover: !!s.cardGradesHover, look, putBack, detect: facts }));
  for (const c of [...root.classList]) {
    // `pk-grades-open` is the student's own click on "Canvas's table" this
    // visit; the sweep used to take it off a moment later and the table
    // snapped shut (found 2026-09-18, the old test passed on the race).
    if (c.startsWith('pk-') && !KEPT_CLASSES.has(c) && !next.has(c)) root.classList.remove(c);
  }
  for (const c of next) root.classList.add(c);
  // The theme's variables, as a stylesheet element boot.js may already have made.
  // With no classes there is nothing for it to hold, and an empty <style> of
  // ours on a page we said we would leave alone is still a node of ours on that
  // page. It goes. (test/receipt.test.js R18 is what says so.)
  let style = document.getElementById('pk-theme-vars');
  if (!next.size) { style?.remove(); return; }
  if (!style) { style = document.createElement('style'); style.id = 'pk-theme-vars'; root.append(style); }
  if (!alive()) return;
  const css = themeStyle(look, textureImage, artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f), ownArt)) + '\n' + courseVarsCSS();
  if (style.textContent !== css) style.textContent = css;
}

/// The receipt for this page, for the popup.
function receiptForPage() {
  const look = wornLook();
  return {
    page: pageName(location.pathname),
    off: killed,
    on: !!skin.cards,
    rows: killed || !skin.cards ? [] : receiptRows({
      present: (k) => document.querySelectorAll(SELECTORS[k].sel).length,
      detect: facts, dark: !!skin.dark, mascot: !!skin.mascot, cardGrades: skin.cardGrades !== false, cardGradesHover: !!skin.cardGradesHover, dense: !!skin.dense, hidePast: !!skin.hidePast, nicknames: Object.keys(nicknames).length, ownArt: Object.keys(cardArt).length, ownWall: look.art === 'own', search: skin.search !== false,
      stock: stockFor(look, !!skin.dark), putBack,
    }),
  };
}

let showTimer = null;
function showMe() {
  document.documentElement.classList.add('pk-show');
  clearTimeout(showTimer);
  showTimer = setTimeout(() => document.documentElement.classList.remove('pk-show'), 4000);
}

const COIN_SVG = `
  <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
    <circle cx="7" cy="7" r="6.4" fill="var(--pk-coin)"/>
    <circle cx="7" cy="7" r="3.4" fill="none" stroke="var(--pk-coin-ring)" stroke-width="1.6"/>
  </svg>`;

// MARK: - Reading the day: see day.js

// The buddy's voice lives in day.js, shared with the popup.

// MARK: - Work dates
//
// Canvas knows when a thing is owed. Nothing in Canvas asks when you will do
// it, which is the question students actually get wrong.

function dayKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function dayFromKey(k) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(k ?? ''));
  if (!m) return null;
  const [y, mo, day] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const d = new Date(y, mo - 1, day);
  // JS rolls a bad date forward rather than refusing it, so 2026-13-40 becomes
  // next February. Only a date that reads back the same is a date.
  if (d.getFullYear() !== y || d.getMonth() !== mo - 1 || d.getDate() !== day) return null;
  return d;
}

/// The day a task sits on in the planner: the day it was planned for, and
/// otherwise the day it is due. Work with neither sits under "No due date".
function planDay(t, planned = plans) {
  const p = dayFromKey(planned[t.id]);
  if (p) return p;
  const due = t.dueAt ? new Date(t.dueAt) : null;
  return due && !isNaN(due) ? startOfDay(due) : null;
}

/// What buckets() asks for: the day a task was planned, or null.
const plannedOn = (t) => dayFromKey(plans[t.id]);

/// True when the student moved this one off the day it is due.
function isMoved(t, planned = plans) {
  const p = dayFromKey(planned[t.id]);
  if (!p) return false;
  const due = t.dueAt ? new Date(t.dueAt) : null;
  return !due || isNaN(due) || !sameLocalDay(p, due);
}

// MARK: - Grades

/// Canvas does not know which classes are Honors or AP, so the student says.
/// The usual US bump: Honors +0.5, AP +1.0, never lifting a failing grade.
const LEVELS = { regular: 0, honors: 0.5, ap: 1.0 };
const LEVEL_NAMES = { regular: 'Regular', honors: 'Honors', ap: 'AP' };
let levels = {};

/// A polyline across a course's graded work. Scaled to its own range with a
/// little headroom, because the shape is the point, not the absolute height.
function sparkline(points, color) {
  if (points.length < 2) return '';
  const w = 280, h = 36, pad = 3;
  const ys = points.map((p) => p.percent);
  const lo = Math.min(...ys), hi = Math.max(...ys);
  const span = hi - lo < 5 ? 5 : hi - lo;
  const x = (i) => (i / (points.length - 1)) * w;
  const y = (v) => h - pad - ((v - lo) / span) * (h - pad * 2);
  const d = points.map((p, i) => `${i ? 'L' : 'M'}${x(i).toFixed(1)} ${y(p.percent).toFixed(1)}`).join(' ');
  const last = points[points.length - 1];
  return `<svg class="pk-spark" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">
    <path d="${d}" stroke="${escapeHTML(color)}" stroke-width="2" fill="none"
          stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke"/>
    <circle cx="${x(points.length - 1).toFixed(1)}" cy="${y(last.percent).toFixed(1)}" r="3" fill="${escapeHTML(color)}"/>
  </svg>`;
}

/// The letters we offer as what-if targets: where you are, and the steps around it.
const LETTERS = [['A', 93], ['A−', 90], ['B+', 87], ['B', 83], ['B−', 80], ['C+', 77], ['C', 73]];

function targetsFor(score) {
  const i = LETTERS.findIndex(([, cut]) => score >= cut);
  const at = i === -1 ? LETTERS.length - 1 : i;
  // Always four choices, even from the bottom of the table.
  const start = Math.min(Math.max(0, at - 1), LETTERS.length - 4);
  return LETTERS.slice(start, start + 4);
}

/// What the missing zeros are worth, and — only when the arithmetic can be
/// checked — what handing them in would do to the class percentage.
///
/// We hold at most the last two dozen graded items, and a course that weights
/// its groups does not average that way. So the percentage is recomputed from
/// what we hold and only spoken when it lands on the number Canvas itself
/// reports. When it does not, the points are the whole of what we say. A grade
/// nobody can check is exactly the kind of number this app does not print.
function missingCost(missed, courses = data.courses ?? [], gradedBy = data.graded ?? {}) {
  const byCourse = new Map();
  for (const t of missed) {
    const k = String(t.courseId);
    if (!byCourse.has(k)) byCourse.set(k, []);
    byCourse.get(k).push(t);
  }
  const out = [];
  for (const [id, items] of byCourse) {
    const course = courses.find((c) => String(c.id) === id);
    const points = items.reduce((n, t) => n + (Number(t.pointsPossible) || 0), 0);
    const row = { courseId: id, name: course?.name ?? items[0].courseName ?? '', count: items.length, points, from: null, to: null };
    const held = gradedBy[id] ?? [];
    const den = held.reduce((n, g) => n + (Number(g.outOf) || 0), 0);
    const num = held.reduce((n, g) => n + (Number(g.score) || 0), 0);
    if (course && typeof course.score === 'number' && den > 0 && points > 0
        && Math.abs((num / den) * 100 - course.score) <= 0.5) {
      const marked = new Set(held.map((g) => g.id));
      let top = num, bottom = den;
      for (const t of items) {
        const p = Number(t.pointsPossible) || 0;
        if (!p) continue;
        // A zero the teacher entered is already in the bottom half; work never
        // marked at all is in neither.
        top += p;
        if (!marked.has(t.id)) bottom += p;
      }
      row.from = Math.round(course.score * 10) / 10;
      row.to = Math.round((top / bottom) * 100);
    }
    out.push(row);
  }
  return out.sort((a, b) => b.points - a.points);
}

/// One line per class, in plain points. No exclamation, no red.
function missingCostLines(missed) {
  return missingCost(missed).map((r) => {
    const worth = `${r.points} point${r.points === 1 ? '' : 's'} in ${escapeHTML(r.name)}`;
    return r.to === null
      ? `<div class="pk-foot">Worth ${worth}.</div>`
      : `<div class="pk-foot">Worth ${worth} — enough to move it from ${r.from}% to about ${r.to}%.</div>`;
  }).join('');
}

// MARK: - Small pieces

/// Only ever link to what Canvas itself handed us.
function safeURL(u) {
  return typeof u === 'string' && u.startsWith('https://') ? u : null;
}

// MARK: - The kin

const KIN_SPECIES = ['butter', 'coral', 'lilac', 'mint', 'peach', 'sky'];
function ownSpecies() {
  const board = Array.isArray(wallet.league?.board) ? wallet.league.board : [];
  const species = board.find((member) => member?.you === true)?.species;
  return KIN_SPECIES.includes(String(species)) ? String(species) : 'mint';
}


/// What he says when clicked: his line, the one thing to start with its two
/// ways to start it, the next few, this class's next three on a course page,
/// and the two doors (the planner, search). No AI, no server: the same facts
/// the rail and the planner hold, in one place a click away on every page.
function helpView() {
  const now = new Date();
  const b = buckets(data.tasks ?? [], now, plannedOn);
  const said = voice(b);
  const first = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;
  const then = [...b.today, ...b.week, ...b.overdue].filter((t) => t.dueAt && t !== first).slice(0, 3);
  const cid = /^\/courses\/(\d+)/.exec(location.pathname)?.[1] ?? null;
  const here = cid ? dueRowsFor(cid, now, 3).filter((r) => !r.done) : [];
  const running = focus.state === 'running';
  const row = (t, late) => {
    const url = safeURL(t.url);
    const inner = `<b>${escapeHTML(t.title)}</b><small${late ? ' class="amber"' : ''}>${escapeHTML(shortCourse(t.courseName))} · ${escapeHTML(dueLabel(t, now).replace(' · still counts', ''))}</small>`;
    return `<li>${url ? `<a href="${escapeHTML(url)}">${inner}</a>` : `<span>${inner}</span>`}</li>`;
  };
  let top = '';
  if (running) {
    top = `<p class="pk-help-label">Now</p><div class="pk-help-first"><b>${escapeHTML(focus.title ?? 'Focus')}</b><small><span class="pk-clock">${clockLeft()}</span> left</small>
      <div class="pk-help-actions">${safeURL(focus.url) ? `<a class="start" href="${escapeHTML(safeURL(focus.url))}">Open</a>` : ''}<button type="button" data-focus-stop="1">Stop</button></div></div>`;
  } else if (first) {
    const late = new Date(first.dueAt) < now;
    const url = safeURL(first.url);
    top = `<p class="pk-help-label">Start with</p><div class="pk-help-first"><b>${escapeHTML(first.title)}</b><small${late ? ' class="amber"' : ''}>${escapeHTML(shortCourse(first.courseName))} · ${escapeHTML(dueLabel(first, now).replace(' · still counts', ''))}</small>
      <div class="pk-help-actions">${url ? `<a class="start" href="${escapeHTML(url)}">Start</a>` : ''}<button type="button" data-focus-first="${escapeHTML(String(first.id))}">Focus ${skin.focusMinutes} min</button></div></div>`;
  }
  const thenRows = running ? [first, ...then].filter((t) => t && String(t.id) !== String(focus.taskId)).slice(0, 3) : then;
  // Your classes, from any page: the tile, the name, the letter when grades
  // are on the cards. The class list without a sidebar of ours.
  const classes = (data.courses ?? []).filter((c) => c.name && /^\d+$/.test(String(c.id))).slice(0, 8);
  const tile = (c) => { const color = safeColor(c.colorHex); return `<i class="pk-tile"${color ? ` style="background:${color}"` : ''} aria-hidden="true">${escapeHTML((shortCourse(c.name) || '?').trim().charAt(0).toUpperCase())}</i>`; };
  const classRows = classes.map((c) => `<li><a href="/courses/${escapeHTML(String(c.id))}">${tile(c)}<b>${escapeHTML(c.name)}</b>${skin.cardGrades !== false && c.grade ? `<small>${escapeHTML(String(c.grade))}</small>` : ''}</a></li>`).join('');
  return `
    <div class="pk-viewhead pk-help-head"><h2>${escapeHTML(said.headline)}</h2></div>
    <p class="pk-help-sub">${escapeHTML(said.subline)}</p>
    ${top}
    ${thenRows.length ? `<p class="pk-help-label">Then</p><ul class="pk-help-list">${thenRows.map((t) => row(t, new Date(t.dueAt) < now)).join('')}</ul>` : ''}
    ${here.length ? `<p class="pk-help-label">Next in this class</p><ul class="pk-help-list">${here.map((r) => row(r.t, r.overdue)).join('')}</ul>` : ''}
    ${classRows ? `<p class="pk-help-label">Your classes</p><ul class="pk-help-classes">${classRows}</ul>` : ''}
    <ul class="pk-help-doors">
      <li><a href="/#planner"><b>Open the planner</b><small>The week by day, your grades</small></a></li>
      <li><button type="button" data-help-search="1"><b>Search Canvas</b><small>Classes, pages, assignments <kbd>⌘K</kbd></small></button></li>
    </ul>`;
}

function searchView() {
  return `
    <div class="pk-viewhead">
      <h2>Search</h2><kbd class="pk-kbd">⌘K</kbd>
    </div>
    <input id="pk-q" class="pk-search" type="text" placeholder="Classes, pages, assignments" value="${escapeHTML(ui.query ?? '')}" autocomplete="off" aria-label="Search">
    <ul class="pk-results">${resultsHTML(ui.query)}</ul>
    <div class="pk-keys"><span><kbd>↑</kbd><kbd>↓</kbd> move</span><span><kbd>↵</kbd> open</span><span><kbd>esc</kbd> close</span></div>`;
}
function resultsHTML(query) {
  const row = (h, on) => `<li${on ? ' class="on"' : ''}><a href="${escapeHTML(h.url)}" data-result><b>${escapeHTML(h.label)}</b><small>${escapeHTML(h.sub)}</small></a></li>`;
  const items = searchItems();
  if (!String(query ?? '').trim()) {
    let first = true;
    return searchGroups(items).map(([name, list]) =>
      `<li class="pk-group">${name}</li>` + list.map((h) => { const html = row(h, first); first = false; return html; }).join('')).join('');
  }
  const hits = searchRank(items, query);
  if (!hits.length) return '<li class="empty">Nothing matches.</li>';
  return hits.map((h, i) => row(h, i === 0)).join('');
}

/// "17:21" — what is left of the session.
function clockLeft() {
  const left = Math.max(0, focus.endsAt - Date.now());
  return `${Math.floor(left / 60000)}:${String(Math.floor((left % 60000) / 1000)).padStart(2, '0')}`;
}

/// Once a second while a session runs: the card's clock and ring, and the
/// rail's clock, moved in place. A full redraw each second would restart
/// every animation and drop every hover; the state changes come through
/// storage and redraw properly.
function tickClocks() {
  if (focus.state !== 'running') return;
  const text = clockLeft();
  for (const node of document.querySelectorAll(`#${WEEK_ID} .pk-w-clock, #${PLANNER_ID} .pk-w-clock`)) node.textContent = text;
  if (!shadow) return;
  const clock = shadow.querySelector('.pk-timer .pk-clock');
  if (clock) clock.textContent = text;
  const ring = shadow.querySelector('.pk-timer .pk-ring circle:last-child');
  if (ring) {
    const left = Math.max(0, focus.endsAt - Date.now());
    ring.setAttribute('stroke-dashoffset', (2 * Math.PI * 54 * (left / (focus.durationMin * 60000))).toFixed(1));
  }
}

/// The running / finished focus card, beside the buddy on every page but the
/// dashboard, where the rail's Now row carries the running clock. The finished
/// card shows everywhere until Done is pressed: a payoff should not be missed.
///
/// The shape is Oura's and Tiimo's: the task on top, the time left inside a
/// ring, when it ends underneath, and two quiet words at the foot. The buddy
/// is not in the ring — he is alive in the tank next to this card already.
function focusCard() {
  if (focus.state === 'running') {
    const left = Math.max(0, focus.endsAt - Date.now());
    const total = focus.durationMin * 60000;
    const mins = Math.floor(left / 60000);
    const secs = Math.floor((left % 60000) / 1000);
    const pct = Math.min(100, ((total - left) / total) * 100);
    const ends = new Date(focus.endsAt).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
    // The ring fills as the session goes. Only ever forward.
    const R = 54, C = 2 * Math.PI * R;
    return `
      <div class="pk-timer">
        <b class="pk-task">${escapeHTML(focus.title ?? 'Focus')}</b>
        <span class="pk-ring">
          <svg viewBox="0 0 120 120" width="120" height="120" aria-hidden="true">
            <circle cx="60" cy="60" r="${R}" fill="none" stroke="var(--pk-track)" stroke-width="6"/>
            <circle cx="60" cy="60" r="${R}" fill="none" stroke="var(--pk-mint)" stroke-width="6" stroke-linecap="round"
                    stroke-dasharray="${C.toFixed(1)}" stroke-dashoffset="${(C * (1 - pct / 100)).toFixed(1)}" transform="rotate(-90 60 60)"/>
          </svg>
          <span class="pk-clock">${mins}:${String(secs).padStart(2, '0')}</span>
        </span>
        <small>Ends at ${escapeHTML(ends)}</small>
        <div class="pk-row">
          <button class="pk-give" data-focus-extend="1">+5 min</button>
          <button class="pk-give" data-focus-stop="1">Stop</button>
        </div>
      </div>`;
  }
  // Done. The buddy cheers in the tank, so the card only has the words.
  return `
    <div class="pk-timer done">
      <b>${focus.durationMin} minutes. Nice.</b>
      <span class="pk-plus">${COIN_SVG}+${focus.durationMin} coins on your phone</span>
      ${safeURL(focus.url)
        ? `<a class="pk-start" style="width:100%" href="${escapeHTML(focus.url)}">Open the assignment</a>`
        : ''}
      <button class="pk-give" data-focus-clear="1">Done</button>
    </div>`;
}

// MARK: - Dashboard cards
//
// The one line students asked for most: what is due next, on the card their
// eye lands on first. It goes into the page (not the shadow root) because it is
// only a title and a date, the same text Canvas itself shows one click away.

const CARD_DUE_CLASS = 'pk-card-due';
const CARD_GRADE_CLASS = 'pk-card-grade';
/// Which of the theme's banners each course wears, by the student's choice.
/// Empty means "rotate by position", which is what a fresh theme does.
let banners = {};
const BANNER_COUNT = 4;

/// A picture the student chose for a course card, by course id:
/// `{ src, scrim, w, h }`. It is read from a file they pick, shrunk here, and
/// kept in this browser. It is never uploaded, never fetched, and never pushed
/// to the phone — the whole point is that it is theirs and it stays put.
let cardArt = {};
/// Twice the widest card band, so it still looks sharp on a retina screen.
const OWN_ART_W = 720;
/// chrome.storage.local holds ten megabytes for everything. A course picture
/// gets a fifth of a megabyte, which at this size is a generous photograph.
const OWN_ART_MAX = 200_000;
/// Tried in order until one fits. The last one is used even if it does not,
/// because a picture that is slightly too big is not a reason to say no.
const OWN_ART_STEPS = [[720, 0.72], [560, 0.6], [420, 0.5], [320, 0.4]];

/// A 96px copy for the picker. The panel redraws on every keystroke somewhere
/// else in it, and a full-size picture in the markup each time is a megabyte of
/// string for a 28px-tall thumbnail.
async function thumbnail(bmp) {
  const w = Math.max(1, Math.min(96, bmp.width));
  const h = Math.max(1, Math.round(bmp.height * (w / bmp.width)));
  const canvas = new OffscreenCanvas(w, h);
  canvas.getContext('2d').drawImage(bmp, 0, 0, w, h);
  return blobToDataURL(await canvas.convertToBlob({ type: 'image/jpeg', quality: 0.6 }));
}

function blobToDataURL(blob) {
  return new Promise((resolve, reject) => {
    const r = new FileReader();
    r.onload = () => resolve(String(r.result));
    r.onerror = () => reject(r.error ?? new Error('unreadable'));
    r.readAsDataURL(blob);
  });
}

/// Mean relative luminance of a decoded picture, sampled every sixteenth pixel.
/// Sampling, not summing: a 720-wide photo is a quarter of a million pixels and
/// the answer to two decimal places is the same either way.
function meanLuminance(px) {
  const lin = (c) => { const v = c / 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
  let sum = 0; let n = 0;
  for (let i = 0; i < px.length; i += 64) {
    sum += 0.2126 * lin(px[i]) + 0.7152 * lin(px[i + 1]) + 0.0722 * lin(px[i + 2]);
    n += 1;
  }
  return n ? sum / n : 0;
}

/// A file the student picked, turned into something a card can wear. Anything
/// the browser can decode is accepted; brightness only decides how much scrim
/// goes over it, never whether it is allowed.
async function readPicture(file) {
  const bmp = await createImageBitmap(file);
  let out = null;
  try {
    for (const [width, quality] of OWN_ART_STEPS) {
      const w = Math.max(1, Math.min(width, bmp.width));
      const h = Math.max(1, Math.round(bmp.height * (w / bmp.width)));
      const canvas = new OffscreenCanvas(w, h);
      const ctx = canvas.getContext('2d', { willReadFrequently: true });
      ctx.drawImage(bmp, 0, 0, w, h);
      const scrim = scrimFor(meanLuminance(ctx.getImageData(0, 0, w, h).data));
      const src = await blobToDataURL(await canvas.convertToBlob({ type: 'image/jpeg', quality }));
      out = { src, scrim, w, h, thumb: await thumbnail(bmp) };
      if (src.length <= OWN_ART_MAX) break;
    }
  } finally { bmp.close(); }
  return out;
}

/// The student's own photo as the wallpaper of the "Your picture" look:
/// `{ src, thumb, w, h, palette }`. Read from a file they pick, shrunk here,
/// kept in this browser. Never uploaded, never fetched, never pushed to the
/// phone. The palette (receipt.js `paletteFrom`) is the rail and accent the
/// look wears while this photo is under it.
let ownArt = null;
/// Wide enough for a laptop screen; a wallpaper sits under a paper wash, so it
/// need not be sharper than the screen.
const OWN_WALL_STEPS = [[1920, 0.82], [1600, 0.78], [1280, 0.74], [1024, 0.7]];
/// A megabyte and a half of the ten the browser gives the whole extension.
const OWN_WALL_MAX = 1_500_000;

async function readWallpaper(file) {
  const bmp = await createImageBitmap(file);
  let out = null;
  try {
    for (const [width, quality] of OWN_WALL_STEPS) {
      const w = Math.max(1, Math.min(width, bmp.width));
      const h = Math.max(1, Math.round(bmp.height * (w / bmp.width)));
      const canvas = new OffscreenCanvas(w, h);
      const ctx = canvas.getContext('2d', { willReadFrequently: true });
      ctx.drawImage(bmp, 0, 0, w, h);
      const palette = paletteFrom(ctx.getImageData(0, 0, w, h).data);
      const src = await blobToDataURL(await canvas.convertToBlob({ type: 'image/jpeg', quality }));
      out = { src, w, h, palette, thumb: await wallpaperThumb(bmp) };
      if (src.length <= OWN_WALL_MAX) break;
    }
  } finally { bmp.close(); }
  return out;
}

/// A 480x270 cover crop for the Looks tile, the size the bundled thumbs are.
async function wallpaperThumb(bmp) {
  const W = 480, H = 270;
  const scale = Math.max(W / bmp.width, H / bmp.height);
  const w = bmp.width * scale, h = bmp.height * scale;
  const canvas = new OffscreenCanvas(W, H);
  canvas.getContext('2d').drawImage(bmp, (W - w) / 2, (H - h) / 2, w, h);
  return blobToDataURL(await canvas.convertToBlob({ type: 'image/jpeg', quality: 0.7 }));
}

/// The look being worn. "Your picture" is a look only with a photo behind it:
/// with none it is Classic, and with one the photo's own colours ride on it.
/// boot.js works the same answer out before first paint.
function wornLook() {
  const base = LOOKS_BY_ID[wallet.wearing] ?? LOOKS_BY_ID.classic;
  if (base.art !== 'own') return base;
  if (typeof ownArt?.src !== 'string') return LOOKS_BY_ID.classic;
  return { ...base, ...(ownArt.palette ?? {}) };
}

/// The pictures, as one stylesheet of custom properties.
///
/// Variables here, rules in skin.css — the same split themeStyle uses, so
/// nothing in this file has to write a page-visible declaration and Put back is
/// still one class away. A <style> element, never an inline property, so
/// teardown leaves Canvas exactly as it found it.
///
/// If a school runs a Content-Security-Policy that bars `data:` images the rule
/// simply does not paint and the card keeps its own colour band, the same way
/// every other rule here fails.
function applyCardArt() {
  const ids = Object.keys(cardArt).filter((id) => /^\d+$/.test(id) && typeof cardArt[id]?.src === 'string');
  const on = skin?.cards && !killed && ids.length > 0;
  let style = document.getElementById('pk-card-art');
  if (!on) { style?.remove(); return; }
  if (!style) {
    style = document.createElement('style');
    style.id = 'pk-card-art';
    document.documentElement.append(style);
  }
  const css = ids.map((id) => {
    const a = Math.min(0.85, Math.max(0, Number(cardArt[id].scrim) || 0));
    return 'html.pk-on .ic-DashboardCard[data-pk-course="' + id + '"]{'
      + '--pk-own-art:url("' + cardArt[id].src + '");'
      + '--pk-own-scrim:rgba(0,0,0,' + a + ')}';
  }).join('\n');
  if (style.textContent !== css) style.textContent = css;
}

/// Facts the stylesheet cannot read off Canvas's own lists, written as
/// attributes on the nodes (never their text): which course a Recent Feedback
/// row belongs to (its colour goes on the edge), the mark as "18/20", how many
/// rows an assignment or quiz group holds (its count chip), and the points of
/// an unscored assignment ("15 pts", where Canvas writes "-/15 pts"). Off, or
/// on a page we leave alone, every attribute goes.
function decorateLists() {
  const on = skin.cards && !killed;
  const clear = (sel, attr) => document.querySelectorAll(`${sel}[${attr}]`).forEach((el) => el.removeAttribute(attr));
  if (!on || putBack['feedback-rows']) { clear('.events_list.recent_feedback a', 'data-pk-course'); clear('.events_list.recent_feedback strong', 'data-pk-mark'); }
  else {
    for (const a of document.querySelectorAll('.events_list.recent_feedback a.recent_feedback_icon')) {
      const id = a.getAttribute('href')?.match(/\/courses\/(\d+)\//)?.[1];
      if (id) { if (a.dataset.pkCourse !== id) a.dataset.pkCourse = id; } else delete a.dataset.pkCourse;
      const strong = a.querySelector('.event-details p > strong');
      const m = strong?.textContent.trim().match(/^(\d+(?:\.\d+)?) out of (\d+(?:\.\d+)?)$/);
      if (m) { const mark = `${m[1]}/${m[2]}`; if (strong.dataset.pkMark !== mark) strong.dataset.pkMark = mark; }
      else strong?.removeAttribute('data-pk-mark');
    }
  }
  if (!on || putBack.paper) clear('.item-group-condensed .ig-header-title', 'data-pk-count');
  else {
    for (const head of document.querySelectorAll('.item-group-condensed .ig-header .ig-header-title')) {
      const n = String(head.closest('.item-group-condensed')?.querySelectorAll('.ig-row:not(.ig-row-empty)').length ?? 0);
      if (head.dataset.pkCount !== n) head.dataset.pkCount = n;
    }
  }
  if (!on || putBack['due-column']) clear('.ig-row .score-display', 'data-pk-pts');
  else {
    for (const el of document.querySelectorAll('.ig-row .ig-details .score-display')) {
      const m = el.textContent.trim().match(/^-\s*\/\s*(\S+)\s*pts$/);
      if (m) { const pts = `${m[1]} pts`; if (el.dataset.pkPts !== pts) el.dataset.pkPts = pts; }
      else el.removeAttribute('data-pk-pts');
    }
  }
}

/// The course colours, one rule per course, for any node of Canvas's that
/// names its course (`data-pk-course`): the edge of a feedback row.
function courseVarsCSS() {
  return [...(data.courses ?? []), ...(data.pastCourses ?? [])]
    .map((c) => ({ id: String(c.id), color: safeColor(c.colorHex) }))
    .filter((c) => /^\d+$/.test(c.id) && c.color)
    .map((c) => `html.pk-on [data-pk-course="${c.id}"]{--pk-course:${c.color}}`).join('\n');
}

/// The rows a card shows under "Due": up to three, pending first (overdue,
/// then soonest, then undated), then the latest handed-in work, struck.
/// Work the school marked missing more than a week ago. It belongs in the
/// panel's Missing list, never written into the school's own page: a card that
/// leads with a three-week-old zero has buried the thing due tonight.
function isStaleMissing(t, now = new Date()) {
  if (!t.missing || isDone(t) || !t.dueAt) return false;
  const due = Date.parse(t.dueAt);
  return Number.isFinite(due) && (startOfDay(now) - startOfDay(new Date(due))) / DAY_MS > MISSED_AFTER_DAYS;
}

/// The one line a course card carries: the soonest pending thing (slipped work
/// first, since it is the oldest), how many more are pending, and whether
/// anything was finished at all, and how: "All handed in" only when Canvas saw
/// a submission, "All done" when the student's own ticks cleared the rest.
function nextLineFor(courseId, now = new Date()) {
  const rows = dueRowsFor(courseId, now, Infinity);
  const pending = rows.filter((r) => !r.done);
  return { next: pending[0] ?? null, more: Math.max(0, pending.length - 1), done: rows.some((r) => r.done), handedIn: rows.some((r) => r.t.submittedAt) };
}

function dueRowsFor(courseId, now = new Date(), limit = 3) {
  const mine = data.tasks.filter((t) => String(t.courseId) === String(courseId) && !isStaleMissing(t, now));
  const time = (t) => { const d = t.dueAt ? new Date(t.dueAt) : null; return d && !isNaN(d) ? d.getTime() : Infinity; };
  const pending = mine.filter((t) => !isDone(t)).sort((a, b) => time(a) - time(b)).slice(0, limit);
  const finished = mine.filter(isDone).sort((a, b) => new Date(doneTime(b)) - new Date(doneTime(a))).slice(0, Math.max(0, limit - pending.length));
  return [...pending, ...finished].map((t) => ({ t, done: isDone(t), overdue: !isDone(t) && time(t) < now.getTime(), when: dueShort(t, now) }));
}

/// "7:54 PM" today, "Mon 7:54 PM" this week, "Sep 12" after that.
function dueShort(t, now) {
  const d = t.dueAt ? new Date(t.dueAt) : null;
  if (!d || isNaN(d)) return 'any time';
  const clock = d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  if (sameLocalDay(d, now)) return clock;
  const days = Math.round((startOfDay(d) - startOfDay(now)) / DAY_MS);
  if (days > 0 && days < 7) return `${d.toLocaleDateString([], { weekday: 'short' })} ${clock}`;
  return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

function nextUpFor(courseId, now = new Date()) {
  const pending = data.tasks
    .filter((t) => String(t.courseId) === String(courseId) && !isDone(t) && !isStaleMissing(t, now))
    .map((t) => ({ t, due: t.dueAt ? new Date(t.dueAt) : null }))
    .filter((x) => !x.due || !isNaN(x.due));
  if (!pending.length) return null;
  // Overdue first (oldest first), then soonest, then undated.
  pending.sort((a, b) => (a.due?.getTime() ?? Infinity) - (b.due?.getTime() ?? Infinity));
  return pending[0].t;
}

function decorateCards() {
  const cards = [...document.querySelectorAll('.ic-DashboardCard')];
  const courseOf = (card) => card.querySelector('a[href*="/courses/"]')?.getAttribute('href')?.match(/\/courses\/(\d+)/)?.[1];
  // Which course a card is for, so a stylesheet can name one card. Canvas has
  // no attribute that says it; the id is only in an href.
  for (const card of cards) {
    const id = courseOf(card);
    if (id) card.dataset.pkCourse = id; else delete card.dataset.pkCourse;
    const own = skin.cards && !killed && !putBack['card-art'] && !putBack.hero && !!cardArt[id]?.src;
    card.classList.toggle('pk-own-art', own);
  }
  applyCardArt();
  // The banner a course was given, as a class on its card; none means rotate.
  for (const card of cards) {
    const pick = skin.cards && !killed ? banners[courseOf(card)] : null;
    for (let i = 1; i <= BANNER_COUNT; i++) card.classList.toggle(`pk-banner-${i}`, pick === i);
  }
  // A nickname the student gave a course goes on its card; Put back restores
  // the registrar's title, kept on the node.
  for (const card of cards) {
    const span = card.querySelector('.ic-DashboardCard__header-title span') ?? card.querySelector('.ic-DashboardCard__header-title');
    if (!span) continue;
    const nick = skin.cards && !killed && !putBack.nickname ? nicknames[courseOf(card)] : null;
    if (nick) {
      if (span.dataset.pkName == null) span.dataset.pkName = span.textContent;
      if (span.textContent !== nick) span.textContent = nick;
    } else if (span.dataset.pkName != null) {
      if (span.textContent !== span.dataset.pkName) span.textContent = span.dataset.pkName;
      delete span.dataset.pkName;
    }
  }
  // The grade, on the band's corner, on unless the student's receipt row turned
  // it off (the #3 thing students name; BetterCampus shows it by default too).
  const showGrades = skin.cards && !killed && skin.cardGrades !== false;
  for (const card of cards) {
    const course = data.courses.find((c) => String(c.id) === courseOf(card));
    const score = showGrades && typeof course?.score === 'number' ? course.score : null;
    let pill = card.querySelector(`.${CARD_GRADE_CLASS}`);
    if (score === null) { pill?.remove(); continue; }
    if (!pill) {
      pill = document.createElement('span');
      pill.className = CARD_GRADE_CLASS;
      const header = card.querySelector('.ic-DashboardCard__header');
      if (header) header.append(pill); else continue;
    }
    const text = `${Number.isInteger(score) ? score : score.toFixed(1)}%`;
    if (pill.textContent !== text) pill.textContent = text;
  }
  if (!skin.cards || killed || putBack['card-due']) {
    document.querySelectorAll(`.${CARD_DUE_CLASS}`).forEach((el) => el.remove());
    return;
  }
  const now = new Date();
  for (const card of cards) {
    const id = courseOf(card);
    if (!id) continue;
    // A course that is not the student's — one they TA, a concluded one that
    // still has a card — gets no line at all rather than a misleading "Nothing due".
    if (!data.courses.some((c) => String(c.id) === id)) { card.querySelector(`.${CARD_DUE_CLASS}`)?.remove(); continue; }
    // Below the header, not inside it: Canvas clips the header to a fixed
    // height, and a line in there is in the DOM but never on screen.
    let el = card.querySelector(`.${CARD_DUE_CLASS}`);
    if (!el) {
      el = document.createElement('div');
      el.className = CARD_DUE_CLASS;
      const actions = card.querySelector('.ic-DashboardCard__action-container');
      if (actions) actions.before(el); else card.append(el);
    }
    // One line per card: the next thing, its date, and how many more wait. The
    // rail beside the cards holds the list; a card says its one thing once.
    const { next, more, done: finished, handedIn } = nextLineFor(id, now);
    el.classList.toggle('overdue', !!next?.overdue);
    el.classList.toggle('is-none', !next);
    // textContent, never markup: titles are other people's text. Rebuilt only
    // when the line changes, so our own write never re-triggers the observer.
    const sig = next ? `${next.t.id}|${next.overdue ? 1 : 0}|${next.when}|${more}|${next.t.title}` : handedIn ? 'all-in' : finished ? 'all-done' : 'none';
    if (el.dataset.sig === sig) continue;
    el.dataset.sig = sig;
    el.replaceChildren();
    if (!next) { el.textContent = handedIn ? 'All handed in' : finished ? 'All done' : 'Nothing due'; continue; }
    // The circle first, then the line, which is a link to the work and says
    // Start when the mouse is on it.
    el.append(tickCircle(next.t));
    const url = safeURL(next.t.url);
    const row = document.createElement(url ? 'a' : 'div');
    row.className = `pk-due-row${next.overdue ? ' overdue' : ''}`;
    if (url) row.href = url;
    const t = document.createElement('span'); t.className = 't'; t.textContent = next.t.title; t.title = next.t.title;
    row.append(t);
    if (more) { const n = document.createElement('span'); n.className = 'n'; n.textContent = `+${more}`; n.title = `${more} more in this class`; row.append(n); }
    const d = document.createElement('span'); d.className = 'd'; d.textContent = next.overdue ? `was due ${next.when}` : next.when;
    row.append(d);
    if (url) { const go = document.createElement('span'); go.className = 'go'; go.textContent = 'Start'; row.append(go); }
    el.append(row);
    fitAtWord(t, next.t.title);
  }
}

/// The card's line shares its row with "+2", the date and Start, so how much
/// title fits depends on the card. Measured, not guessed: drop whole words
/// until the span no longer overflows, so the cut lands at a word (the CSS
/// ellipsis stays as the backstop for one word wider than the row).
function fitAtWord(span, full) {
  span.textContent = full;
  const words = full.split(' ');
  while (words.length > 1 && span.scrollWidth > span.clientWidth) {
    words.pop();
    span.textContent = `${words.join(' ').replace(/[\s:;,.\-–—]+$/, '')}…`;
  }
}
/// Every `.pk-fit` name in a box, whenever the box has a width: now, and again
/// each time its size changes (a course home's aside is laid out after the
/// page; a window narrows). Nothing measures at width 0, so those are skipped.
function fitAll(box) {
  const fit = () => {
    if (!box.isConnected || box.clientWidth === 0) return;
    for (const node of box.querySelectorAll('.pk-fit')) fitAtWord(node, node.title ? node.title.split(' · ')[0] : node.textContent);
  };
  fit();
  if (!box.pkFitWatch && typeof ResizeObserver !== 'undefined') {
    box.pkFitWatch = new ResizeObserver(fit);
    box.pkFitWatch.observe(box);
  }
}

// MARK: - Handing in
//
// The moment a student submits, the ring and the buddy should answer, not the
// next half-hour sync. Canvas hands work in two ways: the classic forms under
// #submit_assignment post and reload the page, the newer Submit button stays on
// it. Either way the page asks the worker for one sync, which it rate-limits.
// Only trusted events count: a script can dispatch a click, not a student.

const HANDED_IN_KEY = 'handedInAt';
const HANDED_IN_FRESH_MS = 3 * 60_000;

function askSyncAfterSubmit(delayMs) {
  setTimeout(() => {
    if (!alive()) return;
    chrome.runtime.sendMessage({ type: 'after-submit' }).catch(() => {});
  }, delayMs);
}

function watchHandIn() {
  // Classic: the form posts and Canvas comes back to the assignment page.
  // The flag survives the reload; the next load asks for the sync.
  document.addEventListener('submit', (e) => {
    if (!e.isTrusted || !alive()) return;
    const form = e.target;
    if (!(form instanceof HTMLFormElement) || !form.closest('#submit_assignment')) return;
    chrome.storage.local.set({ [HANDED_IN_KEY]: Date.now() }).catch(() => {});
  }, true);
  // Assignment Enhancements: the button submits in place.
  document.addEventListener('click', (e) => {
    if (!e.isTrusted) return;
    const btn = e.target instanceof Element ? e.target.closest('button[data-testid="submit-button"]') : null;
    if (btn) askSyncAfterSubmit(4000);
  }, true);
}

/// On a fresh load: if the last page handed something in a moment ago, Canvas
/// recorded it before it sent the browser here, so the ask goes out at once —
/// a student who clicks on within a second must not lose it. Then the flag
/// is forgotten; the worker's sync does not need this tab.
async function syncIfJustHandedIn(stored) {
  const at = Number(stored?.[HANDED_IN_KEY]) || 0;
  if (!at) return;
  if (!alive()) return;
  if (Date.now() - at < HANDED_IN_FRESH_MS) askSyncAfterSubmit(0);
  await chrome.storage.local.remove(HANDED_IN_KEY);
}

// MARK: - A small helper the rail uses

function el(tag, cls, text) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text != null) n.textContent = text;
  return n;
}

// MARK: - Search, in the corner of every page
//
// One pill at the end of the page's title bar: the dashboard header, or the
// breadcrumb strip on every other page. It opens the buddy on search; so does
// Command-K.

const SEARCH_ID = 'pk-search';

function renderSearchChip() {
  const existing = document.getElementById(SEARCH_ID);
  // Only two homes, both of them rows: the dashboard's own bar, or the
  // breadcrumb strip on every other page. The dashboard bar is React and is
  // not in the DOM at document_end, so on the dashboard this finds nothing on
  // the first pass and the observer mounts the pill when the bar arrives.
  // Anything else — the container, a print-only action header — is not a row,
  // and the pill lands on top of the title or at 0,0.
  const bar = document.querySelector('#dashboard_header_container .ic-Dashboard-header__layout')
    ?? (document.getElementById('dashboard_header_container') ? null
      : document.querySelector('.ic-app-nav-toggle-and-crumbs'));
  if (!bar || !skin.cards || killed || skin.search === false || !skin.mascot || !shadow) { existing?.remove(); return; }
  if (existing && existing.parentElement === bar) return;
  existing?.remove();
  const chip = el('span', '', null);
  chip.id = SEARCH_ID;
  chip.setAttribute('role', 'button'); chip.tabIndex = 0; chip.setAttribute('aria-label', 'Search Canvas, Command K');
  const glass = document.createElementNS(SVG_NS, 'svg');
  glass.setAttribute('viewBox', '0 0 16 16'); glass.setAttribute('width', '15'); glass.setAttribute('height', '15'); glass.setAttribute('aria-hidden', 'true');
  const c = document.createElementNS(SVG_NS, 'circle'); c.setAttribute('cx', '7'); c.setAttribute('cy', '7'); c.setAttribute('r', '4.5'); c.setAttribute('fill', 'none'); c.setAttribute('stroke', 'currentColor'); c.setAttribute('stroke-width', '2');
  const l = document.createElementNS(SVG_NS, 'path'); l.setAttribute('d', 'M10.5 10.5 L14 14'); l.setAttribute('stroke', 'currentColor'); l.setAttribute('stroke-width', '2'); l.setAttribute('stroke-linecap', 'round');
  glass.append(c, l);
  const mac = typeof navigator !== 'undefined' && /Mac/.test(navigator.platform ?? '');
  chip.append(glass, el('span', '', 'Search'), el('kbd', '', mac ? '⌘K' : 'Ctrl K'));
  const openSearch = () => { ui.open = true; ui.view = 'search'; ui.query = ''; render(); };
  chip.addEventListener('click', openSearch);
  chip.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openSearch(); } });
  bar.append(chip);
}

// MARK: - This week, at the top of the sidebar
//
// Our own rail, at the top of the dashboard sidebar: a ring per course for
// the week, the one thing to start, the next few, and a way into the buddy's
// week. Canvas's own To Do folds to one line under it, one click to show.
// Counts and titles only; grades stay behind the panel's closed root.

const WEEK_ID = 'pk-week';
const FOLD_ID = 'pk-todo-fold';
const SVG_NS = 'http://www.w3.org/2000/svg';
/// Which week the rings show, in weeks from this one. The arrows move it; a
/// sync brings it home.

/// "AP Physics C: Mechanics" is the course; a narrow line has room for the course.
function shortCourse(name) {
  const n = String(name ?? '');
  return n.length > 20 && n.includes(':') ? n.split(':')[0].trim() : n;
}

/// Once per week, when the last thing goes in, the buddy dances. The week is
/// remembered so a reload does not make him do it again.
let celebrated = null;
function celebrateWeek(allIn, start) {
  if (!allIn) return;
  const week = start.toISOString().slice(0, 10);
  if (celebrated === week) return;
  celebrated = week;
  spriteSend({ do: 'play', emote: 'dance' });
  if (alive()) chrome.storage.local.set({ celebrated: week }).catch(() => {});
}

/// The day alone, for a row with room for one word: Today, Tomorrow, Mon, or
/// the date once it is more than a week off either way.
function dayShort(t, now) {
  const due = new Date(t.dueAt);
  if (isNaN(due)) return '';
  const days = Math.round((startOfDay(due) - startOfDay(now)) / DAY_MS);
  if (days === 0) return 'Today';
  if (days === 1) return 'Tomorrow';
  if (Math.abs(days) <= 6) return due.toLocaleDateString([], { weekday: 'short' });
  return due.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

/// What planner.js needs of this file's state. It runs before this script,
/// and a script cannot see the top-level let/const of one that runs after it;
/// function declarations it can. So the state goes out through this one.
function plannerState() {
  return { data, plans, wallet, focus, skin, putBack, killed, levels, ownTasks, plannedOn, nicknames, targets, recapDismissed, soFarDismissed, LEVELS, LEVEL_NAMES };
}
/// The student's own words for a class: a nickname, its level, the grade they
/// aim for. Each is kept in this browser; the tab that set it redraws itself.
async function setNickname(courseId, value) {
  const v = String(value ?? '').trim();
  const next = { ...nicknames };
  if (v) next[String(courseId)] = v; else delete next[String(courseId)];
  nicknames = next;
  await chrome.storage.local.set({ nicknames });
}
function plannerNickname(courseId, value) { return setNickname(courseId, value); }
async function setLevel(courseId, level) {
  levels = { ...levels, [String(courseId)]: level };
  await chrome.storage.local.set({ levels });
  renderPlanner();
}
function plannerLevel(courseId, level) { return setLevel(courseId, level); }
async function setAim(courseId, cut) {
  targets = { ...targets, [String(courseId)]: Number(cut) };
  await chrome.storage.local.set({ targets });
  renderPlanner();
}
function plannerAim(courseId, cut) { return setAim(courseId, cut); }
/// The recap card, put away for this term; the rail's door goes with it.
let recapDismissed = null;
let soFarDismissed = null;
async function dismissSoFar(key) {
  soFarDismissed = key;
  await chrome.storage.local.set({ soFarDismissed: key });
  renderPlannerTabs(); renderPlanner(); renderWeek();
}
function plannerDismissSoFar(key) { return dismissSoFar(key); }
async function dismissRecap(key) {
  recapDismissed = key;
  await chrome.storage.local.set({ recapDismissed: key });
  renderPlanner();
  renderWeek();
}
function plannerDismissRecap(key) { return dismissRecap(key); }
function plannerSetOwnTasks(next) { ownTasks = next; }
// This file sits in one block, so only its plain function declarations reach
// the world (Annex B hoisting); an async function does not. Hence the wrappers.
function plannerPlan(id, key) { return setPlan(id, key); }
function plannerBuy(id) { return buy(id); }
function plannerLooks() { return { LOOKS, LOOKS_BY_ID, PAPERS, ART_AVAILABLE, cardArt, banners, ownArt, worn: wornLook() }; }
/// The student's own photo as a wallpaper: read here, shrunk here, kept here,
/// and worn at once.
async function plannerWallpaper(file) {
  const pic = await readWallpaper(file);
  if (!pic) return false;
  ownArt = pic;
  wallet = { ...wallet, wearing: 'own', owned: wallet.owned.includes('own') ? wallet.owned : [...wallet.owned, 'own'] };
  await chrome.storage.local.set({ ownArt, wallet });
  applySkin(skin);
  render();
  return true;
}
function plannerWallpaperAsync(file) { return plannerWallpaper(file); }
async function plannerClearWallpaper() {
  ownArt = null;
  if (wallet.wearing === 'own') wallet = { ...wallet, wearing: 'classic' };
  await chrome.storage.local.set({ ownArt: null, wallet });
  applySkin(skin);
  render();
}
function plannerClearWallpaperAsync() { return plannerClearWallpaper(); }
/// A picture the student picked for a course card, or a banner from the theme.
async function plannerPicture(courseId, file) {
  const pic = await readPicture(file);
  if (!pic) return false;
  cardArt = { ...cardArt, [courseId]: pic };
  banners = { ...banners, [courseId]: undefined };
  await chrome.storage.local.set({ cardArt, banners });
  decorateCards();
  return true;
}
function plannerPictureAsync(courseId, file) { return plannerPicture(courseId, file); }
async function plannerClearPicture(courseId) {
  const { [courseId]: gone, ...rest } = cardArt;
  cardArt = rest;
  await chrome.storage.local.set({ cardArt });
  decorateCards();
}
function plannerClearPictureAsync(courseId) { return plannerClearPicture(courseId); }
async function plannerBanner(courseId, n) {
  banners = { ...banners, [courseId]: banners[courseId] === n ? undefined : n };
  await chrome.storage.local.set({ banners });
  decorateCards();
}
function plannerBannerAsync(courseId, n) { return plannerBanner(courseId, n); }

/// Whether the rail belongs on this page: the dashboard, the skin on, nothing
/// killed or put back, and a sync to show. Shown from the first sync on, even
/// with nothing due: the empty week is still the student's.
// MARK: - Ticked done
//
// A circle at the left of every row of ours. A tick is the student's word that
// a thing is finished; it never writes to Canvas. The worker keeps the map and
// tells the phone (background.js `tick`); a task of the student's own is local.

/// The circle. `on` fills it; a click asks for the other state. A real click
/// only: a script on the page can dispatch one at the button.
function tickCircle(t, on = isDone(t)) {
  const b = el('button', `pk-tick${on ? ' on' : ''}`);
  b.type = 'button';
  b.setAttribute('aria-pressed', String(on));
  b.setAttribute('aria-label', on ? `Done: ${t.title}. Undo` : `Done: ${t.title}`);
  b.title = on ? 'Undo' : 'Done';
  b.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); if (e.isTrusted) setDone(t, !on); });
  return b;
}

/// What the rail's foot says for a moment after a tick, with its Undo.
let lastTick = null;
let lastTickTimer = null;

async function setDone(t, on) {
  if (!alive()) return;
  // The foot's line is set before the write, so the redraw the write causes
  // already finds it; a refused tick takes it back.
  const before = lastTick;
  lastTick = on ? { id: t.id, title: t.title, at: Date.now() } : null;
  clearTimeout(lastTickTimer);
  if (t.own) {
    // A task the student added never reaches the worker or the phone.
    ownTasks = ownTasks.map((x) => (x.id === t.id ? { ...x, submittedAt: on ? new Date().toISOString() : null } : x));
    await chrome.storage.local.set({ ownTasks });
  } else {
    if (!alive()) return;
    const r = await chrome.runtime.sendMessage({ type: on ? 'done' : 'undone', id: t.id }).catch(() => null);
    if (!r?.ok) { lastTick = before; return; }
  }
  if (on) { lastTickTimer = setTimeout(() => { lastTick = null; if (alive()) renderWeek(); }, 8000); spriteSend({ do: 'play', emote: 'bounce' }); }
}

/// The class as a small tile: its Canvas colour and its first letter. The
/// colour is the school's, not ours (data-pk-course-color says so to the lint).
function classTile(t) {
  const tile = el('i', 'pk-tile', (shortCourse(t.courseName) || '?').trim().charAt(0).toUpperCase());
  const color = safeColor(t.colorHex);
  if (color) { tile.style.background = color; tile.dataset.pkCourseColor = ''; }
  tile.setAttribute('aria-hidden', 'true');
  return tile;
}

function railShows() {
  const onDashboard = /^\/(dashboard)?\/?$/.test(location.pathname);
  return onDashboard && !!document.getElementById('right-side') && !!skin.cards && !killed && !putBack.week && !!(data.tasks?.length || data.at);
}

function renderWeek() {
  const existing = document.getElementById(WEEK_ID);
  const side = document.getElementById('right-side');
  if (!railShows()) {
    existing?.remove();
    document.getElementById(FOLD_ID)?.remove();
    return;
  }
  const now = new Date();
  const w = weekStats(data.tasks, now);
  const b = buckets(data.tasks, now, plannedOn);
  // The oldest slipped task is the one to start; after it, what is coming
  // before what has already gone by, so the list is not a wall of amber.
  const first = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;
  const then = [...b.today, ...b.week, ...b.overdue].filter((t) => t.dueAt && t !== first).slice(0, 3);
  const running = focus.state === 'running';
  const said = voice(b);
  const key = JSON.stringify([w.start.getTime(), w.total, w.done, said.headline,
    first?.id, first?.dueAt, then.map((t) => [t.id, t.dueAt, t.submittedAt, t.doneAt]), b.overdue.length, skin.focusMinutes, tankId(), lastTick?.id,
    running && focus.endsAt, running && focus.title, plTab, recapDismissed]);
  if (existing && existing.dataset.key === key) { renderFold(); return; }
  const box = el('section', '', null);
  box.id = WEEK_ID;
  box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: this week');
  // Built before he has said ready (or before his frame exists at all, on the
  // first pass): the card waits, at most 1.5 s, so the two come in as one.
  if (skin.mascot && (!sprite || (!sprite.ready && Date.now() - (sprite.mountedAt ?? 0) < 1500))) {
    box.classList.add('pk-w-waiting');
    setTimeout(() => box.classList.remove('pk-w-waiting'), 1500);
  }

  // The buddy's line, the same words his panel opens with. Finch's bird
  // speaks above its goals; this is that, without a bubble.
  if (buddyMode() === 'tank') {
    const tank = el('div', 'pk-w-tank', null);
    if (alive()) tank.style.setProperty('--pk-tank', `url("${chrome.runtime.getURL(`art/tanks/${tankId()}.webp`)}")`);
    box.append(tank);
  }
  const say = el('div', 'pk-w-say');
  say.append(el('b', '', said.headline));
  // His second line only when nothing follows it: "Start with" says the rest.
  if (!(running || first)) say.append(el('small', '', said.short ?? said.subline));
  box.append(say);

  // No strip, no ring (2026-09-14): the rail is five things — the tank, his
  // line, the thing to start, the next three, and a foot in words. The week's
  // count lives in the foot; the planner tab holds the week itself.
  const allIn = w.total > 0 && w.done === w.total;
  // The week closes: he dances once for it. Confetti, without the confetti.
  celebrateWeek(allIn, w.start);

  // One list, the way BetterCampus keeps one: the thing to start at the top
  // with its two ways to start it, the next few under it. Always today's,
  // whichever week the rings show.
  // While the Planner tab is open the list is there, by day; the rail keeps
  // the tank, his line and the foot, so nothing is said twice.
  if ((running || first) && plTab !== 'planner') {
    box.append(el('p', 'pk-w-label', running ? 'Now' : 'Start with'));
    const list = el('ul', 'pk-w-list');
    const top = el('li', 'pk-w-first');
    const info = el('div');
    const actions = el('div', 'pk-w-actions');
    const press = (node, fn) => {
      node.setAttribute('role', 'button'); node.tabIndex = 0;
      node.addEventListener('click', fn);
      node.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fn(e); } });
    };
    if (running) {
      // The session, not the queue: what is being worked on, how long is
      // left (ticked in place), the page it is on, and one way to stop.
      const task = data.tasks.find((t) => String(t.id) === String(focus.taskId));
      const meta = el('small', '', '');
      meta.append(`${task ? shortCourse(task.courseName) + ' · ' : ''}`, el('span', 'pk-w-clock', clockLeft()), ' left');
      info.append(el('b', '', focus.title ?? 'Focus'), meta);
      const url = safeURL(focus.url);
      if (url) { const a = el('a', 'start', 'Open'); a.href = url; actions.append(a); }
      const stop = el('span', '', 'Stop');
      press(stop, (e) => { if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-stop' }); });
      actions.append(stop);
    } else {
      const overdue = new Date(first.dueAt) < now;
      // The circle, then the words. Amber and "Was due" already say late; the
      // row does not add a comment.
      info.className = 'pk-w-info';
      const words = el('div');
      words.append(el('b', '', first.title), el('small', overdue ? 'amber' : '', `${shortCourse(first.courseName)} · ${dueLabel(first, now).replace(' · still counts', '')}`));
      info.append(tickCircle(first), words);
      const url = safeURL(first.url);
      if (url) { const a = el('a', 'start', 'Start'); a.href = url; actions.append(a); }
      const focusBtn = el('span', '', `Focus ${skin.focusMinutes} min`);
      press(focusBtn, (e) => {
        if (!e.isTrusted || !alive()) return;
        chrome.runtime.sendMessage({ type: 'focus-start', taskId: first.id, title: first.title, url: first.url, minutes: skin.focusMinutes });
      });
      actions.append(focusBtn);
    }
    top.append(info, actions);
    list.append(top);
    box.append(list);
    // Then: the next few, one line each — the class as a tile in its colour
    // with its first letter (the row George picked from Finch), the title, the
    // day on the right. The full course and time sit in the title for a hover.
    const rest = running ? [first, ...then].filter((t) => t && String(t.id) !== String(focus.taskId)).slice(0, 3) : then;
    if (rest.length) {
      box.append(el('p', 'pk-w-label', 'Then'));
      const more = el('ul', 'pk-w-list pk-w-then');
      for (const t of rest) {
        const late = new Date(t.dueAt) < now;
        const li = el('li');
        li.append(tickCircle(t), classTile(t));
        const name = el('b', 'pk-fit', t.title);
        name.title = `${t.title} · ${t.courseName} · ${dueLabel(t, now)}`;
        li.append(name, el('small', late ? 'amber' : '', dayShort(t, now)));
        more.append(li);
      }
      box.append(more);
    }
  }

  // The league is the buddy's: it lives in his panel, one tap away, not on
  // the page. BetterCampus's column is one list, and so is this.

  const foot = el('div', 'pk-w-foot');
  if (lastTick && Date.now() - lastTick.at < 8000) {
    // Just ticked: say so, with the way back (Todoist's toast, in words).
    // The foot has one job for those seconds: the planner link waits.
    const line = el('span', 'pk-w-undo');
    const what = el('span', 'pk-w-undo-what', `Done: ${lastTick.title}`);
    what.title = lastTick.title;
    line.append(what, ' · ');
    const undo = el('span', 'more', 'Undo');
    undo.setAttribute('role', 'button'); undo.tabIndex = 0;
    const back = (e) => { if (!e.isTrusted) return; const t = data.tasks.find((x) => x.id === lastTick.id); if (t) setDone(t, false); };
    undo.addEventListener('click', back);
    undo.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); back(e); } });
    line.append(undo);
    foot.append(line);
    box.append(foot);
    if (existing) existing.replaceWith(box); else side.prepend(box);
    fitAll(box);
    renderFold();
    if (sprite) placeSprite();
    return;
  } else if (recapDue(data.courses, data.tasks, now) && plRecapKey(data.tasks, now) !== recapDismissed && plTab !== 'planner') {
    // A term is ending: the door to the recap, on the planner tab.
    const door = el('span', 'more', 'Your term, in numbers');
    door.setAttribute('role', 'button'); door.tabIndex = 0;
    const openRecap = () => { plSetTab('planner'); document.getElementById(PLANNER_ID)?.scrollIntoView({ behavior: 'smooth', block: 'start' }); };
    door.addEventListener('click', openRecap);
    door.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openRecap(); } });
    foot.append(door);
    box.append(foot);
    if (existing) existing.replaceWith(box); else side.prepend(box);
    fitAll(box);
    renderFold();
    if (sprite) placeSprite();
    return;
  } else {
    // The week, said once, here (BetterCampus's widget leads with "17 tasks
    // due this week", the line students quoted): what is due, and what is
    // finished when anything is. Nothing finished is not a scold.
    const due = Math.max(0, w.total - w.done);
    const words = w.total === 0 ? 'Nothing due this week'
      : `${due === 0 ? 'All in' : `${due} due`} this week${w.done ? ` · ${w.done} finished` : ''}`;
    foot.append(el('span', '', words));
  }
  const more = el('span', 'more', plTab === 'planner' ? '' : 'Open the planner');
  more.setAttribute('role', 'button'); more.tabIndex = plTab === 'planner' ? -1 : 0;
  const openWeek = () => { plSetTab('planner'); document.getElementById(PLANNER_ID)?.scrollIntoView({ behavior: 'smooth', block: 'start' }); };
  more.addEventListener('click', openWeek);
  more.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openWeek(); } });
  foot.append(more);
  if (foot.textContent.trim()) box.append(foot);
  if (existing) existing.replaceWith(box); else side.prepend(box);
  fitAll(box);
  renderFold();
  if (sprite) placeSprite();
}

// MARK: - Next in this class: the course home's own three rows (A3)
//
// A student lands on a course home from a link and wants "what's due here".
// Up to three rows in the rail's shape, filtered to this class, at the top of
// the sidebar; Canvas's own To Do folds under them as it does on the dashboard.
// Nothing at all when the class has nothing pending.

const COURSE_NEXT_ID = 'pk-course-next';

function courseId() {
  return /^\/courses\/(\d+)\/?$/.exec(location.pathname)?.[1] ?? null;
}

function courseNextShows() {
  const id = courseId();
  return !!id && !!document.getElementById('right-side') && !!skin.cards && !killed && !putBack['course-next']
    && (data.tasks ?? []).some((t) => String(t.courseId) === id && !isDone(t) && !isStaleMissing(t));
}

function renderCourseNext() {
  const existing = document.getElementById(COURSE_NEXT_ID);
  if (!courseNextShows()) { existing?.remove(); return; }
  const now = new Date();
  const id = courseId();
  const rows = dueRowsFor(id, now, 3).filter((r) => !r.done);
  const key = JSON.stringify(rows.map((r) => [r.t.id, r.when, r.overdue, r.t.doneAt]));
  if (existing && existing.dataset.key === key) return;
  const box = el('section', '', null);
  box.id = COURSE_NEXT_ID; box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: next in this class');
  box.append(el('p', 'pk-w-label', 'Next in this class'));
  const list = el('ul', 'pk-w-list');
  for (const r of rows) {
    const li = el('li');
    li.append(tickCircle(r.t));
    const url = safeURL(r.t.url);
    const name = url ? el('a', '', r.t.title) : el('b', '', r.t.title);
    if (url) name.href = url;
    name.className = 'pk-cn-name pk-fit';
    name.title = r.t.title;
    // The sidebar is narrow: one word for the day, amber when it slipped.
    li.append(name, el('small', r.overdue ? 'amber' : '', dayShort(r.t, now)));
    list.append(li);
  }
  box.append(list);
  if (existing) existing.replaceWith(box); else document.getElementById('right-side').prepend(box);
  fitAll(box);
}

/// Canvas's own To Do and Coming Up are replaced by the rail and the planner
/// (the `todo-fold` receipt row; Put back brings them back for good). The
/// stylesheet does the hiding; nothing is left to draw here.
function renderFold() {
  document.getElementById(FOLD_ID)?.remove();
}

/// Canvas draws most of a page after it loads and redraws parts of it on its
/// own schedule — the sidebar arrives by XHR, the cards by React, the planner
/// on navigation. One debounced observer plus Canvas's own navigation events
/// re-read the page and re-apply whatever depends on what is there.
let pageObserver = null;
let pageTimer = null;
function refreshPage() {
  if (tornDown) return;
  applySkin(skin);
  ensureStylesheet();
  decorateCards();
  decorateLists();
  for (const pass of PAGE_PASSES) pass();
  renderWeek();
  renderCourseNext();
  renderSearchChip();
  renderPlannerTabs();
  renderPlanner();
  renderGradesPage();
  renderLooks();
  renderPastFold();
  if (sprite) mountSprite();
}
function watchPage() {
  if (pageObserver) return;
  const schedule = () => { if (tornDown) return; clearTimeout(pageTimer); pageTimer = setTimeout(refreshPage, 200); };
  // Our own nodes — the buddy's host and the card lines — must not count as
  // the page changing, or every pass would schedule the next one forever.
  const ours = (n) => n.nodeType === 1 && (n.id === ROOT_ID || n.id === SPRITE_ID || n.id === WEEK_ID || n.id === FOLD_ID || n.id === SEARCH_ID || n.id === PLANNER_ID || n.id === PLANNER_TABS_ID || n.id === LOOKS_ID || n.id === 'pk-theme-vars' || n.classList.contains(CARD_DUE_CLASS) || !!n.closest?.(`#${ROOT_ID}, #${SPRITE_ID}, #${WEEK_ID}, #${FOLD_ID}, #${SEARCH_ID}, #${PLANNER_ID}, #${PLANNER_TABS_ID}, #${LOOKS_ID}, .${CARD_DUE_CLASS}`));
  pageObserver = new MutationObserver((records) => {
    const current = document.documentElement.dataset.pkInstance;
    if (shouldStepAside({ mine: instanceId, current, alive: alive() })) { teardown(); return; }
    const theirs = records.filter((r) => r.type === 'childList')
      .some((r) => !ours(r.target) || [...r.addedNodes, ...r.removedNodes].some((n) => !ours(n)));
    if (theirs) schedule();
  });
  pageObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-pk-instance'], childList: true, subtree: true });
  document.addEventListener('canvasReadyStateChange', schedule);
  window.addEventListener('popstate', schedule);
  window.addEventListener('hashchange', schedule);
}


// MARK: - Sprout, on the page
//
// The same character the phone draws: the app's Sprout web build, shipped in
// extension/sprout/ and run in a frame of the extension's own origin. No
// bubble, no card — he sits on the bottom edge of the page the way a desktop
// pet sits on a dock, with the panel's launcher laid over him for the click.
// The frame lives in its own host because the panel redraws with innerHTML,
// and a frame that is moved or rebuilt reloads.

const SPRITE_ID = 'prepkin-sprout';
let sprite = null;   // { host, frame, url, ready, queue, place }
let spriteListening = false;

/// Where he lives. Canvas's global nav is a fixed, full-height rail that is
/// empty below its menu on every page, and it already wears our theme, so
/// the slot above its collapse toggle is his: nothing scrolls under him
/// there, the way Toggl or Slack keep the bottom of the rail for the person.
/// On a page with no rail (a phone-width window, an LTI tool) he falls back
/// to the bottom right, smaller.
/// Where he lives: in the tank above the week card by default. `rail`,
/// `perch` and `corner` are the other candidates from the placement round.
function buddyMode() { return ['tank', 'perch', 'corner'].includes(skin.buddyPlace) ? skin.buddyPlace : 'tank'; }

function spritePlace() {
  const mode = buddyMode();
  // Above the week card, Finch-style: a water band at the top of our own rail
  // card, the to-do list flowing under him. Only where the card is.
  // Canvas's List View keeps the sidebar in the DOM and hides it, so the card
  // can be there with no size; a tank you cannot see is no tank, and he takes
  // the corner (George, 2026-09-17: "the mascot is not there in list view").
  const weekEl = (mode === 'tank' || mode === 'perch') ? document.getElementById(WEEK_ID) : null;
  const week = weekEl && weekEl.getBoundingClientRect().width > 0 ? weekEl : null;
  if (week) {
    const band = week.querySelector('.pk-w-tank') ?? week;
    const r = band.getBoundingClientRect();
    // The frame is the band's width, so the launcher and its badge sit on the
    // band's own corners; 30 is the biggest radius the band's height allows.
    const radius = mode === 'tank' ? 30 : 26, w = Math.round(r.width), h = 200;
    const cx = r.left + scrollX + r.width / 2;
    // Feet on the band's floor (tank) or on the card's top edge (perch).
    const feet = mode === 'tank' ? r.bottom + scrollY - 8 : r.top + scrollY + 6;
    return { side: 'tank', mode, navW: w, bottom: 0, radius, w, h, abs: { left: Math.round(cx - w / 2), top: Math.round(feet - h) } };
  }
  // Everywhere else: the bottom right corner, where most apps keep a helper,
  // small. He used to take the foot of Canvas's global nav, which on a school
  // with a tall nav (Dartmouth: History, Disability Resources, Help) sat him
  // on top of Help (George, 2026-09-17). The corner is nobody's button.
  return { side: 'right', mode, navW: 0, bottom: 0, radius: 28, w: 140, h: 215 };
}

/// The five tanks the phone's Home can show; the band paints the one the phone
/// named, or the first one until a phone is linked.
const TANKS = ['lagoon', 'reef', 'kelp', 'dusk', 'deep'];
function tankId() {
  const id = String(wallet.kin?.scene ?? '');
  return TANKS.includes(id) ? id : 'lagoon';
}

/// Old species ids from the first app builds, onto the six coats Sprout has.
const COAT_OF = { ember: 'coral', mochi: 'coral', droplet: 'sky', puff: 'sky', wisp: 'lilac', comet: 'butter', sprout: 'peach' };
/// What the phone said its kin is, or the league's word for it, or the default.
function kinLook() {
  const k = wallet.kin;
  const raw = String(k?.species ?? ownSpecies());
  const coat = COAT_OF[raw] ?? (KIN_SPECIES.includes(raw) ? raw : 'mint');
  const evo = Math.min(3, Math.max(1, Number(k?.level) || 2));
  const skin = /^[a-z-]+$/.test(String(k?.skin ?? '')) ? String(k.skin) : 'classic';
  // Only stage three wears a costume; a younger kin always asks for the default.
  const costume = evo >= 3 && skin !== 'classic' ? skin : '';
  return { coat, evo, skin, costume };
}

function spriteURL(radius) {
  const look = kinLook();
  const q = new URLSearchParams({ embed: '1', type: 'sprout', coat: look.coat, evo: String(look.evo), skin: look.skin, radius: String(radius) });
  if (look.costume) q.set('costume', look.costume);
  if (!alive()) return null;
  return `${chrome.runtime.getURL('sprout/index.html')}?${q}`;
}

/// Asks the frame for something. Before the page has said "ready", the ask
/// waits; after, it goes straight through.
function spriteSend(msg) {
  if (!sprite) return;
  if (!sprite.ready) { sprite.queue.push(msg); return; }
  sprite.frame.contentWindow?.postMessage({ prepkin: 'sprout', ...msg }, '*');
}

/// Lays the frame and the panel's launcher over the same spot. Cheap, so it
/// runs on every page pass: the rail collapses and expands without a reload.
function placeSprite(place = spritePlace()) {
  if (!sprite) return;
  const st = sprite.host.style;
  if (place.side === 'tank') {
    st.position = 'absolute'; st.left = `${place.abs.left}px`; st.top = `${place.abs.top}px`; st.right = 'auto'; st.bottom = 'auto';
  } else {
    st.position = 'fixed'; st.top = 'auto'; st.left = 'auto'; st.right = '12px'; st.bottom = '0px';
  }
  st.width = `${place.w}px`; st.height = `${place.h}px`;
  sprite.place = place;
  if (shadow) {
    const h = shadow.host;
    h.dataset.side = place.side;
    h.style.setProperty('--pk-nav-w', `${place.side === 'tank' ? place.w : (place.navW || place.w)}px`);
    h.style.setProperty('--pk-tab-h', `${place.side === 'tank' ? 108 : Math.round(place.h * 0.62)}px`);
    h.style.setProperty('--pk-tab-bottom', '0px');
    if (place.side === 'tank') {
      // The panel takes the column to his left (360 + 12), so the launcher
      // lands on the band. With no room there — Canvas read right-to-left
      // puts the sidebar on the left edge — it takes the column to his right
      // instead; off the page's edge it was a sideways scroll on every page.
      const flip = place.abs.left - 372 < 0;
      h.toggleAttribute('data-flip', flip);
      h.style.position = 'absolute'; h.style.left = `${flip ? place.abs.left : place.abs.left - 372}px`; h.style.top = `${place.abs.top + place.h - 108}px`; h.style.right = 'auto'; h.style.bottom = 'auto';
    } else {
      h.removeAttribute('data-flip');
      h.style.position = ''; h.style.left = ''; h.style.top = ''; h.style.right = ''; h.style.bottom = '';
    }
  }
}

/// The moment they both show: him, and the card he stands above.
function revealSprite() {
  if (sprite) sprite.host.style.opacity = '1';
  document.getElementById(WEEK_ID)?.classList.remove('pk-w-waiting');
}

function mountSprite() {
  const place = spritePlace();
  const url = spriteURL(place.radius);
  if (!url) return;
  if (sprite && sprite.url === url && document.getElementById(SPRITE_ID)) { placeSprite(place); return; }
  unmountSprite();
  const host = document.createElement('div');
  host.id = SPRITE_ID;
  const root = host.attachShadow({ mode: 'closed' });
  const style = document.createElement('style');
  style.textContent = `:host{position:fixed;z-index:2147482999;pointer-events:none;}
iframe{display:block;width:100%;height:100%;border:0;background:transparent;color-scheme:normal;}`;
  const frame = document.createElement('iframe');
  frame.src = url;
  frame.title = 'Sprout';
  frame.setAttribute('aria-hidden', 'true');
  frame.tabIndex = -1;
  frame.allowTransparency = true;
  root.append(style, frame);
  // He and his card arrive together: the frame stays clear until the rig says
  // ready (a few hundred ms), and the rail card waits with it; a slow rig
  // never holds the list back more than 1.5 s (George, 2026-09-17: the box
  // and the water came first, then him).
  host.style.opacity = '0'; host.style.transition = 'opacity .2s ease';
  document.body.append(host);
  sprite = { host, frame, url, ready: false, queue: [], place, mountedAt: Date.now() };
  document.getElementById(WEEK_ID)?.classList.add('pk-w-waiting');
  setTimeout(() => revealSprite(), 1500);
  placeSprite(place);
  if (!spriteListening) {
    spriteListening = true;
    window.addEventListener('message', (e) => {
      if (!sprite || e.source !== sprite.frame.contentWindow || e.data?.prepkin !== 'sprout' || e.data.event !== 'ready') return;
      sprite.ready = true;
      revealSprite();
      spriteSend({ do: 'reduceMotion', value: matchMedia('(prefers-reduced-motion: reduce)').matches });
      spriteSend({ do: 'paused', value: document.visibilityState === 'hidden' });
      for (const m of sprite.queue.splice(0)) spriteSend(m);
    });
    document.addEventListener('visibilitychange', () => spriteSend({ do: 'paused', value: document.visibilityState === 'hidden' }));
    window.addEventListener('resize', () => { if (sprite) mountSprite(); });
  }
}

function unmountSprite() {
  document.getElementById(SPRITE_ID)?.remove();
  sprite = null;
}


// MARK: - The term, in numbers
//
// Once, when a term ends. The card lives on the Planner tab; this saves the
// picture, which carries course names and counts, never a grade.

/// The picture: paper, the big number, the lines, the course bars. Drawn on a
/// canvas of our own and handed to the browser as a download, so nothing
/// leaves the page and nothing on the page is touched.
function saveRecapPicture(now) {
  const r = termRecap(data.tasks, now, data.graded, data.courses);
  const W = 1080, H = 1350, pad = 88;
  const cv = document.createElement('canvas'); cv.width = W; cv.height = H;
  const g = cv.getContext('2d');
  const font = (w, s) => `${w} ${s}px ui-rounded, "SF Pro Rounded", -apple-system, system-ui, sans-serif`;
  g.fillStyle = '#F7F6F3'; g.fillRect(0, 0, W, H);
  g.fillStyle = '#51CFA0'; g.fillRect(0, 0, W, 28);
  g.fillStyle = '#776D62'; g.font = font(800, 30); g.textBaseline = 'top';
  const fmt = (d) => d.toLocaleDateString([], { month: 'short', day: 'numeric' });
  g.fillText(`MY TERM${r.firstDue && r.lastDue ? ` · ${fmt(r.firstDue).toUpperCase()} TO ${fmt(r.lastDue).toUpperCase()}` : ''}`, pad, 120);
  g.fillStyle = '#1B1F24'; g.font = font(900, 220); g.fillText(String(r.handedIn), pad - 8, 170);
  g.font = font(800, 56); g.fillText(`thing${r.handedIn === 1 ? '' : 's'} handed in`, pad, 396);
  let y = 496; g.font = font(600, 40); g.fillStyle = '#454B54';
  const lines = [
    r.onTimePct !== null ? `${r.onTimePct}% on time` : null,
    r.busiestWeek ? `Busiest week: ${fmt(r.busiestWeek.start)} to ${fmt(r.busiestWeek.end)}` : null,
    r.hour ? `Handed in most often around ${hourLabel(r.hour.hour)}` : null,
  ].filter(Boolean);
  for (const l of lines) { g.fillText(l, pad, y); y += 62; }
  y += 40;
  for (const c of r.byCourse.slice(0, 6)) {
    g.fillStyle = '#1B1F24'; g.font = font(800, 38); g.fillText(shortCourse(c.name), pad, y);
    g.fillStyle = '#776D62'; g.font = font(700, 34); g.textAlign = 'right'; g.fillText(`${c.done} of ${c.total}`, W - pad, y + 4); g.textAlign = 'left';
    g.fillStyle = '#E3E0D9'; g.fillRect(pad, y + 56, W - 2 * pad, 16);
    g.fillStyle = safeColor(c.colorHex) ?? '#51CFA0'; g.fillRect(pad, y + 56, Math.round((W - 2 * pad) * (c.total ? c.done / c.total : 0)), 16);
    y += 108;
  }
  g.fillStyle = '#776D62'; g.font = font(700, 30); g.fillText('Prepkin for Canvas', pad, H - 120);
  cv.toBlob((blob) => {
    if (!blob) return;
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = 'my-term.png';
    document.body.append(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 5000);
  }, 'image/png');
}

// MARK: - Render

function render() {
  if (shadow) { shadow.host.toggleAttribute('data-open', ui.open); shadow.host.dataset.view = ui.view; }
  if (shadow && sprite) placeSprite(sprite.place);
  // His line is on the rail; while the palette is open beside it, it steps back.
  document.getElementById(WEEK_ID)?.classList.toggle('pk-w-quiet', !!ui.open);
  if (!shadow) return;
  const root = shadow;
  const now = new Date();
  const b = buckets(data.tasks ?? [], now, plannedOn);
  const urgent = b.overdue.length + b.today.length;

  // The buddy is a door and a palette: Command-K opens search, nothing else
  // opens here. The planner, grades and looks are tabs on the dashboard.
  root.innerHTML = `
    ${focus.state === 'done' || (focus.state === 'running' && !railShows()) ? focusCard() : ''}
    <button class="pk-tab" aria-expanded="${ui.open}" aria-controls="pk-panel" aria-label="Prepkin${urgent ? `, ${urgent} to do` : ''}">
      ${ui.float && Date.now() - ui.float < 2500 ? `<span class="pk-float" aria-hidden="true">${COIN_SVG}+${COIN_REWARD}</span>` : ''}
    </button>
    <div class="pk-panel" id="pk-panel" role="dialog" aria-modal="false" aria-label="${ui.view === 'search' ? 'Search' : 'Prepkin'}" tabindex="-1" ${ui.open ? '' : 'hidden'}>
      <div class="pk-body">${ui.open ? (ui.view === 'search' ? searchView() : helpView()) : ''}</div>
    </div>`;

  // innerHTML detached the stylesheet; the node itself survives, so putting it
  // back costs nothing and never refetches.
  root.prepend(styleEl);
  wire(root);
  const scroller = root.querySelector('.pk-panel');
  // Opening the panel moves focus into it. Without this a keyboard has to tab
  // back through the whole Canvas page to reach what it just opened.
  if (ui.open && !wasOpen && scroller) scroller.focus({ preventScroll: true });
  wasOpen = ui.open;
}

/// Command-K (Control-K elsewhere) opens search from anywhere on the page.
if (typeof window !== 'undefined' && typeof chrome !== 'undefined' && chrome.storage) {
  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && !e.altKey && !e.shiftKey && e.key.toLowerCase() === 'k' && shadow && skin.mascot !== false) {
      e.preventDefault(); e.stopPropagation();
      ui.open = true; ui.view = 'search'; ui.query = ''; render();
    }
  }, true);
}

/// One task, one day, or none. Kept out of the payload the phone reads: the
/// app has its own day, and a plan the student made on a laptop at 11 PM is
/// nobody else's business.
async function setPlan(id, key) {
  const next = { ...plans };
  if (key) next[id] = key; else delete next[id];
  plans = next;
  await chrome.storage.local.set({ plans });
  render();
  // The rail counts the same day the panel does, so it has to be redrawn
  // here: nothing else in this tab will.
  renderWeek();
}

function wire(root) {
  const tab = root.querySelector('.pk-tab');
  tab?.addEventListener('click', () => {
    // A click opens his help: his line, the thing to start, the next few,
    // this class's next three, the doors. Open already: it closes. The
    // palette is Command-K (George, 2026-09-17: "he should actually help").
    if (ui.open) { closePalette(); return; }
    spriteSend({ do: 'play', emote: 'wave' });
    ui.open = true; ui.view = 'help'; ui.query = ''; render();
  });
  tab?.addEventListener('mouseenter', () => { if (!ui.open) spriteSend({ do: 'play', emote: 'curious' }); });
  // Escape closes the palette and hands focus back to the buddy rather than
  // dropping it on the page behind.
  root.querySelector('.pk-panel')?.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    e.stopPropagation();
    closePalette();
    shadow?.querySelector('.pk-tab')?.focus();
  });
  const q = root.querySelector('#pk-q');
  if (q) {
    q.addEventListener('input', () => { ui.query = q.value; root.querySelector('.pk-results').innerHTML = resultsHTML(ui.query); });
    q.addEventListener('keydown', (e) => {
      const items = [...root.querySelectorAll('.pk-results li:not(.empty):not(.pk-group)')];
      const at = items.findIndex((li) => li.classList.contains('on'));
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault();
        const next = items[(at + (e.key === 'ArrowDown' ? 1 : items.length - 1)) % Math.max(1, items.length)];
        items.forEach((li) => li.classList.remove('on')); next?.classList.add('on');
      } else if (e.key === 'Enter') {
        e.preventDefault();
        const href = (items[at] ?? items[0])?.querySelector('a')?.getAttribute('href');
        if (href) location.assign(href);
      } else if (e.key === 'Escape') { closePalette(); }
    });
    q.focus();
  }
  // The help view: Focus on the first thing, and the door to search.
  root.querySelector('[data-focus-first]')?.addEventListener('click', (e) => {
    if (!e.isTrusted || !alive()) return;
    const t = (data.tasks ?? []).find((x) => String(x.id) === e.currentTarget.dataset.focusFirst);
    if (t && alive()) chrome.runtime.sendMessage({ type: 'focus-start', taskId: t.id, title: t.title, url: t.url, minutes: skin.focusMinutes });
    closePalette();
  });
  root.querySelector('[data-help-search]')?.addEventListener('click', () => { ui.view = 'search'; ui.query = ''; render(); });
  // The focus card's buttons. A script on the page can fire a click at one;
  // only a real click reaches the worker.
  root.querySelector('[data-focus-extend]')?.addEventListener('click', (e) => {
    if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-extend' });
  });
  root.querySelector('[data-focus-stop]')?.addEventListener('click', (e) => {
    if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-stop' });
  });
  root.querySelector('[data-focus-clear]')?.addEventListener('click', (e) => {
    if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-clear' });
  });
}

function closePalette() { ui.open = false; ui.query = ''; render(); }

/// Wearing a look is local and instant; spending the coins is the phone's call.
/// The extension only files the request — the app's ledger stays the truth.
async function buy(id) {
  const look = LOOKS_BY_ID[id];
  if (!look) return;
  const owned = look.free || wallet.owned.includes(id);
  // The button was disabled if this was not affordable, but the wallet can
  // change between paint and click. A known balance that cannot cover it stops
  // here; an unknown one is still the phone's call.
  if (!owned && typeof wallet.coins === 'number' && wallet.coins < look.price) return;
  wallet = {
    ...wallet,
    wearing: id,
    owned: owned ? wallet.owned : [...wallet.owned, id],
    coins: owned || wallet.coins === null ? wallet.coins : wallet.coins - look.price,
  };
  await chrome.storage.local.set({ wallet });
  if (!alive()) return;
  if (!owned) await chrome.runtime.sendMessage({ type: 'spend', lookId: id, price: look.price });
  applySkin(skin);
  render();
}

/// Canvas content is other people's text. It goes in as text, never as markup.
function escapeHTML(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// MARK: - Boot

let ticker = null;
/// The panel's own root. Null until mount() builds it, and unreachable from the
/// page — every read and write below goes through this handle.
let shadow = null;
let styleEl = null;
let panelCSS = null;

/// panel.css, inlined rather than linked: a <link> loads asynchronously and the
/// tab would flash unstyled on every page. Fetched once per page, then reused.
function panelStyle(host) {
  const el = document.createElement('style');
  if (panelCSS !== null) { el.textContent = panelCSS; return el; }
  // Until the stylesheet is in, the host stays hidden. An unstyled panel is a
  // full-width stack of raw text across somebody's coursework, which is worse
  // than not showing up at all.
  host.style.display = 'none';
  if (!alive()) return null;
  fetch(chrome.runtime.getURL('panel.css'))
    .then((r) => (r.ok ? r.text() : Promise.reject(new Error(String(r.status)))))
    .then((css) => { panelCSS = css; el.textContent = css; host.style.display = ''; })
    .catch((e) => {
      console.warn('Prepkin: could not load panel.css, leaving the page alone', e);
      host.remove();
    });
  return el;
}

async function mount() {
  if (tornDown || !alive()) return;
  skin = await settings();
  const stored = await chrome.storage.local.get(['lastPayload', 'wallet', 'focus', 'putBack', 'levels', 'banners', 'cardArt', 'nicknames', 'ownTasks', 'plans', 'targets', 'flags', 'celebrated', 'dashTab', 'done', 'recapDismissed', 'soFarDismissed', 'ownArt', HANDED_IN_KEY]);
  if (tornDown || !alive()) return;
  nicknames = stored.nicknames ?? {};
  ownTasks = Array.isArray(stored.ownTasks) ? stored.ownTasks : [];
  done = stored.done && typeof stored.done === 'object' ? stored.done : {};
  recapDismissed = typeof stored.recapDismissed === 'string' ? stored.recapDismissed : null;
  soFarDismissed = typeof stored.soFarDismissed === 'string' ? stored.soFarDismissed : null;
  data = composeData(stored.lastPayload ?? null, ownTasks, nicknames, done);
  levels = stored.levels ?? {};
  plans = stored.plans ?? {};
  targets = stored.targets ?? {};
  banners = stored.banners ?? {};
  cardArt = stored.cardArt ?? {};
  ownArt = stored.ownArt && typeof stored.ownArt.src === 'string' ? stored.ownArt : null;
  putBack = stored.putBack ?? {};
  flags = stored.flags ?? null;
  wallet = { ...wallet, ...(stored.wallet ?? {}) };
  if (!LOOKS_BY_ID[wallet.wearing]) wallet.wearing = 'classic'; // a look that no longer exists
  focus = stored.focus ?? { state: 'idle' };
  celebrated = typeof stored.celebrated === 'string' ? stored.celebrated : null;

  applySkin(skin);
  decorateCards();
  decorateLists();
  for (const pass of PAGE_PASSES) pass();
  renderWeek();
  renderCourseNext();
  renderSearchChip();
  // The planner tab: remembered, and #planner in the address opens it.
  plTab = location.hash === '#planner' ? 'planner' : location.hash === '#looks' ? 'looks' : (['planner', 'looks'].includes(stored.dashTab) ? stored.dashTab : 'cards');
  renderPlannerTabs();
  renderPlanner();
  renderLooks();
  renderPastFold();
  watchPage();
  if (!handInWatched) { handInWatched = true; watchHandIn(); syncIfJustHandedIn(stored); }

  clearInterval(ticker);
  ticker = setInterval(() => { if (!alive()) return; tickClocks(); }, 1000);

  document.getElementById(ROOT_ID)?.remove();
  shadow = null;
  // The sign-in page is the school's alone: no paper, no buddy.
  if (!skin.mascot || remoteKilled || isLoginPath(location.pathname) || isQuizTake(location.pathname) || isSubmissionPath(location.pathname, location.hash)) { unmountSprite(); return; }
  mountSprite();

  const host = document.createElement('div');
  host.id = ROOT_ID;
  // Closed, because the panel holds the student's grades for every school they
  // connected. In the page's own DOM any script on Canvas — a school's global
  // theme JS, a teacher's HTML, an embedded tool — could read the lot with one
  // querySelector. A closed root also stops a school's CSS reaching in.
  shadow = host.attachShadow({ mode: 'closed' });
  styleEl = panelStyle(host);
  if (!styleEl) return;
  shadow.append(styleEl);
  document.body.append(host);
  render();

}

// Per-page passes that write data-pk-* attributes for CSS to draw (never
// Canvas's words). One function per parallel session, each edited only inside
// its own marker pair; the list is fixed so nobody touches a shared line.
// ---- Session C pass (course home, page, assignment, quiz) ----
function passC() {}
// ---- end Session C ----
// ---- Session D pass (all courses, files, people, syllabus) ----
function passD() {}
// ---- end Session D ----
// ---- Session E pass (calendar, inbox) ----
function passE() {}
// ---- end Session E ----
// ---- Session F pass (discussions, settings) ----
function passF() {}
// ---- end Session F ----
const PAGE_PASSES = [passC, passD, passE, passF];

if (typeof module !== 'undefined') {
  // `node --test` reads the pure parts; the page never sees this branch.
  module.exports = { startOfDay, sameLocalDay, buckets, dueLabel, submittedLabel, voice, dayKey, dayFromKey, planDay, isMoved, missingCost,
                     targetsFor, safeURL, escapeHTML, sparkline, LETTERS, nextUpFor, LEVELS, composeData, searchItems, searchRank, searchGroups, dayShort, tankId, TANKS, ownSpecies, KIN_SPECIES,
                     searchView, focusCard,
                     _setData: (d) => { data = d; }, _setWallet: (w) => { wallet = w; }, _setFocus: (f) => { focus = f; }, _setSkin: (k) => { skin = { ...skin, ...k }; }, _ui: ui, _setLevels: (l) => { levels = l; } };
} else {
  // A fresh sync, a toggle, a purchase or a Put back should show up without a reload.
  chrome.storage.onChanged.addListener((changes) => {
    // The timer ran out, or a sync found something newly handed in: the buddy
    // cheers before the page says so. Real work, real reaction, nothing else.
    if (changes.focus?.oldValue?.state === 'running' && changes.focus?.newValue?.state === 'done') spriteSend({ do: 'play', emote: 'cheer' });
    const handedIn = (p) => (p?.tasks ?? []).filter((t) => t.submittedAt).length;
    if (changes.lastPayload?.oldValue && handedIn(changes.lastPayload.newValue) > handedIn(changes.lastPayload.oldValue)) {
      spriteSend({ do: 'play', emote: 'cheer' });
      // And the number: what the phone will pay for it, floating up from him.
      ui.float = Date.now();
    }
    if (changes.lastPayload || changes.skin || changes.wallet || changes.focus || changes.putBack || changes.banners || changes.cardArt || changes.ownArt || changes.nicknames || changes.ownTasks || changes.done || changes.flags) mount();
    // Not plans, levels or targets: the tab that set one has already redrawn,
    // and a remount here would throw the student back to the top of the panel
    // they just tapped in.

  });
  // The popup asks this page for its receipt, and asks it to show what it changed.
  chrome.runtime.onMessage.addListener((msg, sender, respond) => {
    if (!msg || sender.id !== chrome.runtime.id) return;
    if (msg.type === 'receipt') respond(receiptForPage());
    if (msg.type === 'show-me') { showMe(); respond({ ok: true }); }
    if (msg.type === 'open-buddy') {
      if (plannerShows()) { plSetTab('planner'); respond({ ok: true }); }
      else { location.assign('/#planner'); respond({ ok: true }); }
    }
  });
  mount();
}
}
