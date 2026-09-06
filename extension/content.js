// Runs on a connected Canvas page: applies the skin and puts the slime on screen.
//
// Injected on demand by background.js once you connect a site, so it never runs
// anywhere you have not approved.

if (typeof module !== 'undefined') {
  // Under node the sibling scripts are modules, not page globals.
  Object.assign(globalThis, require('./receipt.js'), require('./themes.js'), require('./art/manifest.js'), require('./selectors.js'), require('./looks.js'), require('./canvas.js'), require('./day.js'));
}

const ROOT_ID = 'prepkin-buddy';
const DEFAULTS = { dark: false, cards: true, tidy: true, mascot: true, focusMinutes: 25 };

/// Matches TaskKind.canvas.reward in the app, so the "+30" here is the same 30
/// coins the phone actually pays for a verified submission.
const COIN_REWARD = 30;
/// A finished focus session. The phone pays it; the extension only asks.


/// Everything the panel needs to redraw itself. `data` is the last sync, `wallet`
/// is what the phone told us about coins and looks, `ui` is where the student is.
const ui = {
  open: false, view: 'panel', filter: null, expanded: null,
  target: null, askWeight: null, sheet: null,
};
let data = { tasks: [], courses: [], graded: {}, weights: {} };
/// Names the student gave courses, by course id, and tasks they added
/// themselves. Both live in this browser only: Canvas and the phone never see them.
let nicknames = {};
let ownTasks = [];

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
    { label: 'Dashboard', sub: 'Canvas', url: '/' }, { label: 'Calendar', sub: 'Canvas', url: '/calendar' },
    { label: 'Inbox', sub: 'Canvas', url: '/conversations' }, { label: 'All courses', sub: 'Canvas', url: '/courses' },
    { label: 'Account settings', sub: 'Canvas', url: '/profile/settings' },
  ];
  for (const c of d.courses ?? []) {
    if (!c.name) continue;
    items.push({ label: c.name, sub: c.fullName && c.fullName !== c.name ? c.fullName : 'Course', url: `/courses/${c.id}` });
    for (const [tab, path] of COURSE_TABS) items.push({ label: `${c.name} ${tab}`, sub: tab, url: `/courses/${c.id}/${path}` });
  }
  for (const t of d.tasks ?? []) {
    if (!t.title) continue;
    const url = safeURL(t.url) ?? (t.courseId && t.courseId !== 'own' ? `/courses/${t.courseId}/assignments` : null);
    if (url) items.push({ label: t.title, sub: `${t.courseName}${t.dueAt ? ' · ' + dueLabel(t, new Date()) : ''}`, url });
  }
  return items;
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
/// Canvas's ENV is written once per document and can be a hundred kilobytes;
/// read it once, not on every observer pass.
let envText = null;
function detectKill() {
  if (envText === null) {
    envText = [...document.querySelectorAll('script:not([src])')].map((el) => el.textContent).join('\n');
  }
  const env = envText;
  return killReason({
    loginPage: isLoginPath(location.pathname),
    quizTake: isQuizTake(location.pathname),
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
  const next = new Set(killed ? [] : skinClasses({ on: !!s.cards, dark: !!s.dark, dense: !!s.dense, look, putBack, detect: facts }));
  for (const c of [...root.classList]) {
    if (c.startsWith('pk-') && c !== 'pk-show' && !next.has(c)) root.classList.remove(c);
  }
  for (const c of next) root.classList.add(c);
  // The theme's variables, as a stylesheet element boot.js may already have made.
  let style = document.getElementById('pk-theme-vars');
  if (!style) { style = document.createElement('style'); style.id = 'pk-theme-vars'; root.append(style); }
  const css = next.size ? themeStyle(look, textureImage, artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f))) : '';
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
      detect: facts, dark: !!skin.dark, mascot: !!skin.mascot, cardGrades: !!skin.cardGrades, dense: !!skin.dense, nicknames: Object.keys(nicknames).length,
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

// MARK: - The slime

/// The same traced paths the iPhone app draws, ported by bridge/port-slime.py.
/// Drawn as SVG rather than a picture so it stays sharp and recolours for free.
/// A look may add an accessory layer on top; the body, belly and face never change.
/// `size` is the width, exactly as in the app. SLIME_ASPECT is width over
/// height (see SlimeView.swift: `h = w / Slime.aspect`), so the slime is a
/// little wider than it is tall — dividing here is what keeps him from
/// stretching. The paths are normalised to 0..1 on each axis independently and
/// fill the box, which is why preserveAspectRatio is off: that is the same
/// mapping TracedShape does onto its frame.
function slimeSVG(face = 'faceIdle', size = 64, lookId = null) {
  const h = size / SLIME_ASPECT;
  const accessory = lookAccessorySVG(lookId ?? wallet.wearing);
  return `
  <svg width="${size}" height="${h}" viewBox="0 0 1 1" preserveAspectRatio="none" aria-hidden="true">
    <path d="${SLIME_PATHS.body}" fill="${SLIME_PALETTE.body}"/>
    <path d="${SLIME_PATHS.belly}" fill="${SLIME_PALETTE.belly}"/>
    <path d="${SLIME_PATHS[face]}" fill="${SLIME_PALETTE.ink}"/>
    ${accessory}
  </svg>`;
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
             <small>${escapeHTML(t.courseName)} · ${dueLabel(t, now)}</small></div>
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
           <small>${escapeHTML(t.courseName)} · ${dueLabel(t, now)}</small></div>
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
  return `
    <li class="${t.submittedAt ? 'done' : ''}">
      <span class="pk-bar" style="background:${escapeHTML(color)}"></span>
      ${t.submittedAt ? `<span class="pk-tick">${checkSVG(16)}</span>` : ''}
      <div><b>${escapeHTML(t.title)}</b>
           <small>${escapeHTML(t.courseName)} · ${t.submittedAt ? 'submitted' : time}</small></div>
      ${t.pointsPossible ? `<span class="pk-pts">${t.pointsPossible} pts</span>` : ''}
    </li>`;
}

// MARK: - Views

function panelView(b, said, now) {
  const totalToday = b.today.length + b.doneToday.length;
  const pct = totalToday ? Math.round((b.doneToday.length / totalToday) * 100) : 100;
  const filter = ui.filter ?? (b.overdue.length ? 'overdue' : 'today');
  const nextUp = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;

  const rows =
    filter === 'overdue' ? b.overdue.filter((t) => t !== nextUp).map((t) => taskRow(t, { now, state: 'overdue' }))
    : [
        ...b.today.filter((t) => t !== nextUp).map((t) => taskRow(t, { now, state: 'todo' })),
        ...b.doneToday.map((t) => taskRow(t, { now, state: 'done' })),
      ];

  const filterBtn = (key, label, count, amber) => `
    <button data-filter="${key}" class="${filter === key ? `on${amber ? ' amber' : ''}` : ''}">
      ${label}<em>${count}</em>
    </button>`;

  return `
    <div class="pk-filters">
      ${filterBtn('today', 'Today', totalToday, false)}
      ${filterBtn('week', 'This week', b.week.length, false)}
      ${filterBtn('overdue', 'Overdue', b.overdue.length, true)}
    </div>
    ${nextUp ? nextUpCard(nextUp, now) : ''}
    <ul class="pk-list">${rows.join('') || (nextUp ? '' : '<li class="empty">Nothing here. Enjoy it.</li>')}</ul>
    <div class="pk-listfoot"><button class="pk-add" data-view="addtask">+ Add a task</button><button class="pk-add" data-view="search">Search <kbd>⌘K</kbd></button></div>
    ${gradesCard()}
    <div class="pk-foot center">What Prepkin changed on this page, and its settings, are in the toolbar button.</div>`;
}

/// Start (the page) and one focus chip at the remembered length, the same words
/// the dashboard strip uses. The three lengths sit behind "change" so most nights
/// the row is two taps wide, not five.
function nextUpCard(t, now) {
  const mins = [15, 25, 45].map((m) => `
    <button class="pk-mins${skin.focusMinutes === m ? ' on' : ''}" data-mins="${m}">${m}</button>`).join('');
  return `
    <div class="pk-next">
      <span class="pk-label green">Next up</span>
      <div class="pk-row">
        <div>
          <b>${escapeHTML(t.title)} · ${escapeHTML(t.courseName)}</b>
          <small>${dueLabel(t, now)}${t.pointsPossible ? ` · ${t.pointsPossible} pts` : ''}</small>
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
        <div class="pk-foot">Updated ${freshness()}${est.weighted ? '' : ' · open a class to mark it Honors or AP'}</div>` : ''}
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

  if (!open) {
    return `<div class="pk-grade" data-course="${escapeHTML(c.id)}">
      ${head}
      ${pct === null ? '' : `<div class="pk-mini"><i style="width:${pct}%;background:${escapeHTML(color)}"></i></div>`}
    </div>`;
  }

  return `<div class="pk-grade open" data-course="${escapeHTML(c.id)}">
    ${head}
    ${sparkline(graded, color)}
    ${recent.length ? `<div class="pk-recent">${recent.map((g) => `
      <div><span>${escapeHTML(g.title)}</span><em>${g.score}/${g.outOf}</em></div>`).join('')}</div>` : ''}
    <div class="pk-rename">
      <input type="text" maxlength="40" placeholder="Nickname, like BIO 101" data-rename="${escapeHTML(c.id)}" value="${escapeHTML(nicknames[c.id] ?? '')}" aria-label="Nickname for ${escapeHTML(c.fullName ?? c.name)}">
      <button type="button" data-rename-save="${escapeHTML(c.id)}">Save</button>
    </div>
    <div class="pk-levels" role="radiogroup" aria-label="Class level">
      ${Object.keys(LEVELS).map((k) => `<button type="button" role="radio" data-level="${k}" data-level-course="${escapeHTML(c.id)}"
        aria-checked="${(levels[c.id] ?? 'regular') === k}">${LEVEL_NAMES[k]}</button>`).join('')}
    </div>
    ${pct === null ? '' : `<button class="pk-press wide" data-whatif="${escapeHTML(c.id)}"
        style="font-size:12px;padding:8px 10px">What do I need on the final?</button>`}
  </div>`;
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
    <ul class="pk-results">${resultsHTML(ui.query)}</ul>`;
}
function resultsHTML(query) {
  const hits = searchRank(searchItems(), query);
  if (!hits.length) return '<li class="empty">Nothing matches.</li>';
  return hits.map((h, i) => `<li${i === 0 ? ' class="on"' : ''}><a href="${escapeHTML(h.url)}" data-result><b>${escapeHTML(h.label)}</b><small>${escapeHTML(h.sub)}</small></a></li>`).join('');
}

function weekView(b, now) {
  const all = [...b.overdue, ...b.today, ...b.week, ...b.doneToday];
  const dated = all.filter((t) => t.dueAt && !isNaN(new Date(t.dueAt)));
  const undated = all.filter((t) => !dated.includes(t));

  const groups = new Map();
  for (const t of dated.sort((x, y) => x.dueAt.localeCompare(y.dueAt))) {
    const due = new Date(t.dueAt);
    const key = due.toDateString();
    if (!groups.has(key)) groups.set(key, { date: due, items: [] });
    groups.get(key).items.push(t);
  }

  const tomorrow = new Date(now.getTime() + DAY_MS);
  const heading = (d) => sameLocalDay(d, now) ? 'Today'
    : sameLocalDay(d, tomorrow) ? 'Tomorrow'
    : d.toLocaleDateString([], { weekday: 'long' });

  // Seven dots from Monday: filled when that day's work is all in.
  const monday = new Date(now);
  monday.setHours(0, 0, 0, 0);
  monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7));
  const strip = Array.from({ length: 7 }, (_, i) => {
    const day = new Date(monday.getTime() + i * DAY_MS);
    const items = dated.filter((t) => sameLocalDay(new Date(t.dueAt), day));
    const isToday = sameLocalDay(day, now);
    const full = items.length && items.every((t) => t.submittedAt);
    return `<div class="${isToday ? 'is-today' : ''}">
      <i class="${isToday ? 'today' : full ? 'full' : ''}"></i>
      <span>${'MTWTFSS'[i]}</span></div>`;
  }).join('');

  const done = all.filter((t) => t.submittedAt).length;
  const groupBlocks = [...groups.values()].map((g) => `
    <div class="pk-group">
      <span class="pk-label${sameLocalDay(g.date, now) ? ' green' : ''}">${heading(g.date)}</span>
      <span class="pk-count-txt">${g.items.length} due</span>
    </div>
    <ul class="pk-list">${g.items.map((t) => plannerRow(t, now)).join('')}</ul>`).join('');

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
    result = `<div class="pk-result">${slimeSVG('faceIdle', 44)}
      <div><b>Not enough to go on</b><small>Once something is graded I can work this out.</small></div></div>`;
  } else if (needed > 100) {
    const reachable = options.filter(([, cut]) =>
      (requiredScore({ current: course.score, target: cut, weight }) ?? 999) <= 100)[0];
    result = `<div class="pk-result">${slimeSVG('faceDeadpan', 44)}
      <div><b>That one is out of reach</b>
      <small>${reachable
        ? `A ${reachable[0]} needs ${requiredScore({ current: course.score, target: reachable[1], weight })}%. That one is still open.`
        : 'The grade is settled either way. Finish it and move on.'}</small></div></div>`;
  } else {
    const kind = needed <= course.score ? 'Comfortably in reach' : 'Within reach';
    result = `<div class="pk-result">${slimeSVG(needed <= course.score ? 'faceDelight' : 'faceIdle', 44)}
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

/// For an image theme the student is wearing: which banner each course
/// wears. A tap saves it; the dashboard follows without a reload.
function bannerPicker(look) {
  const art = artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f));
  if (!art || wallet.wearing !== look.id) return '';
  const courses = data.courses.filter((c) => c.name).slice(0, 8);
  if (!courses.length) return '';
  return `
    <div class="pk-banners">
      <span class="pk-label">Banners</span>
      ${courses.map((c) => `
        <div class="pk-bannerrow">
          <b>${escapeHTML(c.name)}</b>
          <div class="pk-thumbs">${art.cards.map((u, i) => `
            <button type="button" data-banner-course="${escapeHTML(c.id)}" data-banner="${i + 1}"
              aria-label="Banner ${i + 1}" aria-pressed="${banners[c.id] === i + 1}" style="background-image:url(&quot;${u}&quot;)"></button>`).join('')}
          </div>
        </div>`).join('')}
      <div class="pk-foot">No pick means the banners take turns.</div>
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
        <div class="pk-well" style="background:${escapeHTML(PAPERS[stockFor(look, !!skin.dark)].paper)}">${slimeSVG('faceIdle', 64, look.id)}</div>
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
        ${bannerPicker(look)}
      </div>`;
  }

  const tiles = LOOKS.map((look) => {
    const owned = look.free || wallet.owned.includes(look.id);
    const wearing = wallet.wearing === look.id;
    const status = wearing ? '<small>Wearing</small>'
      : owned ? '<small>Owned</small>'
      : `<small class="price">${COIN_SVG}${look.price}</small>`;
    const stock = stockFor(look, !!skin.dark);
    const paper = paperLine(stock);
    const p = PAPERS[stock];
    const accent = look.accent?.[skin.dark ? 'dark' : 'light'] ?? p.mark;
    const art = artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f));
    // Inside a double-quoted style attribute, so the url gets single quotes.
    // The wall sits under a wash of the paper so the name still reads.
    const pn = parseInt(p.paper.slice(1), 16);
    const scrim = `rgba(${(pn >> 16) & 255}, ${(pn >> 8) & 255}, ${pn & 255}, 0.62)`;
    const tex = art ? `linear-gradient(${scrim}, ${scrim}), url('${art.wallpaper}')` : textureImage(look.texture, p.ink);
    return `
      <button class="pk-look${wearing ? ' wearing' : ''}${p.dark ? ' on-dark' : ''}${art ? ' has-art' : ''}"
              data-look="${escapeHTML(look.id)}" style="background:${escapeHTML(p.paper)};background-image:${tex};background-size:cover;color:${escapeHTML(p.ink)}">
        <span class="pk-preview" aria-hidden="true">
          <span style="background:${escapeHTML(p.paper2)};border-color:${escapeHTML(p.rule)}"><i style="background:${escapeHTML(accent)}"></i><em style="background:${escapeHTML(p.ink2)}"></em><em style="background:${escapeHTML(p.rule)}"></em></span>
          ${slimeSVG('faceIdle', 34, look.id)}
        </span>
        <b>${escapeHTML(look.name)}</b>
        <small class="pk-paper">${escapeHTML(look.vibe ?? paper)}</small>
        ${status}
      </button>`;
  }).join('');

  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>Themes</h2>
      <span class="pk-meta">${wallet.coins === null ? '' : `${COIN_SVG} ${wallet.coins}`}</span>
    </div>
    <div class="pk-foot">A theme picks the paper Canvas is printed on, its accent, and what your
      buddy wears. Earned with coins from verified work, never bought. Dark is free. It always will be.</div>
    <div class="pk-shop">${tiles}</div>
    <div class="pk-foot center">${Object.keys(PAPERS).length} papers under ${LOOKS.length} themes, every ink measured. Nothing on it ever leaves.</div>`;
}

/// The running / finished focus card. Replaces the panel entirely, because a
/// timer you can lose behind a scroll is a timer you forget.
function focusCard() {
  if (focus.state === 'running') {
    const left = Math.max(0, focus.endsAt - Date.now());
    const total = focus.durationMin * 60000;
    const mins = Math.floor(left / 60000);
    const secs = Math.floor((left % 60000) / 1000);
    const pct = Math.min(100, ((total - left) / total) * 100);
    // A ring around the buddy fills as the session goes. Only ever forward.
    const R = 30, C = 2 * Math.PI * R;
    return `
      <div class="pk-timer">
        <div class="pk-row">
          <span class="pk-ring">
            <svg viewBox="0 0 72 72" width="72" height="72" aria-hidden="true">
              <circle cx="36" cy="36" r="${R}" fill="none" stroke="var(--pk-track)" stroke-width="4"/>
              <circle cx="36" cy="36" r="${R}" fill="none" stroke="var(--pk-mint)" stroke-width="4" stroke-linecap="round"
                      stroke-dasharray="${C.toFixed(1)}" stroke-dashoffset="${(C * (1 - pct / 100)).toFixed(1)}" transform="rotate(-90 36 36)"/>
            </svg>
            ${slimeSVG('faceIdle', 40)}
          </span>
          <div>
            <div class="pk-clock">${mins}:${String(secs).padStart(2, '0')}</div>
            <small>${escapeHTML(focus.title ?? 'Focus')}</small>
          </div>
          <button class="pk-mins" data-focus-extend="1" title="Five more minutes">+5</button>
        </div>
        <button class="pk-give" data-focus-stop="1">Give up for now. Stopping is fine, it'll be here.</button>
      </div>`;
  }
  return `
    <div class="pk-timer done">
      ${slimeSVG('faceDelight', 56)}
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

/// The rows a card shows under "Due": up to three, pending first (overdue,
/// then soonest, then undated), then the latest handed-in work, struck.
function dueRowsFor(courseId, now = new Date()) {
  const mine = data.tasks.filter((t) => String(t.courseId) === String(courseId));
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
    .filter((t) => String(t.courseId) === String(courseId) && !t.submittedAt)
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
      const row = document.createElement('div');
      row.className = `pk-due-row${r.done ? ' done' : ''}${r.overdue ? ' overdue' : ''}`;
      const t = document.createElement('span'); t.className = 't'; t.textContent = r.t.title; t.title = r.t.title;
      const d = document.createElement('span'); d.className = 'd'; d.textContent = r.done ? 'handed in' : r.overdue ? `was due ${r.when}` : r.when;
      row.append(t, d);
      el.append(row);
    }
  }
}

// MARK: - Today, at the top of the dashboard
//
// The summary a student asked for on the page their eye lands on first: what
// the buddy says, three counts, the next thing with Start and a focus timer.
// Titles, counts and dates only; grades stay behind the panel's closed root.

const TODAY_ID = 'pk-today';

function el(tag, cls, text) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text != null) n.textContent = text;
  return n;
}

function renderToday() {
  const existing = document.getElementById(TODAY_ID);
  const onDashboard = /^\/(dashboard)?\/?$/.test(location.pathname);
  const container = document.getElementById('DashboardCard_Container') ?? document.querySelector('.ic-DashboardCard__box');
  if (!onDashboard || !container || !skin.cards || killed || putBack.today || !data.tasks?.length) {
    existing?.remove();
    return;
  }
  const now = new Date();
  const b = buckets(data.tasks, now);
  const said = voice(b);
  const next = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;
  const key = JSON.stringify([said.headline, b.overdue.length, b.today.length, b.week.length, b.doneToday.length, next?.id, next?.dueAt]);
  if (existing && existing.dataset.key === key) return;
  const box = el('section', '', null);
  box.id = TODAY_ID;
  box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: today');
  const buddy = el('span', 'pk-t-buddy');
  buddy.innerHTML = slimeSVG(said.face, 44); // our own SVG constant, never page data
  const say = el('div', 'pk-t-say');
  say.append(el('b', '', said.headline), el('small', '', said.subline));
  const counts = el('div', 'pk-t-counts');
  const chip = (label, n, amber) => { const c = el('span', amber ? 'amber' : ''); c.append(el('b', '', String(n)), document.createTextNode(` ${label}`)); return c; };
  counts.append(chip('today', b.today.length + b.doneToday.length, false));
  if (b.overdue.length) counts.append(chip('still count', b.overdue.length, true));
  counts.append(chip('this week', b.week.length, false));
  box.append(buddy, say, counts);
  if (next) {
    const row = el('div', 'pk-t-next');
    const overdue = new Date(next.dueAt) < now;
    const dot = el('i', overdue ? 'amber' : '');
    const color = safeColor(next.colorHex);
    if (color && !overdue) dot.style.background = color;
    const info = el('div');
    info.append(el('b', '', next.title), el('small', overdue ? 'amber' : '', `${next.courseName} · ${dueLabel(next, now)}`));
    const actions = el('div', 'pk-t-actions');
    const url = safeURL(next.url);
    if (url) { const a = el('a', 'start', 'Start'); a.href = url; actions.append(a); }
    const focusBtn = el('span', '', `Focus ${skin.focusMinutes} min`);
    focusBtn.setAttribute('role', 'button'); focusBtn.tabIndex = 0;
    const go = (e) => { if (!e.isTrusted) return; chrome.runtime.sendMessage({ type: 'focus-start', taskId: next.id, title: next.title, url: next.url, minutes: skin.focusMinutes }); };
    focusBtn.addEventListener('click', go);
    focusBtn.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(e); } });
    const grades = el('span', '', 'Grades');
    grades.setAttribute('role', 'button'); grades.tabIndex = 0;
    grades.addEventListener('click', () => { ui.open = true; ui.view = 'panel'; render(); });
    actions.append(focusBtn, grades);
    row.append(dot, info, actions);
    box.append(row);
  }
  if (existing) existing.replaceWith(box); else container.before(box);
}

// MARK: - This week, at the top of the sidebar
//
// Our own rail: a ring of the week's work by course, the streak, and a way
// into the buddy's week. Canvas's To Do and Coming Up stay right under it.
// Counts and titles only; grades stay behind the panel's closed root.

const WEEK_ID = 'pk-week';
const SVG_NS = 'http://www.w3.org/2000/svg';

function renderWeek() {
  const existing = document.getElementById(WEEK_ID);
  const onDashboard = /^\/(dashboard)?\/?$/.test(location.pathname);
  const side = document.getElementById('right-side');
  if (!onDashboard || !side || !skin.cards || killed || putBack.week || !data.tasks?.length) {
    existing?.remove();
    return;
  }
  const now = new Date();
  const w = weekStats(data.tasks, now);
  const key = JSON.stringify([w.start.getTime(), w.total, w.done, w.streak, w.byCourse.map((c) => [c.courseId, c.total, c.done])]);
  if (existing && existing.dataset.key === key) return;
  const box = el('section', '', null);
  box.id = WEEK_ID;
  box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: this week');
  const range = `${w.start.toLocaleDateString([], { month: 'short', day: 'numeric' })} to ${new Date(w.end - 1).toLocaleDateString([], { month: 'short', day: 'numeric' })}`;
  const head = el('div', 'pk-w-head');
  head.append(el('b', '', 'This week'), el('small', '', range));
  box.append(head);

  // The ring: each course owns a slice sized by its share of the week; the
  // handed-in part of the slice is solid, the rest is faint.
  const ring = el('div', 'pk-w-ring');
  const size = 96, r = 40, c = 2 * Math.PI * r;
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', `0 0 ${size} ${size}`); svg.setAttribute('width', size); svg.setAttribute('height', size); svg.setAttribute('aria-hidden', 'true');
  const circle = (dash, offset, stroke, opacity) => {
    const n = document.createElementNS(SVG_NS, 'circle');
    n.setAttribute('cx', size / 2); n.setAttribute('cy', size / 2); n.setAttribute('r', r);
    n.setAttribute('fill', 'none'); n.setAttribute('stroke', stroke); n.setAttribute('stroke-width', '10');
    n.setAttribute('stroke-dasharray', `${dash} ${c}`); n.setAttribute('stroke-dashoffset', `${-offset}`);
    n.setAttribute('transform', `rotate(-90 ${size / 2} ${size / 2})`);
    if (opacity) n.setAttribute('opacity', opacity);
    return n;
  };
  svg.append(circle(c, 0, 'var(--pk-rule)', null));
  let at = 0;
  for (const course of w.byCourse) {
    const color = safeColor(course.colorHex) ?? 'var(--pk-mark)';
    const slice = (course.total / w.total) * c, doneLen = (course.done / w.total) * c;
    const gap = w.byCourse.length > 1 ? 2 : 0;
    svg.append(circle(Math.max(0, slice - gap), at, color, '0.28'));
    if (doneLen > 0) svg.append(circle(Math.max(0, doneLen - gap), at, color, null));
    at += slice;
  }
  const centre = el('div', 'pk-w-centre');
  if (w.total) centre.append(el('b', '', `${w.done}/${w.total}`), el('small', '', 'done'));
  else centre.append(el('b', '', '0'), el('small', '', 'due'));
  ring.append(svg, centre);
  box.append(ring);

  if (w.total) {
    const legend = el('ul', 'pk-w-legend');
    for (const course of w.byCourse.slice(0, 5)) {
      const li = el('li');
      const dot = el('i');
      const color = safeColor(course.colorHex); if (color) dot.style.background = color;
      li.append(dot, el('span', '', course.name), el('b', '', `${course.done}/${course.total}`));
      legend.append(li);
    }
    box.append(legend);
  } else {
    box.append(el('p', 'pk-w-empty', 'Nothing due this week. Good week for a head start.'));
  }
  const foot = el('div', 'pk-w-foot');
  foot.append(el('span', w.streak ? 'streak' : '', w.streak ? `${w.streak} day${w.streak === 1 ? '' : 's'} in a row` : 'Start a streak today'));
  const more = el('span', 'more', 'See the week');
  more.setAttribute('role', 'button'); more.tabIndex = 0;
  const openWeek = () => { ui.open = true; ui.view = 'week'; ui.sheet = null; render(); };
  more.addEventListener('click', openWeek);
  more.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openWeek(); } });
  foot.append(more);
  box.append(foot);
  if (existing) existing.replaceWith(box); else side.prepend(box);
}

/// Canvas draws most of a page after it loads and redraws parts of it on its
/// own schedule — the sidebar arrives by XHR, the cards by React, the planner
/// on navigation. One debounced observer plus Canvas's own navigation events
/// re-read the page and re-apply whatever depends on what is there.
let pageObserver = null;
let pageTimer = null;
function refreshPage() {
  applySkin(skin);
  decorateCards();
  renderToday();
  renderWeek();
}
function watchPage() {
  if (pageObserver) return;
  const schedule = () => { clearTimeout(pageTimer); pageTimer = setTimeout(refreshPage, 200); };
  // Our own nodes — the buddy's host and the card lines — must not count as
  // the page changing, or every pass would schedule the next one forever.
  const ours = (n) => n.nodeType === 1 && (n.id === ROOT_ID || n.id === TODAY_ID || n.id === WEEK_ID || n.id === 'pk-theme-vars' || n.classList.contains(CARD_DUE_CLASS) || !!n.closest?.(`#${ROOT_ID}, #${TODAY_ID}, #${WEEK_ID}, .${CARD_DUE_CLASS}`));
  pageObserver = new MutationObserver((records) => {
    const theirs = records.some((r) => !ours(r.target) || [...r.addedNodes, ...r.removedNodes].some((n) => !ours(n)));
    if (theirs) schedule();
  });
  pageObserver.observe(document.documentElement, { childList: true, subtree: true });
  document.addEventListener('canvasReadyStateChange', schedule);
  window.addEventListener('popstate', schedule);
  window.addEventListener('hashchange', schedule);
}

// MARK: - Render

function render() {
  if (shadow) { shadow.host.toggleAttribute('data-open', ui.open); shadow.host.dataset.view = ui.view; }
  if (!shadow) return;
  const root = shadow;
  const now = new Date();
  const b = buckets(data.tasks ?? [], now);
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
    : ui.view === 'looks' ? looksView()
    : panelView(b, said, now);

  const showHeader = ui.view === 'panel';

  root.innerHTML = `
    ${focus.state !== 'idle' ? focusCard() : ''}
    <button class="pk-tab" aria-expanded="${ui.open}" aria-controls="pk-panel" aria-label="Prepkin${urgent ? `, ${urgent} to do` : ''}" title="Prepkin">
      ${slimeSVG(said.face, 44)}
      ${urgent ? `<span class="pk-count" aria-hidden="true">${urgent}</span>` : ''}
    </button>
    <div class="pk-panel" id="pk-panel" role="dialog" aria-label="Prepkin" ${ui.open ? '' : 'hidden'}>
      ${showHeader ? `
      <div class="pk-head${said.worried ? ' worried' : ''}">
        <div class="pk-hero">
          ${slimeSVG(said.face, 64)}
          <div class="pk-bubble">
            <strong>${said.headline}</strong>
            <span>${said.subline}</span>
          </div>
        </div>
        <div class="pk-chips">
          <button class="pk-coins" data-view="looks" title="Looks">${COIN_SVG}${
            wallet.coins === null ? (earned ? `+${earned} today` : 'Looks') : wallet.coins}</button>
          <span class="pk-donechip">${checkSVG(14)}${b.doneToday.length} of ${totalToday} today</span>
          <span class="pk-label">${now.toLocaleDateString([], { weekday: 'short' })}</span>
        </div>
        <div class="pk-track">
          <i style="width:${pct}%"></i>
          <span class="pk-rider" style="left:${pct}%">${slimeSVG(said.face, 22)}</span>
        </div>
      </div>` : ''}
      <div class="pk-body">${body}</div>
    </div>`;

  // innerHTML detached the stylesheet; the node itself survives, so putting it
  // back costs nothing and never refetches.
  root.prepend(styleEl);
  wire(root);
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

function wire(root) {
  root.querySelector('.pk-tab')?.addEventListener('click', () => {
    ui.open = !ui.open;
    if (!ui.open) { ui.view = 'panel'; ui.sheet = null; }
    render();
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
      const items = [...root.querySelectorAll('.pk-results li:not(.empty)')];
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
  root.querySelectorAll('[data-view]').forEach((el) => el.addEventListener('click', () => {
    ui.view = el.dataset.view; ui.sheet = null; render();
  }));
  root.querySelectorAll('[data-banner]').forEach((el) => el.addEventListener('click', async () => {
    const id = el.dataset.bannerCourse, n = Number(el.dataset.banner);
    banners = { ...banners, [id]: banners[id] === n ? undefined : n };
    await chrome.storage.local.set({ banners });
    decorateCards(); render();
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
    chrome.runtime.sendMessage({
      type: 'focus-start', taskId: id, title: task?.title, url: task?.url,
      minutes: skin.focusMinutes,
    });
  });
  root.querySelector('[data-focus-extend]')?.addEventListener('click', (e) => {
    if (e.isTrusted) chrome.runtime.sendMessage({ type: 'focus-extend' });
  });
  root.querySelector('[data-focus-stop]')?.addEventListener('click', (e) => {
    if (e.isTrusted) chrome.runtime.sendMessage({ type: 'focus-stop' });
  });
  root.querySelector('[data-focus-clear]')?.addEventListener('click', (e) => {
    if (e.isTrusted) chrome.runtime.sendMessage({ type: 'focus-clear' });
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
  skin = await settings();
  const stored = await chrome.storage.local.get(['lastPayload', 'wallet', 'focus', 'putBack', 'levels', 'banners', 'nicknames', 'ownTasks']);
  nicknames = stored.nicknames ?? {};
  ownTasks = Array.isArray(stored.ownTasks) ? stored.ownTasks : [];
  data = composeData(stored.lastPayload ?? null, ownTasks, nicknames);
  levels = stored.levels ?? {};
  banners = stored.banners ?? {};
  putBack = stored.putBack ?? {};
  wallet = { ...wallet, ...(stored.wallet ?? {}) };
  if (!LOOKS_BY_ID[wallet.wearing]) wallet.wearing = 'classic'; // a look that no longer exists
  focus = stored.focus ?? { state: 'idle' };

  applySkin(skin);
  decorateCards();
  renderToday();
  renderWeek();
  watchPage();

  document.getElementById(ROOT_ID)?.remove();
  shadow = null;
  // The sign-in page is the school's alone: no paper, no buddy.
  if (!skin.mascot || isLoginPath(location.pathname) || isQuizTake(location.pathname)) return;

  const host = document.createElement('div');
  host.id = ROOT_ID;
  // Closed, because the panel holds the student's grades for every school they
  // connected. In the page's own DOM any script on Canvas — a school's global
  // theme JS, a teacher's HTML, an embedded tool — could read the lot with one
  // querySelector. A closed root also stops a school's CSS reaching in.
  shadow = host.attachShadow({ mode: 'closed' });
  styleEl = panelStyle(host);
  shadow.append(styleEl);
  document.body.append(host);
  render();

  clearInterval(ticker);
  // Only tick while a timer is actually on screen.
  ticker = setInterval(() => { if (focus.state === 'running' && ui.open) render(); }, 1000);
}

if (typeof module !== 'undefined') {
  // `node --test` reads the pure parts; the page never sees this branch.
  module.exports = { startOfDay, sameLocalDay, buckets, dueLabel, submittedLabel, voice, gpa,
                     targetsFor, safeURL, escapeHTML, sparkline, LETTERS, nextUpFor, LEVELS, composeData, searchItems, searchRank,
                     _setData: (d) => { data = d; } };
} else {
  // A fresh sync, a toggle, a purchase or a Put back should show up without a reload.
  chrome.storage.onChanged.addListener((changes) => {
    if (changes.lastPayload || changes.skin || changes.wallet || changes.focus || changes.putBack || changes.banners || changes.nicknames || changes.ownTasks) mount();
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
