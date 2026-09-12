// Runs on a connected Canvas page: applies the skin and puts Sprout on screen.
//
// Injected on demand by background.js once you connect a site, so it never runs
// anywhere you have not approved.

{

if (typeof module !== 'undefined') {
  // Under node the sibling scripts are modules, not page globals.
  Object.assign(globalThis, require('./receipt.js'), require('./themes.js'), require('./art/manifest.js'), require('./selectors.js'), require('./looks.js'), require('./canvas.js'), require('./day.js'), require('./podnames.js'), require('./recap.js'));
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
let prevView = 'panel';
/// Whether the panel was open on the last draw, so focus moves in once, on the
/// draw that opened it, and never again while the student is typing.
let wasOpen = false;
const ui = {
  open: false, view: 'panel', filter: null, expanded: null,
  target: null, askWeight: null, sheet: null,
  planning: null, courseFilter: 'all',
};
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

/// The last sync plus the student's own tasks, with nicknames applied to every
/// course name. The payload itself is never changed, so nothing invented is
/// ever pushed to the phone.
function composeData(payload, own = [], nick = {}) {
  const base = payload ?? { tasks: [], courses: [], graded: {}, weights: {} };
  const name = (id, fallback) => (id != null && nick[String(id)]) || fallback;
  const courses = (base.courses ?? []).map((c) => ({ ...c, fullName: c.name, name: name(c.id, c.name) }));
  const mine = own.map((t) => ({ ...t, own: true, courseId: t.courseId ?? 'own', courseName: t.courseName || 'My tasks' }));
  const tasks = [...(base.tasks ?? []), ...mine].map((t) => ({ ...t, courseName: name(t.courseId, t.courseName ?? '') }));
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
    if (url) items.push({ kind: 'task', label: t.title, sub: `${t.courseName}${t.dueAt ? ' · ' + dueLabel(t, new Date()) : ''}`, url, dueAt: t.dueAt ?? null, done: !!t.submittedAt });
  }
  return items;
}
/// Before a word is typed, the palette is grouped the way Linear's and Causal's
/// are: your classes, what is due soonest, then Canvas's own pages. Typing
/// turns it into one ranked list.
function searchGroups(items) {
  const soon = items.filter((i) => i.kind === 'task' && !i.done && i.dueAt)
    .sort((a, b) => Date.parse(a.dueAt) - Date.parse(b.dueAt)).slice(0, 3);
  return [
    ['Classes', items.filter((i) => i.kind === 'course').slice(0, 6)],
    ['Due soon', soon],
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
    // Canvas's To Do folds only under our rail: with no rail there is no
    // other list, and a page with no to-do list is not calmer.
    todoFold: (has('todoReact') || has('todoLegacy')) && railShows(),
    wordPaste: WORD_INKS.some((ink) =>
      document.querySelector(`.user_content [style*="color:${ink}" i], .user_content [style*="color: ${ink}" i]`)),
  };
}

/// What the student has put back, by receipt key. From storage; the popup writes it.
let putBack = {};
let facts = {};

/// The skin is a set of classes on <html>, nothing else — no inline property is
/// ever written, so taking every class away leaves Canvas, unchanged. boot.js
/// put a first guess on before paint; this is the same answer with the DOM read.
function applySkin(s) {
  const root = document.documentElement;
  killed = detectKill();
  facts = detectFacts();
  const look = LOOKS_BY_ID[wallet.wearing] ?? LOOKS_BY_ID.classic;
  const next = new Set(killed ? [] : skinClasses({ on: !!s.cards, dark: !!s.dark, dense: !!s.dense, hidePast: !!s.hidePast, look, putBack, detect: facts }));
  for (const c of [...root.classList]) {
    if (c.startsWith('pk-') && c !== 'pk-show' && c !== 'pk-todo-open' && !next.has(c)) root.classList.remove(c);
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
  const css = themeStyle(look, textureImage, artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f)));
  if (style.textContent !== css) style.textContent = css;
}

/// The receipt for this page, for the popup.
function receiptForPage() {
  const look = LOOKS_BY_ID[wallet.wearing] ?? LOOKS_BY_ID.classic;
  return {
    page: pageName(location.pathname),
    off: killed,
    on: !!skin.cards,
    rows: killed || !skin.cards ? [] : receiptRows({
      present: (k) => document.querySelectorAll(SELECTORS[k].sel).length,
      detect: facts, dark: !!skin.dark, mascot: !!skin.mascot, cardGrades: !!skin.cardGrades, dense: !!skin.dense, hidePast: !!skin.hidePast, nicknames: Object.keys(nicknames).length, ownArt: Object.keys(cardArt).length, search: skin.search !== false,
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

function checkSVG(size = 18) {
  return `
  <svg width="${size}" height="${size}" viewBox="0 0 16 16" aria-hidden="true">
    <circle cx="8" cy="8" r="8" fill="#51CFA0"/>
    <path d="M4.6 8.3 L7 10.6 L11.4 5.6" stroke="#101820" stroke-width="1.9"
          fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
}

function chevronSVG(dir = 'right') {
  const d = { right: 'M5 3 L10 7 L5 11', left: 'M9 3 L4 7 L9 11',
              down: 'M3 5 L7 10 L11 5', up: 'M3 10 L7 5 L11 10' }[dir];
  return `<svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
    <path d="${d}" stroke="currentColor" stroke-width="2" fill="none"
          stroke-linecap="round" stroke-linejoin="round"/></svg>`;
}

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

function gpa(courses, levelsByCourse = {}) {
  const scored = courses.filter((c) => typeof c.score === 'number');
  if (!scored.length) return null;
  // Unweighted 4.0 on the usual US cutoffs. Shown as an estimate, because a
  // school's real scale is its own business and Canvas does not publish it.
  const points = scored.map((c) =>
    c.score >= 93 ? 4.0 : c.score >= 90 ? 3.7 : c.score >= 87 ? 3.3 : c.score >= 83 ? 3.0
    : c.score >= 80 ? 2.7 : c.score >= 77 ? 2.3 : c.score >= 73 ? 2.0 : c.score >= 70 ? 1.7
    : c.score >= 67 ? 1.3 : c.score >= 65 ? 1.0 : 0);
  const avg = (xs) => (xs.reduce((a, b) => a + b, 0) / xs.length).toFixed(2);
  const bumps = scored.map((c) => LEVELS[levelsByCourse[c.id]] ?? 0);
  const weighted = bumps.some((b) => b > 0)
    ? avg(points.map((pt, i) => (pt > 0 ? pt + bumps[i] : 0))) : null;
  return { unweighted: avg(points), weighted };
}

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

function startButton(t, soft) {
  const url = safeURL(t.url);
  if (!url) return '';
  return `<a class="pk-start${soft ? ' soft' : ''}" href="${escapeHTML(url)}">Start</a>`;
}

function taskRow(t, { now, state }) {
  if (state === 'done') {
    return `
      <li class="done">
        <span class="pk-tick">${checkSVG(18)}</span>
        <div><b>${escapeHTML(t.title)}</b><small>${t.own ? 'done' : submittedLabel(t)}</small></div>
        ${t.own ? `<button class="pk-x" data-own-remove="${escapeHTML(t.id)}" aria-label="Remove">×</button>` : `<span class="pk-plus">${COIN_SVG}+${COIN_REWARD}</span>`}
      </li>`;
  }
  if (t.own) {
    const color = safeColor(t.colorHex);
    return `
      <li class="${state === 'overdue' ? 'overdue' : ''} own">
        <span class="pk-dot"${state !== 'overdue' && color ? ` style="background:${escapeHTML(color)}"` : ''}></span>
        <div><b>${escapeHTML(t.title)}</b>
             <small>${escapeHTML(shortCourse(t.courseName))} · ${dueLabel(t, now)}</small></div>
        <button class="pk-done" data-own-done="${escapeHTML(t.id)}">Done</button>
        <button class="pk-x" data-own-remove="${escapeHTML(t.id)}" aria-label="Remove">×</button>
      </li>`;
  }
  const overdue = state === 'overdue';
  // The dot is the course's own Canvas colour, so the eye lands by colour the
  // way it does on the dashboard. Slipped work gets the amber ring instead.
  const color = safeColor(t.colorHex);
  return `
    <li class="${overdue ? 'overdue' : ''}">
      <span class="pk-dot"${!overdue && color ? ` style="background:${escapeHTML(color)}"` : ''}></span>
      <div><b>${escapeHTML(t.title)}</b>
           <small>${escapeHTML(shortCourse(t.courseName))} · ${overdue ? dueLabel(t, now).replace(' · still counts', '') : dueLabel(t, now)}${isMoved(t) ? ' · you planned this' : ''}</small></div>
      ${overdue ? startButton(t, true) : ''}
    </li>`;
}

/// A planner row: colour bar, title, course and time, points on the right.
function plannerRow(t, now) {
  // Validated again here, not only in the worker: what is in storage today
  // was written by an older version, and this string lands in a style attribute.
  const color = safeColor(t.colorHex) ?? '#C9BCA4';
  const due = t.dueAt ? new Date(t.dueAt) : null;
  const time = due && !isNaN(due)
    ? due.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
    : 'anytime';
  const moved = isMoved(t);
  const dueWord = due && !isNaN(due)
    ? (sameLocalDay(due, now) ? 'due today' : `due ${due.toLocaleDateString([], { weekday: 'short' })}`)
    : 'no due date';
  const slipped = due && !isNaN(due) && due < now && !sameLocalDay(due, now) && !t.submittedAt;
  const when = slipped ? `was due ${due.toLocaleDateString([], { month: 'short', day: 'numeric' })}` : time;
  const sub = t.submittedAt ? 'submitted' : moved ? `${escapeHTML(shortCourse(t.courseName))} · ${dueWord}` : `${escapeHTML(shortCourse(t.courseName))} · ${when}`;
  return `
    <li class="${t.submittedAt ? 'done' : ''}${moved ? ' moved' : ''}"${t.submittedAt ? '' : ` draggable="true" data-drag="${escapeHTML(t.id)}"`}>
      <span class="pk-bar" style="background:${escapeHTML(color)}"></span>
      ${t.submittedAt ? `<span class="pk-tick">${checkSVG(16)}</span>` : ''}
      <div><b>${escapeHTML(t.title)}</b>
           <small>${t.submittedAt ? `${escapeHTML(shortCourse(t.courseName))} · submitted` : sub}</small></div>
      ${t.submittedAt ? (t.pointsPossible ? `<span class="pk-pts">${t.pointsPossible} pts</span>` : '')
        : `<button class="pk-planbtn${plans[t.id] ? ' on' : ''}" data-plan-open="${escapeHTML(t.id)}"
             aria-expanded="${ui.planning === t.id}"
             aria-label="When will you do ${escapeHTML(t.title)}?">${plans[t.id] ? 'Moved' : 'Plan'}</button>`}
    </li>
    ${ui.planning === t.id ? planPicker(t, now) : ''}`;
}

/// Seven days from today, plus a way back. One tap, no calendar, no times —
/// the question is only which day you will sit down, and a time you invent at
/// 11 PM is a time you will not keep.
function planPicker(t, now) {
  const chips = Array.from({ length: 7 }, (_, i) => {
    const d = startOfDay(new Date(now.getTime() + i * DAY_MS));
    const label = i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : d.toLocaleDateString([], { weekday: 'short' });
    const on = plans[t.id] === dayKey(d);
    return `<button type="button" role="radio" aria-checked="${on}" class="${on ? 'on' : ''}"
      data-plan-set="${escapeHTML(t.id)}" data-plan-day="${dayKey(d)}"
      aria-label="${label}, ${d.toLocaleDateString([], { month: 'long', day: 'numeric' })}">${label}</button>`;
  }).join('');
  return `
    <li class="pk-planpick" role="radiogroup" aria-label="What day will you do ${escapeHTML(t.title)}?">
      <span class="pk-planlead" aria-hidden="true">Do it on</span>
      ${chips}
      ${plans[t.id] ? `<button class="clear" data-plan-clear="${escapeHTML(t.id)}">Back to its due date</button>` : ''}
    </li>`;
}

// MARK: - Views

function panelView(b, said, now) {
  const totalToday = b.today.length + b.doneToday.length;
  const pct = totalToday ? Math.round((b.doneToday.length / totalToday) * 100) : 100;
  const filter = ui.filter ?? (b.overdue.length ? 'overdue' : 'today');
  const nextUp = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;

  const rows =
    filter === 'missed' ? b.missed.map((t) => taskRow(t, { now, state: 'overdue' }))
    : filter === 'overdue' ? b.overdue.filter((t) => t !== nextUp).map((t) => taskRow(t, { now, state: 'overdue' }))
    : [
        ...b.today.filter((t) => t !== nextUp).map((t) => taskRow(t, { now, state: 'todo' })),
        ...b.doneToday.map((t) => taskRow(t, { now, state: 'done' })),
      ];

  const filterBtn = (key, label, count, amber) => `
    <button data-filter="${key}" aria-pressed="${filter === key}" class="${filter === key ? `on${amber ? ' amber' : ''}` : ''}">
      ${label}${count ? `<em>${count}</em>` : ''}
    </button>`;

  return `
    <div class="pk-filters">
      ${filterBtn('today', 'Today', totalToday, false)}
      ${filterBtn('week', 'This week', b.week.length, false)}
      ${filterBtn('overdue', 'Overdue', b.overdue.length, true)}
      ${b.missed.length ? filterBtn('missed', 'Missing', b.missed.length, true) : ''}
    </div>
    ${filter === 'missed' ? `<div class="pk-foot">Your school marked these missing. Late work still counts. Teachers take it more often than students ask.</div>${missingCostLines(b.missed)}` : ''}
    ${filter === 'missed' ? '' : nextUp ? nextUpCard(nextUp, now) : ''}
    <ul class="pk-list">${rows.join('') || (nextUp ? '' : '<li class="empty">Nothing here. Enjoy it.</li>')}</ul>
    <div class="pk-listfoot"><button class="pk-add" data-view="addtask">+ Add a task</button><button class="pk-add" data-view="search">Search <kbd>⌘K</kbd></button></div>
    ${recapDue(data.courses, data.tasks, now) ? '<button class="pk-recaprow" data-view="recap"><b>Your term, in numbers</b><span>The whole term, from your own laptop</span></button>' : ''}
    ${gradesCard()}
    ${leagueCard()}
    <div class="pk-foot center">Settings, and what changed on this page, are in the toolbar button.</div>`;
}

/// Start (the page) and one focus chip at the remembered length, the same words
/// the dashboard strip uses. "Still counts" is the headline whenever this is
/// late, so the meta line does not say it again. The three lengths sit behind "change" so most nights
/// the row is two taps wide, not five.
function nextUpCard(t, now) {
  const mins = [15, 25, 45].map((m) => `
    <button class="pk-mins${skin.focusMinutes === m ? ' on' : ''}" data-mins="${m}">${m}</button>`).join('');
  return `
    <div class="pk-next">
      <span class="pk-label green">Next up</span>
      <div class="pk-row">
        <div>
          <b>${escapeHTML(t.title)}</b>
          <small>${escapeHTML(shortCourse(t.courseName))} · ${dueLabel(t, now).replace(' · still counts', '')}${t.pointsPossible ? ` · ${t.pointsPossible} pts` : ''}</small>
        </div>
        ${startButton(t, false)}
      </div>
      <div class="pk-focusrow${ui.lengthOpen ? ' open' : ''}">
        <button class="pk-mins go" data-focus="${escapeHTML(t.id)}">Focus ${skin.focusMinutes} min</button>
        <button class="pk-lenchange" data-len-toggle="1" aria-expanded="${ui.lengthOpen ? 'true' : 'false'}">${ui.lengthOpen ? 'minutes' : 'change'}</button>
        <span class="pk-lenopts">${mins}</span>
      </div>
    </div>`;
}

// MARK: - The league, the way the phone draws it
//
// Six depths of water, shallowest first. KEEP IN STEP WITH LeagueTier and its
// colours in ios/Sources/Core/LeagueState.swift and ios/Sources/LeagueView.swift.
const TIERS = [
  { id: 'tidepool', name: 'Tidepool', water: 'Sunlit rock pools at the tide line.', color: '#8FDCCB', edge: '#3E9E8C', ink: '#1B1F24' },
  { id: 'shallows', name: 'Shallows', water: 'Sand you can still stand on.', color: '#4FBDC6', edge: '#2A8C95', ink: '#1B1F24' },
  { id: 'reef', name: 'Reef', water: 'Warm water over living coral.', color: '#3A9FBF', edge: '#226F8C', ink: '#1B1F24' },
  { id: 'kelp', name: 'Kelp', water: 'Green forest, light in columns.', color: '#1F767E', edge: '#0F4F55', ink: '#FBF4EA' },
  { id: 'openwater', name: 'Open water', water: 'No bottom under you.', color: '#1D5787', edge: '#123B5D', ink: '#FBF4EA' },
  { id: 'deep', name: 'Deep', water: 'Cold, quiet, a long way down.', color: '#173A60', edge: '#0E2440', ink: '#FBF4EA' },
];
/// The kin stills the phone draws on its board, level three, shipped in the
/// zip. An unknown species gets Mint rather than a broken image.
const KIN_SPECIES = ['butter', 'coral', 'lilac', 'mint', 'peach', 'sky'];
function ownSpecies() {
  const board = Array.isArray(wallet.league?.board) ? wallet.league.board : [];
  const species = board.find((member) => member?.you === true)?.species;
  return KIN_SPECIES.includes(String(species)) ? String(species) : 'mint';
}
function kinFace(species, size = 28, className = '') {
  const id = KIN_SPECIES.includes(String(species)) ? String(species) : 'mint';
  const url = typeof chrome !== 'undefined' && chrome.runtime?.getURL && alive() ? chrome.runtime.getURL(`art/kin/${id}.webp`) : `art/kin/${id}.webp`;
  return `<span class="pk-kin${className ? ` ${className}` : ''}" style="width:${size}px;height:${size}px;background-image:url('${url}')" aria-hidden="true"></span>`;
}
function tierOf(league) { return TIERS[Math.max(0, Math.min(TIERS.length - 1, Number(league?.tier) || 0))]; }

/// The pennant: a flag with a fold, the app's shape at panel size.
function pennantSVG(tier, h = 20, earned = true) {
  const w = Math.round(h * 1.5);
  const fill = earned ? tier.color : 'none';
  return `<svg width="${w}" height="${h}" viewBox="0 0 30 20" aria-hidden="true">
    <path d="M1 1 H29 L22 10 L29 19 H1 Z" fill="${fill}" stroke="${tier.edge}" stroke-width="1.5" stroke-linejoin="round"/>
    <path d="M1 1 L8 10 L1 19 Z" fill="${earned ? tier.edge : 'none'}" opacity="${earned ? 1 : 0}"/>
  </svg>`;
}

/// Nothing to say without a phone. With one: the tier, the week so far and the
/// bar, then the pod, best first, with the student's own row marked.
function leagueCard() {
  const league = wallet.league;
  // No phone, no league card: the trio is the product, the app is the door.
  if (!league) return '';
  const tier = tierOf(league);
  const points = Math.max(0, Number(league.points) || 0);
  const bar = typeof league.bar === 'number' ? league.bar : null;
  const toGo = bar === null ? null : Math.max(0, bar - points);
  const pct = bar ? Math.min(100, Math.round((points / bar) * 100)) : 100;
  const board = Array.isArray(league.board) ? league.board : null;
  const rows = board ? board.slice(0, 20).map((m, i) => `
      <li class="${m.you ? 'you' : ''}">
        <span class="pk-rank">${i + 1}</span>
        ${kinFace(m.species)}
        <b>${escapeHTML(m.you ? 'You' : podName(m.adjective, m.noun))}</b>
        <span class="pk-pts">${escapeHTML(String(Math.max(0, Number(m.points) || 0)))}</span>
      </li>`).join('') : '';
  return `
    <span class="pk-label">League</span>
    <div class="pk-league" style="--tier:${tier.color};--tier-edge:${tier.edge};--tier-ink:${tier.ink}">
      <div class="pk-league-head">
        ${pennantSVG(tier, 34, true)}
        <div><b>${tier.name}</b><small>${leagueDaysLeft(league) ?? tier.water}</small></div>
      </div>
      <div class="pk-league-week">
        <b>${points} earned this week</b>
        ${bar !== null ? `<div class="pk-league-bar"><i style="width:${pct}%"></i></div>
        <small>${toGo === 0 ? `Bar cleared. ${TIERS[TIERS.indexOf(tier) + 1]?.name ?? ''} next week.` : `${toGo} to go for ${TIERS[TIERS.indexOf(tier) + 1]?.name ?? 'the next tier'}`}</small>`
        : '<small>Deep is the last one. Nothing below it, and nothing to lose.</small>'}
      </div>
      ${board === null ? '<div class="pk-league-note">No pod this week. Join one from the app to swim with strangers.</div>'
        : board.length <= 1 ? '<div class="pk-league-note">Only you at this tier this week. The bar is the same bar.</div>'
        : `<ol class="pk-league-board">${rows}</ol>`}
      <div class="pk-foot">Nothing here ever moves you down.</div>
    </div>`;
}

/// "3 days left", the way a league says it, from the week the phone named.
function leagueDaysLeft(league) {
  const start = Date.parse(String(league?.week ?? ''));
  if (!Number.isFinite(start)) return null;
  const end = start + 7 * DAY_MS;
  const days = Math.ceil((end - Date.now()) / DAY_MS);
  if (days <= 0) return 'Week over';
  return days === 1 ? '1 day left' : `${days} days left`;
}

function gradesCard() {
  const courses = data.courses.filter((c) => c.name).slice(0, 8);
  if (!courses.length) return '';
  const est = gpa(data.courses, levels);
  return `
    <span class="pk-label">Grades</span>
    <div class="pk-grades">
      ${courses.map(gradeRow).join('')}
      ${est ? `<hr />
        <div class="pk-gpa"><b>GPA (est.)</b><strong>${est.unweighted}</strong></div>
        ${est.weighted ? `<div class="pk-gpa weighted"><b>Weighted</b><strong>${est.weighted}</strong></div>` : ''}
        <div class="pk-foot">Updated ${freshness()}</div>` : ''}
    </div>`;
}

function gradeRow(c) {
  const pct = typeof c.score === 'number' ? Math.max(0, Math.min(100, c.score)) : null;
  const color = safeColor(c.colorHex) ?? '#51CFA0';
  const open = ui.expanded === c.id;
  const graded = data.graded?.[c.id] ?? [];
  const recent = graded.slice(-3).reverse();

  const head = `
    <div class="pk-row">
      <span class="pk-cdot" style="background:${escapeHTML(color)}"></span>
      <b>${escapeHTML(c.name)}</b>
      <span class="pk-pct">${pct === null ? '—' : `${pct}%`}</span>
      <span class="pk-letter">${escapeHTML(c.grade ?? '')}</span>
      ${levels[c.id] && levels[c.id] !== 'regular' ? `<span class="pk-level">${LEVEL_NAMES[levels[c.id]]}</span>` : ''}
      <span class="pk-chev">${chevronSVG(open ? 'up' : 'down')}</span>
    </div>`;

  const aim = targets[c.id] ?? null;
  const aimLetter = aim === null ? null : (LETTERS.find(([, cut]) => cut === aim)?.[0] ?? null);

  if (!open) {
    return `<div class="pk-grade" data-course="${escapeHTML(c.id)}">
      ${head}
      ${pct === null ? '' : `<div class="pk-mini"><i style="width:${pct}%;background:${escapeHTML(color)}"></i>${
        aim === null ? '' : `<u style="left:${Math.max(0, Math.min(100, aim))}%" title="Aiming for ${escapeHTML(aimLetter ?? '')}"></u>`}</div>`}
    </div>`;
  }

  return `<div class="pk-grade open" data-course="${escapeHTML(c.id)}">
    ${head}
    ${sparkline(graded, color)}
    ${recent.length ? `<div class="pk-recent">${recent.map((g) => `
      <div><span>${escapeHTML(g.title)}</span>${
        typeof g.classMean === 'number' ? `<i>class ${g.classMean}</i>` : ''
      }<em>${g.score}/${g.outOf}</em></div>`).join('')}</div>` : ''}
    <div class="pk-rename">
      <input type="text" maxlength="40" placeholder="Nickname, like BIO 101" data-rename="${escapeHTML(c.id)}" value="${escapeHTML(nicknames[c.id] ?? '')}" aria-label="Nickname for ${escapeHTML(c.fullName ?? c.name)}">
      <button type="button" data-rename-save="${escapeHTML(c.id)}">Save</button>
    </div>
    <div class="pk-levels" role="radiogroup" aria-label="Class level">
      ${Object.keys(LEVELS).map((k) => `<button type="button" role="radio" data-level="${k}" data-level-course="${escapeHTML(c.id)}"
        aria-checked="${(levels[c.id] ?? 'regular') === k}">${LEVEL_NAMES[k]}</button>`).join('')}
    </div>
    ${pct === null ? '' : `
    <div class="pk-aim" role="radiogroup" aria-label="Grade you are aiming for in ${escapeHTML(c.name)}">
      <span class="pk-aimlead" aria-hidden="true">Aiming for</span>
      ${targetsFor(pct).map(([letter, cut]) => `<button type="button" role="radio" aria-checked="${aim === cut}"
        class="${aim === cut ? 'on' : ''}" data-aim="${cut}" data-aim-course="${escapeHTML(c.id)}"
        aria-label="${letter}, ${cut} percent">${letter}</button>`).join('')}
      ${aim === null ? '' : `<button class="clear" data-aim-clear="${escapeHTML(c.id)}">Clear</button>`}
    </div>
    ${aim === null ? '' : `<div class="pk-foot">${
      pct >= aim
        ? `You are at ${pct}%, ${Math.round((pct - aim) * 10) / 10} above ${escapeHTML(aimLetter ?? '')}. Keep it there.`
        : `${Math.round((aim - pct) * 10) / 10} points of average to reach ${escapeHTML(aimLetter ?? '')}. Still counts.`
    }</div>`}`}
    <button class="pk-press wide" data-open-course="${escapeHTML(c.id)}"
        style="font-size:12px;padding:8px 10px">See every assignment</button>
    ${pct === null ? '' : `<button class="pk-press wide" data-whatif="${escapeHTML(c.id)}"
        style="font-size:12px;padding:8px 10px">What do I need on the final?</button>`}
  </div>`;
}

/// Everything this class has that we already fetched: what is graded, what the
/// school marked missing, what is still ahead. Canvas hides the same list behind
/// four clicks and a page load.
function courseView(now) {
  const c = data.courses.find((x) => x.id === ui.expanded);
  if (!c) return panelViewFallback();
  const filter = ui.courseFilter ?? 'all';
  const tasks = (data.tasks ?? []).filter((t) => String(t.courseId) === String(c.id));
  const graded = (data.graded?.[c.id] ?? []).slice().reverse();

  const missing = tasks.filter((t) => t.missing && !t.submittedAt);
  const upcoming = tasks.filter((t) => !t.submittedAt && !t.missing);
  // A zero the teacher entered for work never handed in is both missing and a
  // grade. It belongs in Missing, where something can still be done about it.
  const missingIds = new Set(missing.map((t) => t.id));
  const gradedOnly = graded.filter((g) => !missingIds.has(g.id));

  const gradedRow = (g) => `
    <li>
      <div><b>${escapeHTML(g.title)}</b>
           <small>${g.percent}%${typeof g.classMean === 'number' ? ` · class ${g.classMean}` : ''}</small></div>
      <span class="pk-pts">${g.score}/${g.outOf}</span>
    </li>`;
  const gradedRows = graded.map(gradedRow).join('');
  const gradedOnlyRows = gradedOnly.map(gradedRow).join('');
  const taskRows = (list, amber) => list.map((t) => `
    <li class="${amber ? 'overdue' : ''}">
      <div><b>${escapeHTML(t.title)}</b><small>${escapeHTML(dueLabel(t, now))}</small></div>
      ${startButton(t, true)}
    </li>`).join('');

  const body =
    filter === 'graded' ? (gradedRows || '<li class="empty">Nothing marked yet.</li>')
    : filter === 'missing' ? (taskRows(missing, true) || '<li class="empty">Nothing missing. Good.</li>')
    : filter === 'upcoming' ? (taskRows(upcoming, false) || '<li class="empty">Nothing ahead.</li>')
    : (taskRows(missing, true) + taskRows(upcoming, false) + gradedOnlyRows) || '<li class="empty">Nothing here yet.</li>';

  const chip = (key, label, n) => `<button data-cfilter="${key}" aria-pressed="${filter === key}" class="${filter === key ? 'on' : ''}">${label}<em>${n}</em></button>`;
  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>${escapeHTML(c.name)}</h2>
      <span class="pk-meta">${typeof c.score === 'number' ? `${c.score}%` : ''}</span>
    </div>
    <div class="pk-filters">
      ${chip('all', 'All', missing.length + upcoming.length + gradedOnly.length)}
      ${chip('graded', 'Graded', graded.length)}
      ${chip('missing', 'Missing', missing.length)}
      ${chip('upcoming', 'Upcoming', upcoming.length)}
    </div>
    <ul class="pk-list">${body}</ul>
    <div class="pk-foot">What Canvas handed over, nothing added. Older work drops off Canvas's own list, not ours.</div>`;
}

function freshness() {
  const at = data.at ? new Date(data.at) : null;
  if (!at || isNaN(at)) return 'just now';
  const mins = Math.round((Date.now() - at) / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  return `${Math.round(mins / 60)} hr ago`;
}

function addTaskView() {
  const courses = data.courses.filter((c) => c.name).map((c) => `<option value="${escapeHTML(c.id)}">${escapeHTML(c.name)}</option>`).join('');
  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>Add a task</h2>
    </div>
    <form id="pk-addtask" class="pk-form">
      <input name="title" type="text" maxlength="120" placeholder="What is it?" required autocomplete="off">
      <div class="pk-formrow"><input name="date" type="date" aria-label="Due date"><input name="time" type="time" aria-label="Due time"></div>
      <select name="course" aria-label="Class"><option value="">No class</option>${courses}</select>
      <button class="pk-press wide" type="submit">Add</button>
      <div class="pk-foot center">Lives in this browser. Canvas and your phone never see it.</div>
    </form>`;
}

function searchView() {
  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
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

function weekView(b, now) {
  // Not b.missed: a month-old zero under a heading that says "Friday" reads as
  // this Friday. Old missing work has its own list on the panel.
  const all = [...b.overdue, ...b.today, ...b.week, ...b.doneToday];
  // Grouped by the day the work sits on, which is the day it was planned for
  // when the student moved it, and the day it is due when they did not.
  const placed = all.map((t) => ({ t, day: planDay(t) })).filter((x) => x.day);
  const undated = all.filter((t) => !planDay(t));

  // One group for everything that slipped, the way Todoist keeps Overdue
  // together, then a group per day from today on.
  const today0 = startOfDay(now);
  const groups = new Map();
  for (const { t, day } of placed.sort((x, y) => x.day - y.day || String(x.t.dueAt ?? '').localeCompare(String(y.t.dueAt ?? '')))) {
    const past = day < today0;
    const key = past ? 'past' : day.toDateString();
    if (!groups.has(key)) groups.set(key, { date: past ? null : day, items: [] });
    groups.get(key).items.push(t);
  }

  // Headers the way Todoist writes them: the date, then the word for it.
  const tomorrow = new Date(now.getTime() + DAY_MS);
  const heading = (d) => {
    if (!d) return 'Past due';
    const date = d.toLocaleDateString([], { month: 'short', day: 'numeric' });
    if (sameLocalDay(d, now)) return `${date} · Today`;
    if (sameLocalDay(d, tomorrow)) return `${date} · Tomorrow`;
    return `${date} · ${d.toLocaleDateString([], { weekday: 'long' })}`;
  };

  // Seven dots from Monday: filled when that day's work is all in. Each one is
  // also where a dragged task lands, so the whole week is a set of drop targets.
  const monday = new Date(now);
  monday.setHours(0, 0, 0, 0);
  monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7));
  const strip = Array.from({ length: 7 }, (_, i) => {
    const day = new Date(monday.getTime() + i * DAY_MS);
    const items = placed.filter((x) => sameLocalDay(x.day, day)).map((x) => x.t);
    const isToday = sameLocalDay(day, now);
    const full = items.length && items.every((t) => t.submittedAt);
    return `<div class="${isToday ? 'is-today' : ''}" data-drop="${dayKey(day)}">
      <i class="${isToday ? 'today' : full ? 'full' : ''}"></i>
      <span>${'MTWTFSS'[i]}</span></div>`;
  }).join('');

  const done = all.filter((t) => t.submittedAt).length;
  const groupBlocks = [...groups.values()].map((g) => {
    const owed = g.items.filter((t) => !isMoved(t)).length;
    const moved = g.items.length - owed;
    const count = [owed ? `${owed} due` : '', moved ? `${moved} planned` : ''].filter(Boolean).join(' · ');
    return `
    <div class="pk-group">
      <span class="pk-label${g.date && sameLocalDay(g.date, now) ? ' green' : ''}${g.date ? '' : ' amber'}">${heading(g.date)}</span>
      <span class="pk-count-txt">${count}</span>
    </div>
    <ul class="pk-list"${g.date ? ` data-drop="${dayKey(g.date)}"` : ''}>${g.items.map((t) => plannerRow(t, now)).join('')}</ul>`;
  }).join('');

  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>This week</h2>
      <span class="pk-meta">${all.length} tasks · ${done} done</span>
    </div>
    <div class="pk-week">${strip}</div>
    ${groupBlocks || '<ul class="pk-list"><li class="empty">Nothing scheduled. Enjoy it.</li></ul>'}
    ${undated.length ? `
      <div class="pk-group">
        <span class="pk-label">No due date</span>
        <span class="pk-count-txt">${undated.length}</span>
      </div>
      <ul class="pk-list">${undated.map((t) => plannerRow(t, now)).join('')}</ul>` : ''}`;
}

function whatIfView() {
  const course = data.courses.find((c) => c.id === ui.expanded);
  if (!course || typeof course.score !== 'number') return panelViewFallback();

  const groups = data.weights?.[course.id] ?? null;
  // Canvas only reports weights when the course turns weighting on. Rather than
  // guess a number that looks authoritative, ask.
  const guess = groups
    ? groups.find((g) => /final|exam/i.test(g.name))?.weight ?? null
    : null;
  const weight = ui.askWeight ?? guess;

  const options = targetsFor(course.score);
  const target = ui.target ?? options.find(([, cut]) => course.score >= cut)?.[1] ?? options[0][1];

  const needed = weight != null ? requiredScore({ current: course.score, target, weight }) : null;

  let result;
  if (weight == null) {
    result = `
      <div class="pk-context" style="flex-direction:column;align-items:flex-start;gap:8px">
        <small>This course does not publish its weights, so tell me what the
               final is worth and I'll do the rest.</small>
        <div class="pk-weightask">
          <input id="pk-weight" type="number" min="1" max="100" placeholder="30" />
          <span style="font-size:12px;font-weight:600;color:var(--pk-text-2)">% of the grade</span>
          <button class="pk-press" id="pk-weight-go" style="font-size:12px;padding:8px 12px">Set</button>
        </div>
      </div>`;
  } else if (needed === null) {
    result = `<div class="pk-result">${kinFace(ownSpecies(), 44, 'pk-buddy')}
      <div><b>Not enough to go on</b><small>Once something is graded I can work this out.</small></div></div>`;
  } else if (needed > 100) {
    const reachable = options.filter(([, cut]) =>
      (requiredScore({ current: course.score, target: cut, weight }) ?? 999) <= 100)[0];
    result = `<div class="pk-result">${kinFace(ownSpecies(), 44, 'pk-buddy')}
      <div><b>That one is out of reach</b>
      <small>${reachable
        ? `A ${reachable[0]} needs ${requiredScore({ current: course.score, target: reachable[1], weight })}%. That one is still open.`
        : 'The grade is settled either way. Finish it and move on.'}</small></div></div>`;
  } else {
    const kind = needed <= course.score ? 'Comfortably in reach' : 'Within reach';
    result = `<div class="pk-result">${kinFace(ownSpecies(), 44, 'pk-buddy')}
      <div><b>You'd need ${needed}%</b>
      <small>${kind}. You're averaging ${course.score}% so far.</small></div></div>`;
  }

  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>What-if · ${escapeHTML(course.name)}</h2>
    </div>
    <div class="pk-context">
      <div><small>Current grade</small><b>${course.score}%${course.grade ? ` · ${escapeHTML(course.grade)}` : ''}</b></div>
      <div><small>Final exam</small><b>${weight ? `${weight}% of grade` : 'not published'}</b></div>
    </div>
    <span class="pk-label">I want to end with</span>
    <div class="pk-targets">
      ${options.map(([name, cut]) => `
        <button data-target="${cut}" class="${target === cut ? 'on' : ''}">${name}</button>`).join('')}
    </div>
    ${result}
    <div class="pk-foot center">Estimates from Canvas weights. Your syllabus wins.</div>`;
}

function panelViewFallback() {
  ui.view = 'panel';
  return '';
}

/// Course pictures: the theme's own banners for the theme being worn, and a
/// picture of the student's own for any course, under any theme.
///
/// One control, not two. A student who wants their dog on their Chemistry card
/// should not have to work out that banners live inside a theme sheet and
/// pictures live somewhere else.
function picturesSection(look) {
  if (!alive()) return '';
  const art = artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f));
  const showBanners = !!art && wallet.wearing === look.id;
  const courses = data.courses.filter((c) => c.name && /^\d+$/.test(String(c.id))).slice(0, 8);
  if (!courses.length) return '';
  const row = (c) => {
    const own = cardArt[c.id];
    const busy = ui.picBusy === String(c.id);
    return `
      <div class="pk-bannerrow">
        <b>${escapeHTML(c.name)}</b>
        <div class="pk-thumbs${showBanners ? '' : ' own-only'}">
          ${showBanners ? art.cards.map((u, i) => `
            <button type="button" data-banner-course="${escapeHTML(c.id)}" data-banner="${i + 1}"
              aria-label="Banner ${i + 1}" aria-pressed="${!own && banners[c.id] === i + 1}"
              style="background-image:url(&quot;${u}&quot;)"></button>`).join('') : ''}
          ${own ? `<button type="button" class="pk-own" data-pic-clear="${escapeHTML(c.id)}"
              aria-label="Remove your picture from ${escapeHTML(c.name)}" aria-pressed="true"
              style="background-image:url(&quot;${own.thumb ?? own.src}&quot;)"><i aria-hidden="true">×</i></button>` : ''}
          <label class="pk-pic${busy ? ' busy' : ''}">
            <input type="file" accept="image/*" data-pic-course="${escapeHTML(c.id)}" ${busy ? 'disabled' : ''} />
            <span>${busy ? 'Reading…' : own ? 'Change' : 'Your picture'}</span>
          </label>
        </div>
      </div>`;
  };
  return `
    <div class="pk-banners">
      <span class="pk-label">Course pictures</span>
      ${courses.map(row).join('')}
      ${ui.picError ? '<div class="pk-foot">That file could not be read. Any photo your browser can open will work.</div>' : ''}
      <div class="pk-foot">${showBanners ? 'No pick means the banners take turns. ' : ''}A picture you choose is shrunk here and kept in this browser. It is never uploaded, and it never goes to your phone.</div>
    </div>`;
}

function looksView() {
  if (ui.sheet) {
    const look = LOOKS_BY_ID[ui.sheet];
    const afford = wallet.coins !== null && wallet.coins >= look.price;
    return `
      <div class="pk-viewhead">
        <button class="pk-back" data-sheet="">${chevronSVG('left')}</button>
        <h2>${escapeHTML(look.name)}</h2>
      </div>
      <div class="pk-sheet">
        <div class="pk-well" style="background:${escapeHTML(PAPERS[stockFor(look, !!skin.dark)].paper)}">${kinFace(ownSpecies(), 64, 'pk-buddy')}</div>
        <b>Wear ${escapeHTML(look.name)}?</b>
        <small class="pk-paper">${escapeHTML(look.vibe ?? '')}<br>Light: ${escapeHTML(paperLine(stockFor(look, false)))}<br>Dark: ${escapeHTML(paperLine(stockFor(look, true)))}</small>
        <span class="pk-cost">${COIN_SVG}${look.price} coins${
          wallet.coins === null ? '' : ` · you have ${wallet.coins}`}</span>
        ${afford
          ? `<button class="pk-press wide" data-buy="${escapeHTML(look.id)}">Wear it</button>`
          : `<div class="pk-foot center">${wallet.coins === null
              ? 'Link your phone in the Prepkin popup to spend coins.'
              : `${look.price - wallet.coins} more coins to go. Verified work earns ${COIN_REWARD} each.`}</div>`}
        <button class="pk-no" data-sheet="">Not now</button>
      </div>`;
  }

  // Numo's shop: what you have first, the one you wear ticked, the rest under
  // "Locked" with a price. The tile is the paper itself, nothing else on it.
  const yours = LOOKS.filter((look) => look.free || wallet.owned.includes(look.id))
    .sort((a, b) => (b.id === wallet.wearing) - (a.id === wallet.wearing));
  const locked = LOOKS.filter((look) => !yours.includes(look));
  const tile = (look) => {
    const wearing = wallet.wearing === look.id;
    const stock = stockFor(look, !!skin.dark);
    const paper = paperLine(stock);
    const p = PAPERS[stock];
    const accent = look.accent?.[skin.dark ? 'dark' : 'light'] ?? p.mark;
    if (!alive()) return '';
    const art = artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f));
    // Inside a double-quoted style attribute, so the url gets single quotes.
    // The wall sits under a wash of the paper so the name still reads.
    const pn = parseInt(p.paper.slice(1), 16);
    const scrim = `rgba(${(pn >> 16) & 255}, ${(pn >> 8) & 255}, ${pn & 255}, 0.62)`;
    const tex = art ? `linear-gradient(${scrim}, ${scrim}), url('${art.wallpaper}')` : textureImage(look.texture, p.ink);
    return `
      <button class="pk-look${wearing ? ' wearing' : ''}${p.dark ? ' on-dark' : ''}${art ? ' has-art' : ''}"
              data-look="${escapeHTML(look.id)}" aria-pressed="${wearing}" style="background:${escapeHTML(p.paper)};background-image:${tex};background-size:cover;color:${escapeHTML(p.ink)}">
        <span class="pk-preview" aria-hidden="true">
          <span style="background:${escapeHTML(p.paper2)};border-color:${escapeHTML(p.rule)}"><i style="background:${escapeHTML(accent)}"></i><em style="background:${escapeHTML(p.ink2)}"></em><em style="background:${escapeHTML(p.rule)}"></em></span>
          ${wearing ? `<span class="pk-tick">${checkSVG(18)}</span>` : ''}
        </span>
        <b>${escapeHTML(look.name)}</b>
        <small class="pk-paper">${escapeHTML(look.vibe ?? paper)}</small>
        ${yours.includes(look) ? '' : `<small class="price">${COIN_SVG}${look.price}</small>`}
      </button>`;
  };

  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>Themes</h2>
      <span class="pk-meta">${wallet.coins === null ? '' : `${COIN_SVG} ${wallet.coins}`}</span>
    </div>
    <div class="pk-foot">Earned with coins from verified work. Dark is always free.</div>
    <span class="pk-label">Yours</span>
    <div class="pk-shop">${yours.map(tile).join('')}</div>
    ${locked.length ? `<span class="pk-label">Locked</span><div class="pk-shop">${locked.map(tile).join('')}</div>` : ''}
    ${picturesSection(LOOKS_BY_ID[wallet.wearing] ?? LOOKS_BY_ID.classic)}`;
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
  const rail = document.querySelector(`#${WEEK_ID} .pk-w-clock`);
  if (rail) rail.textContent = text;
  if (!shadow) return;
  const clock = shadow.querySelector('.pk-timer .pk-clock');
  if (clock) clock.textContent = text;
  const ring = shadow.querySelector('.pk-timer .pk-ring circle:last-child');
  if (ring) {
    const left = Math.max(0, focus.endsAt - Date.now());
    ring.setAttribute('stroke-dashoffset', (2 * Math.PI * 54 * (left / (focus.durationMin * 60000))).toFixed(1));
  }
}

/// The running / finished focus card. Replaces the panel entirely, because a
/// timer you can lose behind a scroll is a timer you forget.
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

/// The rows a card shows under "Due": up to three, pending first (overdue,
/// then soonest, then undated), then the latest handed-in work, struck.
/// Work the school marked missing more than a week ago. It belongs in the
/// panel's Missing list, never written into the school's own page: a card that
/// leads with a three-week-old zero has buried the thing due tonight.
function isStaleMissing(t, now = new Date()) {
  if (!t.missing || t.submittedAt || !t.dueAt) return false;
  const due = Date.parse(t.dueAt);
  return Number.isFinite(due) && (startOfDay(now) - startOfDay(new Date(due))) / DAY_MS > MISSED_AFTER_DAYS;
}

function dueRowsFor(courseId, now = new Date()) {
  const mine = data.tasks.filter((t) => String(t.courseId) === String(courseId) && !isStaleMissing(t, now));
  const time = (t) => { const d = t.dueAt ? new Date(t.dueAt) : null; return d && !isNaN(d) ? d.getTime() : Infinity; };
  const pending = mine.filter((t) => !t.submittedAt).sort((a, b) => time(a) - time(b)).slice(0, 3);
  const done = mine.filter((t) => t.submittedAt).sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt)).slice(0, 3 - pending.length);
  return [...pending, ...done].map((t) => ({ t, done: !!t.submittedAt, overdue: !t.submittedAt && time(t) < now.getTime(), when: dueShort(t, now) }));
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
    .filter((t) => String(t.courseId) === String(courseId) && !t.submittedAt && !isStaleMissing(t, now))
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
  // The grade pill: only when the student turned it on (its receipt row), so a
  // score is never written into the page by default.
  const showGrades = skin.cards && !killed && skin.cardGrades;
  for (const card of cards) {
    const course = data.courses.find((c) => String(c.id) === courseOf(card));
    const score = showGrades && typeof course?.score === 'number' ? course.score : null;
    let pill = card.querySelector(`.${CARD_GRADE_CLASS}`);
    if (score === null) { pill?.remove(); continue; }
    if (!pill) {
      pill = document.createElement('span');
      pill.className = CARD_GRADE_CLASS;
      const actions = card.querySelector('.ic-DashboardCard__action-container');
      if (actions) actions.append(pill); else continue;
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
    const rows = dueRowsFor(id, now);
    el.classList.toggle('overdue', rows.some((r) => r.overdue));
    el.classList.toggle('is-none', !rows.length);
    // textContent, never markup: titles are other people's text. Rebuilt only
    // when the rows change, so our own write never re-triggers the observer.
    const sig = rows.map((r) => `${r.t.id}|${r.done ? 1 : 0}|${r.overdue ? 1 : 0}|${r.when}|${r.t.title}`).join('\n') || 'none';
    if (el.dataset.sig === sig) continue;
    el.dataset.sig = sig;
    el.replaceChildren();
    if (!rows.length) { el.textContent = 'Nothing due'; continue; }
    const label = document.createElement('span'); label.className = 'pk-due-label'; label.textContent = 'Due';
    el.append(label);
    for (const r of rows) {
      // A pending row is a link to the work, and says Start when the mouse is
      // on it; handed-in rows stay plain text.
      const url = r.done ? null : safeURL(r.t.url);
      const row = document.createElement(url ? 'a' : 'div');
      row.className = `pk-due-row${r.done ? ' done' : ''}${r.overdue ? ' overdue' : ''}`;
      if (url) row.href = url;
      const t = document.createElement('span'); t.className = 't'; t.textContent = r.t.title; t.title = r.t.title;
      const d = document.createElement('span'); d.className = 'd'; d.textContent = r.done ? 'handed in' : r.overdue ? `was due ${r.when}` : r.when;
      row.append(t, d);
      if (url) { const go = document.createElement('span'); go.className = 'go'; go.textContent = 'Start'; row.append(go); }
      el.append(row);
    }
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
  const openSearch = () => { ui.open = true; ui.view = 'search'; ui.query = ''; ui.sheet = null; render(); };
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
let weekOffset = 0;

/// "AP Physics C: Mechanics" is the course; a narrow line has room for the course.
function shortCourse(name) {
  const n = String(name ?? '');
  return n.length > 20 && n.includes(':') ? n.split(':')[0].trim() : n;
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

/// Whether the rail belongs on this page: the dashboard, the skin on, nothing
/// killed or put back, and a sync to show. Shown from the first sync on, even
/// with nothing due: the empty week is still the student's.
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
  const shown = new Date(now.getTime() + weekOffset * 7 * DAY_MS);
  const w = weekStats(data.tasks, shown);
  const b = buckets(data.tasks, now, plannedOn);
  // The oldest slipped task is the one to start; after it, what is coming
  // before what has already gone by, so the list is not a wall of amber.
  const first = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;
  const then = [...b.today, ...b.week, ...b.overdue].filter((t) => t.dueAt && t !== first).slice(0, 3);
  const running = focus.state === 'running';
  const key = JSON.stringify([weekOffset, w.start.getTime(), w.total, w.done, w.byCourse.map((c) => [c.courseId, c.total, c.done]),
    first?.id, first?.dueAt, then.map((t) => [t.id, t.dueAt, t.submittedAt]), b.overdue.length, skin.focusMinutes, tankId(),
    running && focus.endsAt, running && focus.title]);
  if (existing && existing.dataset.key === key) { renderFold(); return; }
  const box = el('section', '', null);
  box.id = WEEK_ID;
  box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: this week');

  // Head: the week in words, then a stepper on its own line (the way Life
  // Reset and Garmin do it), so the title row never has to share.
  const last = new Date(w.end - 1);
  const mon = (d) => d.toLocaleDateString([], { month: 'short' });
  const range = w.start.getMonth() === last.getMonth()
    ? `${mon(w.start)} ${w.start.getDate()} – ${last.getDate()}`
    : `${mon(w.start)} ${w.start.getDate()} – ${mon(last)} ${last.getDate()}`;
  const title = weekOffset === 0 ? 'This week' : weekOffset === -1 ? 'Last week' : weekOffset === 1 ? 'Next week' : `Week of ${mon(w.start)} ${w.start.getDate()}`;
  if (buddyMode() === 'tank') {
    // The band is the tank from the phone's Home, cut to the card's shape:
    // the same water, the same floor, so the buddy is at home here too.
    const tank = el('div', 'pk-w-tank', null);
    if (alive()) tank.style.setProperty('--pk-tank', `url("${chrome.runtime.getURL(`art/tanks/${tankId()}.webp`)}")`);
    box.append(tank);
  }
  box.append(el('div', 'pk-w-head', title));
  const step = el('div', 'pk-w-step');
  const arrow = (dir, label) => {
    const a = el('i', dir < 0 ? 'prev' : 'next', null);
    a.setAttribute('role', 'button'); a.tabIndex = 0; a.setAttribute('aria-label', label);
    const go = () => { weekOffset += dir; renderWeek(); };
    a.addEventListener('click', go);
    a.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
    return a;
  };
  step.append(arrow(-1, 'Previous week'), el('span', '', range), arrow(1, 'Next week'));
  box.append(step);

  // The rings: one per course, in the course's own colour, filled by how much
  // of that course's week is handed in. The biggest week sits outermost.
  const ring = el('div', 'pk-w-ring');
  const size = 128, stroke = 9, gapStep = 12;
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', `0 0 ${size} ${size}`); svg.setAttribute('width', size); svg.setAttribute('height', size); svg.setAttribute('aria-hidden', 'true');
  const g = document.createElementNS(SVG_NS, 'g');
  g.setAttribute('transform', `rotate(-90 ${size / 2} ${size / 2})`);
  g.setAttribute('fill', 'none'); g.setAttribute('stroke-width', String(stroke)); g.setAttribute('stroke-linecap', 'round');
  const circle = (r, color, dash, opacity) => {
    const n = document.createElementNS(SVG_NS, 'circle');
    n.setAttribute('cx', size / 2); n.setAttribute('cy', size / 2); n.setAttribute('r', r); n.setAttribute('stroke', color);
    if (dash) n.setAttribute('stroke-dasharray', dash);
    if (opacity) n.setAttribute('stroke-opacity', opacity);
    return n;
  };
  const rings = w.byCourse.slice(0, 4);
  const outer = (size - stroke) / 2 - 1;
  rings.forEach((course, i) => {
    const r = outer - i * gapStep, c = 2 * Math.PI * r;
    const color = safeColor(course.colorHex) ?? 'var(--pk-mark)';
    g.append(circle(r, color, null, skin.dark ? '0.3' : '0.18'));
    if (course.done > 0) g.append(circle(r, color, `${(course.done / course.total) * c} ${c}`, null));
  });
  if (!rings.length) g.append(circle(outer, 'var(--pk-ink-2)', null, '0.15'));
  svg.append(g);
  const centre = el('div', 'pk-w-centre');
  if (w.total) centre.append(el('b', '', `${w.done}/${w.total}`), el('small', '', 'done'));
  else centre.append(el('b', '', '0'), el('small', '', 'due'));
  ring.append(svg, centre);
  box.append(ring);

  if (w.total) {
    const legend = el('ul', 'pk-w-legend');
    for (const course of w.byCourse) {
      const li = el('li');
      const dot = el('i');
      const color = safeColor(course.colorHex); if (color) dot.style.background = color;
      li.append(dot, el('span', '', shortCourse(course.name)), el('b', '', `${course.done}/${course.total}`));
      li.title = course.name;
      legend.append(li);
    }
    box.append(legend);
  } else {
    box.append(el('p', 'pk-w-empty', weekOffset === 0 ? 'Nothing due this week. Good week for a head start.' : 'Nothing due that week.'));
  }

  // One list, the way BetterCampus keeps one: the thing to start at the top
  // with its two ways to start it, the next few under it. Always today's,
  // whichever week the rings show.
  if (running || first) {
    box.append(el('p', 'pk-w-label', running ? 'Now' : 'Up next'));
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
      // Amber and "Was due" already say late; the row does not add a comment.
      info.append(el('b', '', first.title), el('small', overdue ? 'amber' : '', `${shortCourse(first.courseName)} · ${dueLabel(first, now).replace(' · still counts', '')}`));
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
    // The next few are one line each: the dot is the course, the day is on
    // the right. The full course and time sit in the title for a hover.
    for (const t of running ? [first, ...then].filter((t) => t && String(t.id) !== String(focus.taskId)).slice(0, 3) : then) {
      const late = new Date(t.dueAt) < now;
      const li = el('li');
      const dot = el('i', late ? 'late' : '');
      const color = safeColor(t.colorHex); if (color && !late) dot.style.background = color;
      const name = el('b', '', t.title);
      name.title = `${t.courseName} · ${dueLabel(t, now)}`;
      li.append(dot, name, el('small', late ? 'amber' : '', dayShort(t, now)));
      list.append(li);
    }
    box.append(list);
  }

  // The league is the buddy's: it lives in his panel, one tap away, not on
  // the page. BetterCampus's column is one list, and so is this.

  const foot = el('div', 'pk-w-foot');
  // Finished work is worth a line; nothing finished is not worth a scold.
  foot.append(el('span', '', w.done ? `${w.done} thing${w.done === 1 ? '' : 's'} finished this week` : ''));
  const more = el('span', 'more', 'See the week');
  more.setAttribute('role', 'button'); more.tabIndex = 0;
  const openWeek = () => { ui.open = true; ui.view = 'week'; ui.sheet = null; render(); };
  more.addEventListener('click', openWeek);
  more.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openWeek(); } });
  foot.append(more);
  box.append(foot);
  if (existing) existing.replaceWith(box); else side.prepend(box);
  renderFold();
  if (sprite) placeSprite();
}

/// Canvas's own To Do and Coming Up, folded to one line right under our rail:
/// how many they hold, and Show to open them for this page view. The fold is
/// a receipt row (`todo-fold`); Put back keeps the lists open for good.
/// BetterCampus deletes both outright; ours stay one click away.
function renderFold() {
  const existing = document.getElementById(FOLD_ID);
  const week = document.getElementById(WEEK_ID);
  const list = document.querySelector(SELECTORS.todoReact.sel) ?? document.querySelector(SELECTORS.todoLegacy.sel);
  if (!week || !list || putBack['todo-fold'] || killed) { existing?.remove(); return; }
  const coming = document.querySelector(SELECTORS.comingUp.sel);
  const count = list.querySelectorAll('li').length + (coming ? coming.querySelectorAll('li.event').length : 0);
  const open = document.documentElement.classList.contains('pk-todo-open');
  const key = `${count}:${open}`;
  if (existing && existing.dataset.key === key) return;
  const row = el('div', '', null);
  row.id = FOLD_ID; row.dataset.key = key;
  row.setAttribute('role', 'button'); row.tabIndex = 0;
  row.setAttribute('aria-expanded', String(open));
  row.append(el('span', '', count ? `To Do & Coming Up · ${count}` : 'To Do & Coming Up'), el('b', '', open ? 'Hide' : 'Show'));
  const toggle = () => { document.documentElement.classList.toggle('pk-todo-open'); renderFold(); };
  row.addEventListener('click', toggle);
  row.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); } });
  if (existing) existing.replaceWith(row); else week.after(row);
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
  decorateCards();
  renderWeek();
  renderSearchChip();
  if (sprite) mountSprite();
}
function watchPage() {
  if (pageObserver) return;
  const schedule = () => { if (tornDown) return; clearTimeout(pageTimer); pageTimer = setTimeout(refreshPage, 200); };
  // Our own nodes — the buddy's host and the card lines — must not count as
  // the page changing, or every pass would schedule the next one forever.
  const ours = (n) => n.nodeType === 1 && (n.id === ROOT_ID || n.id === SPRITE_ID || n.id === WEEK_ID || n.id === FOLD_ID || n.id === SEARCH_ID || n.id === 'pk-theme-vars' || n.classList.contains(CARD_DUE_CLASS) || !!n.closest?.(`#${ROOT_ID}, #${SPRITE_ID}, #${WEEK_ID}, #${FOLD_ID}, #${SEARCH_ID}, .${CARD_DUE_CLASS}`));
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
function buddyMode() { return ['tank', 'perch', 'rail', 'corner'].includes(skin.buddyPlace) ? skin.buddyPlace : 'tank'; }

function spritePlace() {
  const mode = buddyMode();
  const header = document.getElementById('header');
  const rail = header ? header.getBoundingClientRect() : null;
  const hasRail = !!(rail && rail.width >= 48 && rail.height >= 400 && rail.left === 0);
  // Above the week card, Finch-style: a water band at the top of our own rail
  // card, the to-do list flowing under him. Only where the card is.
  const week = (mode === 'tank' || mode === 'perch') ? document.getElementById(WEEK_ID) : null;
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
  if (mode === 'corner' || !hasRail) {
    const small = mode === 'corner';
    return { side: 'right', mode, navW: 0, bottom: 0, radius: small ? 22 : 36, w: small ? 110 : 150, h: small ? 170 : 240 };
  }
  const toggle = document.getElementById('primaryNavToggle')?.getBoundingClientRect();
  const bottom = Math.round(toggle?.height || 44) + 6;
  // His stage-three body radius: fins reach about 1.6 radii each side, so
  // 26 fills the 84 px rail edge to edge and 17 the collapsed 54.
  const radius = rail.width >= 80 ? 26 : 17;
  return { side: 'left', mode, navW: Math.round(rail.width), bottom, radius, w: Math.round(rail.width) + 24, h: 190 };
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
  } else if (place.side === 'left') {
    st.position = 'fixed'; st.top = 'auto'; st.left = '-12px'; st.right = 'auto'; st.bottom = `${place.bottom}px`;
  } else {
    st.position = 'fixed'; st.top = 'auto'; st.left = 'auto'; st.right = '12px'; st.bottom = '0px';
  }
  st.width = `${place.w}px`; st.height = `${place.h}px`;
  sprite.place = place;
  if (shadow) {
    const h = shadow.host;
    h.dataset.side = place.side;
    h.style.setProperty('--pk-nav-w', `${place.side === 'tank' ? place.w : (place.navW || place.w)}px`);
    h.style.setProperty('--pk-tab-h', `${place.side === 'left' ? 120 : place.side === 'tank' ? 108 : Math.round(place.h * 0.62)}px`);
    h.style.setProperty('--pk-tab-bottom', `${place.side === 'left' ? place.bottom : 0}px`);
    if (place.side === 'tank') {
      // The panel takes the column to his left (360 + 12), so the launcher lands on the band.
      h.style.position = 'absolute'; h.style.left = `${place.abs.left - 372}px`; h.style.top = `${place.abs.top + place.h - 108}px`; h.style.right = 'auto'; h.style.bottom = 'auto';
    } else {
      h.style.position = ''; h.style.left = ''; h.style.top = ''; h.style.right = ''; h.style.bottom = '';
    }
  }
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
  document.body.append(host);
  sprite = { host, frame, url, ready: false, queue: [], place };
  placeSprite(place);
  if (!spriteListening) {
    spriteListening = true;
    window.addEventListener('message', (e) => {
      if (!sprite || e.source !== sprite.frame.contentWindow || e.data?.prepkin !== 'sprout' || e.data.event !== 'ready') return;
      sprite.ready = true;
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
// Once, when a term ends: what was handed in, how much of it on time, which
// course took the most, the busiest week and the hour it all went in. The
// picture a student can save carries course names and counts, never a grade.

function recapView(now) {
  const r = termRecap(data.tasks, now);
  const fmt = (d) => d.toLocaleDateString([], { month: 'short', day: 'numeric' });
  const span = r.firstDue && r.lastDue ? `${fmt(r.firstDue)} to ${fmt(r.lastDue)}` : '';
  const most = r.byCourse.reduce((m, c) => (m && m.total >= c.total ? m : c), null);
  const bars = r.byCourse.slice(0, 6).map((c) => `
    <li><span class="pk-cdot" style="background:${escapeHTML(safeColor(c.colorHex) ?? '#51CFA0')}"></span>
      <b>${escapeHTML(shortCourse(c.name))}</b><em>${c.done} of ${c.total}</em>
      <i><u style="width:${c.total ? Math.round((c.done / c.total) * 100) : 0}%;background:${escapeHTML(safeColor(c.colorHex) ?? '#51CFA0')}"></u></i></li>`).join('');
  const lines = [
    r.onTimePct !== null ? `${r.onTimePct}% of it on time` : null,
    r.busiestWeek ? `Busiest week: ${fmt(r.busiestWeek.start)} to ${fmt(r.busiestWeek.end)}, ${r.busiestWeek.count} handed in` : null,
    r.hour ? `Most often handed in around ${hourLabel(r.hour.hour)}` : null,
    most ? `${escapeHTML(shortCourse(most.name))} asked the most of you` : null,
  ].filter(Boolean);
  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>Your term</h2><span class="pk-label">${escapeHTML(span)}</span>
    </div>
    <div class="pk-recap">
      <div class="pk-recap-big"><strong>${r.handedIn}</strong><span>thing${r.handedIn === 1 ? '' : 's'} handed in${r.total ? ` of ${r.total}` : ''}</span></div>
      <ul class="pk-recap-lines">${lines.map((l) => `<li>${l}</li>`).join('')}</ul>
      ${bars ? `<ul class="pk-recap-courses">${bars}</ul>` : ''}
      <div class="pk-listfoot"><button class="pk-add" data-recap-save>Save as a picture</button></div>
      <div class="pk-foot">Counted on your own laptop. Nothing was sent anywhere, and the picture has no grades in it.</div>
    </div>`;
}

/// The picture: paper, the big number, the lines, the course bars. Drawn on a
/// canvas of our own and handed to the browser as a download, so nothing
/// leaves the page and nothing on the page is touched.
function saveRecapPicture(now) {
  const r = termRecap(data.tasks, now);
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
  if (shadow) { shadow.host.toggleAttribute('data-open', ui.open); shadow.host.dataset.view = ui.view; shadow.host.dataset.league = wallet.league ? tierOf(wallet.league).id : ''; }
  if (shadow && sprite) placeSprite(sprite.place);
  if (!shadow) return;
  const root = shadow;
  const now = new Date();
  const b = buckets(data.tasks ?? [], now, plannedOn);
  const said = voice(b);
  const totalToday = b.today.length + b.doneToday.length;
  const pct = totalToday ? Math.round((b.doneToday.length / totalToday) * 100) : 100;
  const urgent = b.overdue.length + b.today.length;
  const earned = b.doneToday.length * COIN_REWARD;

  const body =
    ui.view === 'week' ? weekView(b, now)
    : ui.view === 'addtask' ? addTaskView()
    : ui.view === 'search' ? searchView()
    : ui.view === 'whatif' ? whatIfView()
    : ui.view === 'course' ? courseView(now)
    : ui.view === 'looks' ? looksView()
    : ui.view === 'recap' ? recapView(now)
    : panelView(b, said, now);

  const showHeader = ui.view === 'panel';

  // Every control redraws the whole panel, so without this a chip near the
  // bottom — a class level, a grade to aim for — throws the student back to the
  // top of the list and looks like it did nothing.
  const keepScroll = ui.view === prevView ? (root.querySelector('.pk-panel')?.scrollTop ?? 0) : 0;
  prevView = ui.view;

  root.innerHTML = `
    ${focus.state !== 'idle' ? focusCard() : ''}
    <button class="pk-tab" aria-expanded="${ui.open}" aria-controls="pk-panel" aria-label="Prepkin${urgent ? `, ${urgent} to do` : ''}" title="Prepkin">
      ${urgent ? `<span class="pk-count" aria-hidden="true">${urgent}</span>` : ''}
      ${ui.float && Date.now() - ui.float < 2500 ? `<span class="pk-float" aria-hidden="true">${COIN_SVG}+${COIN_REWARD}</span>` : ''}
    </button>
    <div class="pk-panel" id="pk-panel" role="dialog" aria-modal="false" aria-label="Prepkin" tabindex="-1" ${ui.open ? '' : 'hidden'}>
      ${showHeader ? `
      <div class="pk-head${said.worried ? ' worried' : ''}">
        <div class="pk-hero">
          <div class="pk-bubble">
            <strong>${said.headline}</strong>
            <span>${said.subline}</span>
          </div>
        </div>
        <div class="pk-chips">
          <button class="pk-coins" data-view="looks" title="Looks">${COIN_SVG}${
            wallet.coins === null ? (earned ? `+${earned} today` : 'Looks') : wallet.coins}</button>
          ${totalToday ? `<span class="pk-donechip">${checkSVG(14)}${b.doneToday.length} of ${totalToday} done today</span>` : ''}
        </div>
        ${totalToday ? `<div class="pk-track">
          <i style="width:${pct}%"></i>
          <span class="pk-rider" style="left:${pct}%">${kinFace(ownSpecies(), 22, 'pk-buddy')}</span>
        </div>` : ''}
      </div>` : ''}
      <div class="pk-body">${body}</div>
    </div>`;

  // innerHTML detached the stylesheet; the node itself survives, so putting it
  // back costs nothing and never refetches.
  root.prepend(styleEl);
  wire(root);
  const scroller = root.querySelector('.pk-panel');
  if (scroller && keepScroll) scroller.scrollTop = keepScroll;
  // Opening the panel moves focus into it. Without this a keyboard has to tab
  // back through the whole Canvas page to reach what it just opened.
  if (ui.open && !wasOpen && scroller) scroller.focus({ preventScroll: true });
  wasOpen = ui.open;
}

async function saveNickname(root, courseId) {
  const v = root.querySelector(`[data-rename="${CSS.escape(String(courseId))}"]`)?.value.trim() ?? '';
  const next = { ...nicknames };
  if (v) next[String(courseId)] = v; else delete next[String(courseId)];
  nicknames = next;
  await chrome.storage.local.set({ nicknames });
}

/// Command-K (Control-K elsewhere) opens search from anywhere on the page.
if (typeof window !== 'undefined' && typeof chrome !== 'undefined' && chrome.storage) {
  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && !e.altKey && !e.shiftKey && e.key.toLowerCase() === 'k' && shadow && skin.mascot !== false) {
      e.preventDefault(); e.stopPropagation();
      ui.open = true; ui.view = 'search'; ui.query = ''; ui.sheet = null; render();
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
  ui.planning = null;
  await chrome.storage.local.set({ plans });
  render();
  // The rail counts the same day the panel does, so it has to be redrawn
  // here: nothing else in this tab will.
  renderWeek();
}

function wire(root) {
  const tab = root.querySelector('.pk-tab');
  tab?.addEventListener('click', () => {
    ui.open = !ui.open;
    if (!ui.open) { ui.view = 'panel'; ui.sheet = null; }
    // He waves when you open him up, and looks over when you come close.
    spriteSend({ do: 'play', emote: ui.open ? 'wave' : 'curious' });
    render();
  });
  tab?.addEventListener('mouseenter', () => { if (!ui.open) spriteSend({ do: 'play', emote: 'curious' }); });
  // Escape closes the panel wherever you are inside it, and hands focus back to
  // the buddy rather than dropping it on the page behind.
  root.querySelector('.pk-panel')?.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    e.stopPropagation();
    // One layer at a time, and only the layers that sit on top of a view: a
    // sheet, then an open day picker. Escape has always closed the buddy from
    // anywhere else, and it still does — a view is not a layer.
    if (ui.sheet) { ui.sheet = null; render(); return; }
    if (ui.planning) { ui.planning = null; render(); return; }
    ui.open = false;
    ui.view = 'panel';
    ui.sheet = null;
    render();
    shadow?.querySelector('.pk-tab')?.focus();
  });
  root.querySelectorAll('[data-rename-save]').forEach((el) => el.addEventListener('click', () => saveNickname(root, el.dataset.renameSave)));
  root.querySelectorAll('[data-rename]').forEach((el) => el.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); saveNickname(root, el.dataset.rename); } }));
  root.querySelectorAll('[data-own-done]').forEach((el) => el.addEventListener('click', async () => {
    ownTasks = ownTasks.map((t) => (t.id === el.dataset.ownDone ? { ...t, submittedAt: new Date().toISOString() } : t));
    await chrome.storage.local.set({ ownTasks });
  }));
  root.querySelectorAll('[data-own-remove]').forEach((el) => el.addEventListener('click', async () => {
    ownTasks = ownTasks.filter((t) => t.id !== el.dataset.ownRemove);
    await chrome.storage.local.set({ ownTasks });
  }));
  root.querySelector('#pk-addtask')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const f = e.target;
    const title = f.title.value.trim(); if (!title) return;
    const date = f.date.value, time = f.time.value;
    const due = date ? new Date(`${date}T${time || '23:59'}`) : null;
    const course = data.courses.find((c) => String(c.id) === f.course.value);
    ownTasks = [...ownTasks, {
      id: `own-${Date.now()}`, title, dueAt: due && !isNaN(due) ? due.toISOString() : null,
      courseId: course?.id ?? null, courseName: course?.fullName ?? course?.name ?? '', colorHex: course?.colorHex ?? null,
      createdAt: new Date().toISOString(), submittedAt: null,
    }];
    ui.view = 'panel';
    await chrome.storage.local.set({ ownTasks });
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
      } else if (e.key === 'Escape') { ui.open = false; ui.view = 'panel'; render(); }
    });
    q.focus();
  }
  root.querySelectorAll('[data-filter]').forEach((el) => el.addEventListener('click', () => {
    const key = el.dataset.filter;
    // "This week" is a view of its own, the other two just filter the list.
    if (key === 'week') { ui.view = 'week'; } else { ui.filter = key; }
    render();
  }));
  root.querySelector('[data-recap-save]')?.addEventListener('click', () => saveRecapPicture(new Date()));
  root.querySelectorAll('[data-view]').forEach((el) => el.addEventListener('click', () => {
    ui.view = el.dataset.view; ui.sheet = null; render();
  }));
  root.querySelectorAll('[data-pic-course]').forEach((el) => el.addEventListener('change', async () => {
    const id = el.dataset.picCourse;
    const file = el.files?.[0];
    if (!file) return;
    ui.picBusy = String(id); ui.picError = false; render();
    try {
      const pic = await readPicture(file);
      // A picture wins over a banner for that course: the student just chose it.
      if (pic) {
        cardArt = { ...cardArt, [id]: pic };
        banners = { ...banners, [id]: undefined };
        await chrome.storage.local.set({ cardArt, banners });
      }
    } catch (e) {
      logError('picture', e);
      ui.picError = true;
    } finally {
      ui.picBusy = null;
      decorateCards();
      render();
    }
  }));
  root.querySelectorAll('[data-pic-clear]').forEach((el) => el.addEventListener('click', async () => {
    const { [el.dataset.picClear]: gone, ...rest } = cardArt;
    cardArt = rest;
    await chrome.storage.local.set({ cardArt });
    decorateCards(); render();
  }));
  root.querySelectorAll('[data-banner]').forEach((el) => el.addEventListener('click', async () => {
    const id = el.dataset.bannerCourse, n = Number(el.dataset.banner);
    banners = { ...banners, [id]: banners[id] === n ? undefined : n };
    await chrome.storage.local.set({ banners });
    decorateCards(); render();
  }));
  root.querySelectorAll('[data-plan-open]').forEach((el) => el.addEventListener('click', (e) => {
    e.stopPropagation();
    const id = el.dataset.planOpen;
    ui.planning = ui.planning === id ? null : id;
    render();
  }));
  root.querySelectorAll('[data-plan-set]').forEach((el) => el.addEventListener('click', async (e) => {
    e.stopPropagation();
    await setPlan(el.dataset.planSet, el.dataset.planDay);
  }));
  root.querySelectorAll('[data-plan-clear]').forEach((el) => el.addEventListener('click', async (e) => {
    e.stopPropagation();
    await setPlan(el.dataset.planClear, null);
  }));
  // Dragging is the quick way for a mouse; the Plan button is the same move for
  // a keyboard, a phone, or anyone who cannot drag. Neither is the only way in.
  root.querySelectorAll('[data-drag]').forEach((el) => {
    el.addEventListener('dragstart', (e) => {
      e.dataTransfer?.setData('text/plain', el.dataset.drag);
      if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move';
      el.classList.add('dragging');
    });
    el.addEventListener('dragend', () => el.classList.remove('dragging'));
  });
  root.querySelectorAll('[data-drop]').forEach((el) => {
    el.addEventListener('dragover', (e) => { e.preventDefault(); el.classList.add('over'); });
    el.addEventListener('dragleave', () => el.classList.remove('over'));
    el.addEventListener('drop', async (e) => {
      e.preventDefault(); el.classList.remove('over');
      const id = e.dataTransfer?.getData('text/plain');
      if (id) await setPlan(id, el.dataset.drop);
    });
  });
  root.querySelectorAll('[data-aim]').forEach((el) => el.addEventListener('click', async (e) => {
    e.stopPropagation();
    targets = { ...targets, [el.dataset.aimCourse]: Number(el.dataset.aim) };
    await chrome.storage.local.set({ targets });
    render();
  }));
  root.querySelectorAll('[data-aim-clear]').forEach((el) => el.addEventListener('click', async (e) => {
    e.stopPropagation();
    const next = { ...targets }; delete next[el.dataset.aimClear];
    targets = next;
    await chrome.storage.local.set({ targets });
    render();
  }));
  root.querySelectorAll('[data-open-course]').forEach((el) => el.addEventListener('click', (e) => {
    e.stopPropagation();
    ui.expanded = el.dataset.openCourse; ui.view = 'course'; ui.courseFilter = 'all';
    render();
  }));
  root.querySelectorAll('[data-cfilter]').forEach((el) => el.addEventListener('click', () => {
    ui.courseFilter = el.dataset.cfilter; render();
  }));
  root.querySelectorAll('[data-level]').forEach((el) => el.addEventListener('click', async (e) => {
    e.stopPropagation();
    levels = { ...levels, [el.dataset.levelCourse]: el.dataset.level };
    await chrome.storage.local.set({ levels });
    render();
  }));
  root.querySelectorAll('[data-course]').forEach((el) => el.addEventListener('click', (e) => {
    if (e.target.closest('[data-whatif], [data-level]')) return;
    ui.expanded = ui.expanded === el.dataset.course ? null : el.dataset.course;
    render();
  }));
  root.querySelectorAll('[data-whatif]').forEach((el) => el.addEventListener('click', (e) => {
    e.stopPropagation();
    ui.expanded = el.dataset.whatif; ui.view = 'whatif'; ui.target = null; ui.askWeight = null;
    render();
  }));
  root.querySelectorAll('[data-target]').forEach((el) => el.addEventListener('click', () => {
    ui.target = Number(el.dataset.target); render();
  }));
  root.querySelector('#pk-weight-go')?.addEventListener('click', () => {
    const n = Number(root.querySelector('#pk-weight')?.value);
    if (n > 0 && n <= 100) { ui.askWeight = n; render(); }
  });
  root.querySelectorAll('[data-look]').forEach((el) => el.addEventListener('click', () => {
    ui.sheet = el.dataset.look; render();
  }));
  root.querySelectorAll('[data-sheet]').forEach((el) => el.addEventListener('click', () => {
    ui.sheet = null; render();
  }));
  root.querySelectorAll('[data-buy]').forEach((el) => el.addEventListener('click', (e) => {
    if (!e.isTrusted) return;
    buy(el.dataset.buy);
  }));
  root.querySelectorAll('[data-mins]').forEach((el) => el.addEventListener('click', async () => {
    skin = { ...skin, focusMinutes: Number(el.dataset.mins) };
    ui.lengthOpen = false;
    await chrome.storage.local.set({ skin });
    render();
  }));
  root.querySelector('[data-len-toggle]')?.addEventListener('click', () => {
    ui.lengthOpen = !ui.lengthOpen; render();
  });
  root.querySelector('[data-focus]')?.addEventListener('click', (e) => {
    // A script on the page can fire a click at this button. Only a real one
    // starts a timer or spends anything.
    if (!e.isTrusted) return;
    const id = e.currentTarget.dataset.focus;
    const task = (data.tasks ?? []).find((t) => t.id === id);
    if (!alive()) return;
    chrome.runtime.sendMessage({
      type: 'focus-start', taskId: id, title: task?.title, url: task?.url,
      minutes: skin.focusMinutes,
    });
  });
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
  ui.sheet = null;
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
  const stored = await chrome.storage.local.get(['lastPayload', 'wallet', 'focus', 'putBack', 'levels', 'banners', 'cardArt', 'nicknames', 'ownTasks', 'plans', 'targets', 'flags', HANDED_IN_KEY]);
  if (tornDown || !alive()) return;
  nicknames = stored.nicknames ?? {};
  ownTasks = Array.isArray(stored.ownTasks) ? stored.ownTasks : [];
  data = composeData(stored.lastPayload ?? null, ownTasks, nicknames);
  weekOffset = 0;
  levels = stored.levels ?? {};
  plans = stored.plans ?? {};
  targets = stored.targets ?? {};
  banners = stored.banners ?? {};
  cardArt = stored.cardArt ?? {};
  putBack = stored.putBack ?? {};
  flags = stored.flags ?? null;
  wallet = { ...wallet, ...(stored.wallet ?? {}) };
  if (!LOOKS_BY_ID[wallet.wearing]) wallet.wearing = 'classic'; // a look that no longer exists
  focus = stored.focus ?? { state: 'idle' };

  applySkin(skin);
  decorateCards();
  renderWeek();
  renderSearchChip();
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

if (typeof module !== 'undefined') {
  // `node --test` reads the pure parts; the page never sees this branch.
  module.exports = { startOfDay, sameLocalDay, buckets, dueLabel, submittedLabel, voice, gpa, dayKey, dayFromKey, planDay, isMoved, missingCost,
                     targetsFor, safeURL, escapeHTML, sparkline, LETTERS, nextUpFor, LEVELS, composeData, searchItems, searchRank, searchGroups, dayShort, tankId, TANKS, TIERS, tierOf, kinFace, ownSpecies, KIN_SPECIES, recapView,
                     panelView, looksView, weekView, whatIfView, courseView, addTaskView, searchView, focusCard, gradesCard, leagueCard,
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
    if (changes.lastPayload || changes.skin || changes.wallet || changes.focus || changes.putBack || changes.banners || changes.cardArt || changes.nicknames || changes.ownTasks || changes.flags) mount();
    // Not plans, levels or targets: the tab that set one has already redrawn,
    // and a remount here would throw the student back to the top of the panel
    // they just tapped in.

  });
  // The popup asks this page for its receipt, and asks it to show what it changed.
  chrome.runtime.onMessage.addListener((msg, sender, respond) => {
    if (!msg || sender.id !== chrome.runtime.id) return;
    if (msg.type === 'receipt') respond(receiptForPage());
    if (msg.type === 'show-me') { showMe(); respond({ ok: true }); }
    if (msg.type === 'open-buddy') { ui.open = !!shadow; ui.view = 'panel'; ui.sheet = null; render(); respond({ ok: !!shadow }); }
  });
  mount();
}
}
