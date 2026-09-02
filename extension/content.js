// Runs on a connected Canvas page: applies the skin and puts the slime on screen.
//
// Injected on demand by background.js once you connect a site, so it never runs
// anywhere you have not approved.

const ROOT_ID = 'prepkin-buddy';
const DEFAULTS = { dark: false, cards: true, tidy: true, mascot: true, focusMinutes: 25 };

/// Matches TaskKind.canvas.reward in the app, so the "+30" here is the same 30
/// coins the phone actually pays for a verified submission.
const COIN_REWARD = 30;
/// A finished focus session. The phone pays it; the extension only asks.
const FOCUS_REWARD = 10;

const DAY_MS = 86_400_000;

/// Everything the panel needs to redraw itself. `data` is the last sync, `wallet`
/// is what the phone told us about coins and looks, `ui` is where the student is.
const ui = {
  open: false, view: 'panel', filter: null, expanded: null,
  target: null, askWeight: null, sheet: null,
};
let data = { tasks: [], courses: [], graded: {}, weights: {} };
let wallet = { coins: null, owned: ['classic'], wearing: 'classic' };
let skin = { ...DEFAULTS };
let focus = { state: 'idle' };

/// Settings live in one place so the popup and the page cannot disagree.
async function settings() {
  const { skin: saved } = await chrome.storage.local.get('skin');
  return { ...DEFAULTS, ...(saved ?? {}) };
}

/// Every custom property this has ever set, so turning a look off removes
/// exactly what it added and nothing a school put there itself.
let appliedVars = [];

function applySkin(s) {
  const root = document.documentElement;
  const look = LOOKS_BY_ID[wallet.wearing];
  // A look may be a dark one; that counts the same as the toggle.
  const dark = !!s.dark || !!look?.dark;
  root.classList.toggle('prepkin-dark', dark);
  root.classList.toggle('prepkin-cards', !!s.cards);
  root.classList.toggle('prepkin-tidy', !!s.tidy);

  // A look only moves tints. Type, layout and spacing never change, and course
  // colours stay Canvas's own. Properties are set one at a time rather than
  // through the style attribute, which would wipe whatever the school put there.
  for (const name of appliedVars) root.style.removeProperty(name);
  appliedVars = [];
  if (!s.cards || dark) return;
  for (const [name, value] of Object.entries(look?.tints ?? {})) {
    root.style.setProperty(name, value);
    appliedVars.push(name);
  }
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

// MARK: - Reading the day

function sameLocalDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth()
      && a.getDate() === b.getDate();
}

/// Splits the synced tasks the way the panel talks about them. "Overdue" is by
/// the clock, not the calendar: work due at 9 AM is overdue at 2 PM.
function buckets(tasks, now = new Date()) {
  const pending = tasks.filter((t) => !t.submittedAt);
  const doneToday = tasks.filter((t) => {
    const at = t.submittedAt && new Date(t.submittedAt);
    return at && !isNaN(at) && sameLocalDay(at, now);
  });
  const overdue = [], today = [], week = [];
  for (const t of pending) {
    const due = t.dueAt ? new Date(t.dueAt) : null;
    if (!due || isNaN(due)) week.push(t);
    else if (due < now) overdue.push(t);
    else if (sameLocalDay(due, now)) today.push(t);
    else week.push(t);
  }
  return { overdue, today, week, doneToday };
}

function dueLabel(t, now = new Date()) {
  const due = t.dueAt ? new Date(t.dueAt) : null;
  if (!due || isNaN(due)) return 'No due date';
  const time = due.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  if (due < now) {
    const days = Math.floor((now - due) / DAY_MS);
    const when = sameLocalDay(due, now) ? `${time} today`
      : days < 2 ? 'yesterday'
      : due.toLocaleDateString([], { weekday: 'short' });
    return `Was due ${when} · still counts`;
  }
  if (sameLocalDay(due, now)) return `Due ${time}`;
  return `${due.toLocaleDateString([], { weekday: 'short' })} · ${time}`;
}

function submittedLabel(t) {
  const at = new Date(t.submittedAt);
  if (isNaN(at)) return 'Submitted · verified';
  return `Submitted ${at.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })} · verified`;
}

/// What the slime says. Calm on purpose: no alarms, no shame — overdue work is
/// "still counts", never a red wall.
function voice({ overdue, today, doneToday }) {
  const o = overdue.length, t = today.length, d = doneToday.length;
  const count = (n) => ['Zero', 'One', 'Two', 'Three', 'Four', 'Five'][n] ?? String(n);
  if (o) {
    return {
      face: 'faceDeadpan', worried: true,
      headline: o === 1 ? 'One slipped past due' : `${count(o)} slipped past due`,
      subline: 'Pick one to start — ten minutes counts.',
    };
  }
  if (!t) {
    return d
      ? { face: 'faceDelight', headline: 'All done for today', subline: 'Rest counts too.' }
      : { face: 'faceDelight', headline: 'Nothing due today', subline: 'Enjoy the space.' };
  }
  return {
    face: 'faceIdle',
    headline: d ? 'Nice pace today' : 'Ready when you are',
    subline: d ? `${d} down, ${t} to go. No rush.` : `${t === 1 ? 'One thing' : count(t) + ' things'} today. Start small.`,
  };
}

// MARK: - Grades

function gpa(courses) {
  const scored = courses.filter((c) => typeof c.score === 'number');
  if (!scored.length) return null;
  // Unweighted 4.0 on the usual US cutoffs. Shown as an estimate, because a
  // school's real scale is its own business and Canvas does not publish it.
  const points = scored.map((c) =>
    c.score >= 93 ? 4.0 : c.score >= 90 ? 3.7 : c.score >= 87 ? 3.3 : c.score >= 83 ? 3.0
    : c.score >= 80 ? 2.7 : c.score >= 77 ? 2.3 : c.score >= 73 ? 2.0 : c.score >= 70 ? 1.7
    : c.score >= 67 ? 1.3 : c.score >= 65 ? 1.0 : 0);
  return (points.reduce((a, b) => a + b, 0) / points.length).toFixed(2);
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
  return LETTERS.slice(Math.max(0, at - 1), Math.max(0, at - 1) + 4);
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
        <div><b>${escapeHTML(t.title)}</b><small>${submittedLabel(t)}</small></div>
        <span class="pk-plus">${COIN_SVG}+${COIN_REWARD}</span>
      </li>`;
  }
  const overdue = state === 'overdue';
  return `
    <li class="${overdue ? 'overdue' : ''}">
      <span class="pk-dot"></span>
      <div><b>${escapeHTML(t.title)} · ${escapeHTML(t.courseName)}</b>
           <small>${dueLabel(t, now)}</small></div>
      ${overdue ? startButton(t, true) : ''}
    </li>`;
}

/// A planner row: colour bar, title, course and time, points on the right.
function plannerRow(t, now) {
  const color = t.colorHex ?? '#C9BCA4';
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
    <ul class="pk-list">${rows.join('') || '<li class="empty">Nothing here. Enjoy it.</li>'}</ul>
    ${gradesCard()}`;
}

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
      <div class="pk-focusrow">
        <span>or focus for</span>${mins}
        <button class="pk-mins" data-focus="${escapeHTML(t.id)}" style="font-weight:800">Go</button>
      </div>
    </div>`;
}

function gradesCard() {
  const courses = data.courses.filter((c) => c.name).slice(0, 8);
  if (!courses.length) return '';
  const est = gpa(data.courses);
  return `
    <span class="pk-label">Grades</span>
    <div class="pk-grades">
      ${courses.map(gradeRow).join('')}
      ${est ? `<hr />
        <div class="pk-gpa"><b>GPA (est.)</b><strong>${est}</strong></div>
        <div class="pk-foot">Updated ${freshness()}</div>` : ''}
    </div>`;
}

function gradeRow(c) {
  const pct = typeof c.score === 'number' ? Math.max(0, Math.min(100, c.score)) : null;
  const color = c.colorHex ?? '#51CFA0';
  const open = ui.expanded === c.id;
  const graded = data.graded?.[c.id] ?? [];
  const recent = graded.slice(-3).reverse();

  const head = `
    <div class="pk-row">
      <span class="pk-cdot" style="background:${escapeHTML(color)}"></span>
      <b>${escapeHTML(c.name)}</b>
      <span class="pk-pct">${pct === null ? '—' : `${pct}%`}</span>
      <span class="pk-letter">${escapeHTML(c.grade ?? '')}</span>
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

  const needed = weight ? requiredScore({ current: course.score, target, weight }) : null;

  let result;
  if (!weight) {
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
        ? `A ${reachable[0]} needs ${requiredScore({ current: course.score, target: reachable[1], weight })}% — that one is still open.`
        : 'The grade is settled either way. Finish it and move on.'}</small></div></div>`;
  } else {
    const kind = needed <= course.score ? 'Comfortably in reach' : 'Within reach';
    result = `<div class="pk-result">${slimeSVG(needed <= course.score ? 'faceDelight' : 'faceIdle', 44)}
      <div><b>You'd need ${needed}%</b>
      <small>${kind} — you're averaging ${course.score}% so far.</small></div></div>`;
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
    <div class="pk-foot center">Estimates from Canvas weights — your syllabus wins.</div>`;
}

function panelViewFallback() {
  ui.view = 'panel';
  return '';
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
        <div class="pk-well" style="background:${escapeHTML(look.swatch)}">${slimeSVG('faceIdle', 64, look.id)}</div>
        <b>Wear ${escapeHTML(look.name)}?</b>
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

  const tiles = LOOKS.map((look) => {
    const owned = look.free || wallet.owned.includes(look.id);
    const wearing = wallet.wearing === look.id;
    const status = wearing ? '<small>Wearing</small>'
      : owned ? '<small>Owned</small>'
      : `<small class="price">${COIN_SVG}${look.price}</small>`;
    return `
      <button class="pk-look${wearing ? ' wearing' : ''}${look.dark ? ' on-dark' : ''}"
              data-look="${escapeHTML(look.id)}" style="background:${escapeHTML(look.swatch)}">
        ${slimeSVG('faceIdle', 44, look.id)}
        <b>${escapeHTML(look.name)}</b>
        ${status}
      </button>`;
  }).join('');

  return `
    <div class="pk-viewhead">
      <button class="pk-back" data-view="panel">${chevronSVG('left')}</button>
      <h2>Looks</h2>
      <span class="pk-meta">${wallet.coins === null ? '' : `${COIN_SVG} ${wallet.coins}`}</span>
    </div>
    <div class="pk-foot">A look restyles Canvas and dresses your slime. Earned with
      coins from verified work — never bought.</div>
    <div class="pk-shop">${tiles}</div>`;
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
    return `
      <div class="pk-timer">
        <div class="pk-row">
          ${slimeSVG('faceIdle', 44)}
          <div>
            <div class="pk-clock">${mins}:${String(secs).padStart(2, '0')}</div>
            <small>${escapeHTML(focus.title ?? 'Focus')}</small>
          </div>
        </div>
        <div class="pk-thin"><i style="width:${pct}%"></i></div>
        <button class="pk-give" data-focus-stop="1">Give up for now — stopping is fine. It'll be here.</button>
      </div>`;
  }
  return `
    <div class="pk-timer done">
      ${slimeSVG('faceDelight', 56)}
      <b>${focus.durationMin} minutes. Nice.</b>
      <span class="pk-plus">${COIN_SVG}+${FOCUS_REWARD} coins on your phone</span>
      ${safeURL(focus.url)
        ? `<a class="pk-start" style="width:100%" href="${escapeHTML(focus.url)}">Open the assignment</a>`
        : ''}
      <button class="pk-give" data-focus-clear="1">Done</button>
    </div>`;
}

// MARK: - Render

function render() {
  const root = document.getElementById(ROOT_ID);
  if (!root) return;
  const now = new Date();
  const b = buckets(data.tasks ?? [], now);
  const said = voice(b);
  const totalToday = b.today.length + b.doneToday.length;
  const pct = totalToday ? Math.round((b.doneToday.length / totalToday) * 100) : 100;
  const urgent = b.overdue.length + b.today.length;
  const earned = b.doneToday.length * COIN_REWARD;

  const body =
    ui.view === 'week' ? weekView(b, now)
    : ui.view === 'whatif' ? whatIfView()
    : ui.view === 'looks' ? looksView()
    : panelView(b, said, now);

  const showHeader = ui.view === 'panel';

  root.innerHTML = `
    ${focus.state !== 'idle' && ui.open ? focusCard() : ''}
    <button class="pk-tab" aria-expanded="${ui.open}" title="Prepkin">
      ${slimeSVG(said.face, 44)}
      ${urgent ? `<span class="pk-count">${urgent}</span>` : ''}
    </button>
    <div class="pk-panel" ${ui.open ? '' : 'hidden'}>
      ${showHeader ? `
      <div class="pk-head${said.worried ? ' worried' : ''}">
        <div class="pk-hero">
          ${slimeSVG(said.face, 80)}
          <div class="pk-bubble">
            <strong>${said.headline}</strong>
            <span>${said.subline}</span>
          </div>
        </div>
        <div class="pk-chips">
          <button class="pk-coins" data-view="looks">${COIN_SVG}${
            wallet.coins === null ? (earned ? `+${earned} today` : 'Looks') : wallet.coins}</button>
          <span class="pk-donechip">${checkSVG(14)}${b.doneToday.length} of ${totalToday} today</span>
          <span class="pk-label">Today</span>
        </div>
        <div class="pk-track">
          <i style="width:${pct}%"></i>
          <span class="pk-rider" style="left:${pct}%">${slimeSVG(said.face, 22)}</span>
        </div>
      </div>` : ''}
      <div class="pk-body">${body}</div>
    </div>`;

  wire(root);
}

function wire(root) {
  root.querySelector('.pk-tab')?.addEventListener('click', () => {
    ui.open = !ui.open;
    if (!ui.open) { ui.view = 'panel'; ui.sheet = null; }
    render();
  });
  root.querySelectorAll('[data-filter]').forEach((el) => el.addEventListener('click', () => {
    const key = el.dataset.filter;
    // "This week" is a view of its own, the other two just filter the list.
    if (key === 'week') { ui.view = 'week'; } else { ui.filter = key; }
    render();
  }));
  root.querySelectorAll('[data-view]').forEach((el) => el.addEventListener('click', () => {
    ui.view = el.dataset.view; ui.sheet = null; render();
  }));
  root.querySelectorAll('[data-course]').forEach((el) => el.addEventListener('click', (e) => {
    if (e.target.closest('[data-whatif]')) return;
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
  root.querySelectorAll('[data-buy]').forEach((el) => el.addEventListener('click', () => buy(el.dataset.buy)));
  root.querySelectorAll('[data-mins]').forEach((el) => el.addEventListener('click', async () => {
    skin = { ...skin, focusMinutes: Number(el.dataset.mins) };
    await chrome.storage.local.set({ skin });
    render();
  }));
  root.querySelector('[data-focus]')?.addEventListener('click', (e) => {
    const id = e.currentTarget.dataset.focus;
    const task = (data.tasks ?? []).find((t) => t.id === id);
    chrome.runtime.sendMessage({
      type: 'focus-start', taskId: id, title: task?.title, url: task?.url,
      minutes: skin.focusMinutes,
    });
  });
  root.querySelector('[data-focus-stop]')?.addEventListener('click', () =>
    chrome.runtime.sendMessage({ type: 'focus-stop' }));
  root.querySelector('[data-focus-clear]')?.addEventListener('click', () =>
    chrome.runtime.sendMessage({ type: 'focus-clear' }));
}

/// Wearing a look is local and instant; spending the coins is the phone's call.
/// The extension only files the request — the app's ledger stays the truth.
async function buy(id) {
  const look = LOOKS_BY_ID[id];
  if (!look) return;
  const owned = look.free || wallet.owned.includes(id);
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

async function mount() {
  skin = await settings();
  const stored = await chrome.storage.local.get(['lastPayload', 'wallet', 'focus']);
  data = stored.lastPayload ?? data;
  wallet = { ...wallet, ...(stored.wallet ?? {}) };
  focus = stored.focus ?? { state: 'idle' };

  applySkin(skin);

  document.getElementById(ROOT_ID)?.remove();
  if (!skin.mascot) return;

  const root = document.createElement('div');
  root.id = ROOT_ID;
  document.body.append(root);
  render();

  clearInterval(ticker);
  // Only tick while a timer is actually on screen.
  ticker = setInterval(() => { if (focus.state === 'running' && ui.open) render(); }, 1000);
}

// A fresh sync should show up without a reload.
chrome.storage.onChanged.addListener((changes) => {
  if (changes.lastPayload || changes.skin || changes.wallet || changes.focus) mount();
});

mount();
