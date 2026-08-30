// Runs on a connected Canvas page: applies the skin and puts the slime on screen.
//
// Injected on demand by background.js once you connect a site, so it never runs
// anywhere you have not approved.

const ROOT_ID = 'prepkin-buddy';
const DEFAULTS = { cards: true, tidy: true, mascot: true };

/// Matches TaskKind.canvas.reward in the app, so the "+30" here is the same 30
/// coins the phone actually pays for a verified submission.
const COIN_REWARD = 30;

const DAY_MS = 86_400_000;

/// Settings live in one place so the popup and the page cannot disagree.
async function settings() {
  const { skin } = await chrome.storage.local.get('skin');
  return { ...DEFAULTS, ...(skin ?? {}) };
}

function applySkin(s) {
  const root = document.documentElement.classList;
  root.remove('prepkin-dark'); // retired — the warm theme is the theme
  root.toggle('prepkin-cards', !!s.cards);
  root.toggle('prepkin-tidy', !!s.tidy);
}

// MARK: - The slime

/// The same traced paths the iPhone app draws, ported by bridge/port-slime.py.
/// Drawn as SVG rather than a picture so it stays sharp and recolours for free.
function slimeSVG(face = 'faceIdle', size = 64) {
  const h = size * SLIME_ASPECT;
  return `
  <svg width="${size}" height="${h}" viewBox="0 0 1 ${SLIME_ASPECT}" aria-hidden="true">
    <g transform="scale(1, ${SLIME_ASPECT})">
      <path d="${SLIME_PATHS.body}" fill="${SLIME_PALETTE.body}"/>
      <path d="${SLIME_PATHS.belly}" fill="${SLIME_PALETTE.belly}"/>
      <path d="${SLIME_PATHS[face]}" fill="${SLIME_PALETTE.ink}"/>
    </g>
  </svg>`;
}

const COIN_SVG = `
  <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
    <circle cx="7" cy="7" r="6.4" fill="#DE9A22"/>
    <circle cx="7" cy="7" r="3.4" fill="none" stroke="#FFF3D9" stroke-width="1.6"/>
  </svg>`;

function checkSVG(size = 18) {
  return `
  <svg width="${size}" height="${size}" viewBox="0 0 16 16" aria-hidden="true">
    <circle cx="8" cy="8" r="8" fill="#51CFA0"/>
    <path d="M4.6 8.3 L7 10.6 L11.4 5.6" stroke="#101820" stroke-width="1.9"
          fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
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

// MARK: - The panel

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

function gradeRow(c) {
  const pct = typeof c.score === 'number' ? Math.max(0, Math.min(100, c.score)) : null;
  const color = c.colorHex ?? '#51CFA0';
  return `
    <div class="pk-grade">
      <div class="pk-row">
        <span class="pk-cdot" style="background:${escapeHTML(color)}"></span>
        <b>${escapeHTML(c.name)}</b>
        <span class="pk-pct">${pct === null ? '—' : `${pct}%`}</span>
        <span class="pk-letter">${escapeHTML(c.grade ?? '')}</span>
      </div>
      ${pct === null ? '' : `<div class="pk-bar"><i style="width:${pct}%;background:${escapeHTML(color)}"></i></div>`}
    </div>`;
}

/// Panel state that should survive a re-render mid-session but not a reload.
const ui = { open: false, filter: null };

function render(root, { tasks = [], courses = [] }) {
  const now = new Date();
  const b = buckets(tasks, now);
  const said = voice(b);
  const totalToday = b.today.length + b.doneToday.length;
  const pct = totalToday ? Math.round((b.doneToday.length / totalToday) * 100) : 100;
  const urgent = b.overdue.length + b.today.length;
  const earned = b.doneToday.length * COIN_REWARD;

  const filter = ui.filter ?? (b.overdue.length ? 'overdue' : 'today');
  const nextUp = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;

  // The hero card already shows nextUp, so the list underneath never repeats it.
  const rows =
    filter === 'overdue' ? b.overdue.filter((t) => t !== nextUp).map((t) => taskRow(t, { now, state: 'overdue' }))
    : filter === 'week' ? b.week.map((t) => taskRow(t, { now, state: 'todo' }))
    : [
        ...b.today.filter((t) => t !== nextUp).map((t) => taskRow(t, { now, state: 'todo' })),
        ...b.doneToday.map((t) => taskRow(t, { now, state: 'done' })),
      ];

  const filterBtn = (key, label, count, amber) => `
    <button data-filter="${key}" class="${filter === key ? `on${amber ? ' amber' : ''}` : ''}">
      ${label}<em>${count}</em>
    </button>`;

  const shownCourses = courses.filter((c) => c.name).slice(0, 8);

  root.innerHTML = `
    <button class="pk-tab" aria-expanded="${ui.open}" title="Prepkin">
      ${slimeSVG(said.face, 44)}
      ${urgent ? `<span class="pk-count">${urgent}</span>` : ''}
    </button>
    <div class="pk-panel" ${ui.open ? '' : 'hidden'}>
      <div class="pk-head${said.worried ? ' worried' : ''}">
        <div class="pk-hero">
          ${slimeSVG(said.face, 80)}
          <div class="pk-bubble">
            <strong>${said.headline}</strong>
            <span>${said.subline}</span>
          </div>
        </div>
        <div class="pk-chips">
          <span class="pk-coins">${COIN_SVG}${earned ? `+${earned} today` : 'Coins ready'}</span>
          <span class="pk-donechip">${checkSVG(14)}${b.doneToday.length} of ${totalToday} today</span>
          <span class="pk-label">Today</span>
        </div>
        <div class="pk-track">
          <i style="width:${pct}%"></i>
          <span class="pk-rider" style="left:${pct}%">${slimeSVG(said.face, 22)}</span>
        </div>
      </div>
      <div class="pk-body">
        <div class="pk-filters">
          ${filterBtn('today', 'Today', totalToday, false)}
          ${filterBtn('week', 'This week', b.week.length, false)}
          ${filterBtn('overdue', 'Overdue', b.overdue.length, true)}
        </div>
        ${nextUp && filter !== 'week' ? `
          <div class="pk-next">
            <span class="pk-label">Next up</span>
            <div class="pk-row">
              <div>
                <b>${escapeHTML(nextUp.title)} · ${escapeHTML(nextUp.courseName)}</b>
                <small>${dueLabel(nextUp, now)}${nextUp.pointsPossible ? ` · ${nextUp.pointsPossible} pts` : ''}</small>
              </div>
              ${startButton(nextUp, false)}
            </div>
          </div>` : ''}
        <ul class="pk-list">
          ${rows.join('') || '<li class="empty">Nothing here. Enjoy it.</li>'}
        </ul>
        ${shownCourses.length ? `
          <span class="pk-label">Grades</span>
          <div class="pk-grades">
            ${shownCourses.map(gradeRow).join('')}
            ${gpa(courses) ? `<hr /><div class="pk-gpa"><b>GPA (est.)</b><strong>${gpa(courses)}</strong></div>` : ''}
          </div>` : ''}
      </div>
    </div>`;

  root.querySelector('.pk-tab').addEventListener('click', () => {
    ui.open = !ui.open;
    const panel = root.querySelector('.pk-panel');
    panel.hidden = !ui.open;
    root.querySelector('.pk-tab').setAttribute('aria-expanded', String(ui.open));
  });
  root.querySelectorAll('.pk-filters button').forEach((btn) => {
    btn.addEventListener('click', () => {
      ui.filter = btn.dataset.filter;
      render(root, { tasks, courses });
    });
  });
}

/// Canvas content is other people's text. It goes in as text, never as markup.
function escapeHTML(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// MARK: - Boot

async function mount() {
  const s = await settings();
  applySkin(s);

  document.getElementById(ROOT_ID)?.remove();
  if (!s.mascot) return;

  const root = document.createElement('div');
  root.id = ROOT_ID;
  document.body.append(root);

  const { lastPayload } = await chrome.storage.local.get('lastPayload');
  render(root, lastPayload ?? {});
}

// A fresh sync should show up without a reload.
chrome.storage.onChanged.addListener((changes) => {
  if (changes.lastPayload || changes.skin) mount();
});

mount();
